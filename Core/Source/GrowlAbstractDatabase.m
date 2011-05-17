//
//  GrowlAbstractDatabase.m
//  Growl
//
//  Created by Daniel Siemer on 9/23/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import "GrowlAbstractDatabase.h"
#import "GrowlPathUtilities.h"


@implementation GrowlAbstractDatabase

@synthesize updateDelegate;
@synthesize managedObjectContext;
@synthesize uiManagedObjectContext;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;

-(id)initSingleton
{
   if((self = [super initSingleton]))
   {
      [self managedObjectContext];
      [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                          selector:@selector(databaseDidUpdate:)
                                                              name:RemoteDatabaseDidUpdate
                                                            object:[self storeType]
                                                suspensionBehavior:NSNotificationSuspensionBehaviorCoalesce];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(databaseDidSave:)
                                                   name:NSManagedObjectContextDidSaveNotification
                                                 object:[self managedObjectContext]];
      NSProcessInfo *proc = [NSProcessInfo processInfo];
      processID = [[NSNumber numberWithUnsignedInt:[proc processIdentifier]] retain];
   }
   return self;
}

-(NSString*)storePath
{
   return nil;
}

-(NSString*)storeType
{
   return nil;
}

-(NSString*)modelName
{
   return nil;
}

-(void)databaseDidSave:(NSNotification*)note
{
   NSMutableDictionary *savedURIs = [NSMutableDictionary dictionaryWithObject:processID forKey:@"kDatabaseProcessID"];
   
   for(NSString *saveTypeKey in [[note userInfo] allKeys]) {
      NSMutableSet *saveTypeSet = [NSMutableSet set];
      
      for(id object in [[[note userInfo] objectForKey:saveTypeKey] allObjects]) {
         NSURL *objectURI = [[(NSManagedObject *)object objectID] URIRepresentation];
         [saveTypeSet addObject:objectURI];
      }
      [savedURIs setObject:[NSArchiver archivedDataWithRootObject:saveTypeSet] forKey:saveTypeKey];
   }
   
   [[NSDistributedNotificationCenter defaultCenter] postNotificationName:RemoteDatabaseDidUpdate 
                                                                  object:[self storeType]
                                                                userInfo:(NSDictionary*)savedURIs
                                                      deliverImmediately:YES];
}

-(void)databaseDidUpdate:(NSNotification*)note
{
   NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

   /* verify we need to update something, processID should be unique
    * no need to go around telling the database to forget all it knows unless it needs to
    */
   NSNumber *remotePID = [[note userInfo] objectForKey:@"kDatabaseProcessID"];
   if([remotePID unsignedIntValue] == [processID unsignedIntValue]) {
      [pool drain];
      return;
   }
   
   /* Ask the delegate if we can do a reset */
   if(!updateDelegate || [updateDelegate CanGrowlDatabaseHardReset:self])
   {
      [[self managedObjectContext] reset];
   }else {
      //TODO: test this properly
      //we dont want this object in the rest of the info
      NSMutableDictionary *mutableUserInfo = [[note userInfo] mutableCopy];
      [mutableUserInfo removeObjectForKey:@"kDatabaseProcessID"];
      
      for(NSString *saveTypeKey in [mutableUserInfo allKeys]) {
         NSSet *objectURISet = [NSUnarchiver unarchiveObjectWithData:[[note userInfo] objectForKey:saveTypeKey]];
         
         for(NSURL *objectURI in objectURISet) {
            NSManagedObjectID *objectID = [[self persistentStoreCoordinator] managedObjectIDForURIRepresentation:objectURI];
            /* Database on first run sometimes doesn't like finding URIR's, 
             * the view will still update, but additional testing is needed to verify
             * lack of side affects to ignoring this.
             */
            if(!objectID)
               continue;
            NSManagedObject *object = [[self managedObjectContext] objectWithID:objectID];
            [[self managedObjectContext] refreshObject:object mergeChanges:NO];
         }
      }
      [mutableUserInfo release];
   }

   if(updateDelegate)
      [updateDelegate GrowlDatabaseDidUpdate:self];
   
   [pool drain];
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
	
   if (managedObjectContext != nil) {
      return managedObjectContext;
   }
	
   NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
   if (coordinator != nil) {
      managedObjectContext = [NSManagedObjectContext new];
      [managedObjectContext setPersistentStoreCoordinator:coordinator];
      [managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
   }
   return managedObjectContext;
}

- (NSManagedObjectContext *)uiManagedObjectContext {
	
   if (uiManagedObjectContext != nil) {
      return uiManagedObjectContext;
   }
	
   NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
   if (coordinator != nil) {
      uiManagedObjectContext = [NSManagedObjectContext new];
      [uiManagedObjectContext setPersistentStoreCoordinator:coordinator];
      [uiManagedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
   }
   return uiManagedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
   if (managedObjectModel != nil) {
      return managedObjectModel;
   }
   //TODO: make this work better
   NSString *modelName = [self modelName];
   NSURL *url = [NSURL fileURLWithPath:[[GrowlPathUtilities helperAppBundle] pathForResource:modelName ofType:@"mom"] ];
   managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
   return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
   if (persistentStoreCoordinator != nil) {
      return persistentStoreCoordinator;
   }
   
	NSString *storePath = [self storePath];
   if(!storePath)
      return nil;
	
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	
	NSError *error;
   persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
   if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		// Handle error
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
   }    
   
   return persistentStoreCoordinator;
}

-(void)destroy
{
   [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
   [managedObjectContext release]; managedObjectContext = nil;
   [managedObjectModel release]; managedObjectModel = nil;
   [persistentStoreCoordinator release]; persistentStoreCoordinator = nil;
   [processID release]; processID = nil;
   [super destroy];
}

@end
