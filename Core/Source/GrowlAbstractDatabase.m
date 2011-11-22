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

@synthesize managedObjectContext;
@synthesize managedObjectModel;
@synthesize persistentStoreCoordinator;

-(id)initSingleton
{
   if((self = [super initSingleton]))
   {
      [self managedObjectContext];
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(databaseDidSave:)
                                                   name:NSManagedObjectContextDidSaveNotification
                                                 object:[self managedObjectContext]];
       [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(databaseDidChange:)
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:[self managedObjectContext]];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GrowlDatabaseSaved" 
                                                        object:self
                                                      userInfo:[note userInfo]];
}

-(void)databaseDidChange:(NSNotification*)note
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"GrowlDatabaseUpdated" 
                                                        object:self
                                                      userInfo:[note userInfo]];
}


/* most database save requests should use this, this makes it easier to make save fancier down the road
 * We could make it so it doesn't save after every operation, and waits and clumps them together
 */
-(void)saveDatabase:(BOOL)doItNow
{
    void (^saveBlock)(void) = ^{
        NSError *error = nil;
        [managedObjectContext save:&error];
        if(error)
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);       
    };
    if(doItNow)
        [managedObjectContext performBlockAndWait:saveBlock];
    else
        [managedObjectContext performBlock:saveBlock];
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
      managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
      [managedObjectContext setPersistentStoreCoordinator:coordinator];
      [managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
   }
   return managedObjectContext;
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
   NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:modelName ofType:@"mom"] ];
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
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [managedObjectContext release]; managedObjectContext = nil;
   [managedObjectModel release]; managedObjectModel = nil;
   [persistentStoreCoordinator release]; persistentStoreCoordinator = nil;
   [super destroy];
}

@end
