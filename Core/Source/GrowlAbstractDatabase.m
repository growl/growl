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

-(id)init
{
   if((self = [super init]))
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

-(NSString*)storeType
{
   return nil;
}

-(NSString*)storePath
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
   NSURL *url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:[modelName stringByDeletingPathExtension] ofType:[modelName pathExtension]]];
   managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
   return managedObjectModel;
}

- (void)launchFailed {
   
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
   if (persistentStoreCoordinator != nil) {
      return persistentStoreCoordinator;
   }
   
   NSString *storeType = [self storeType];
	NSString *storePath = [self storePath];
   if(!storePath)
      return nil;
	
	NSURL *storeUrl = [NSURL fileURLWithPath:storePath];
	
	NSError *error = nil;
   BOOL launchSuceeded = YES;
   persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
   if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
		// Handle error
      if([[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
         NSBeginCriticalAlertSheet([NSString stringWithFormat:NSLocalizedString(@"Error opening %@.", @"Alert when database has been corrupted"), storeType],
                                   NSLocalizedString(@"Ok", @""),
                                   nil, nil, nil, nil, NULL, NULL, NULL, 
                                   [NSString stringWithFormat:NSLocalizedString(@"There was error opening the %@ file, it is possibly corrupted.\nGrowl will move the database aside, and create a fresh database.\nThis may have occured if Growl or the computer crashed.", @""), storeType]);
         if([[NSFileManager defaultManager] moveItemAtPath:storePath toPath:[storePath stringByAppendingPathExtension:@"bak"] error:nil]){
            NSError *tryTwoError = nil;
            if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&tryTwoError]){
               launchSuceeded = NO;
               NSLog(@"Unresolved error after moving corrupt database aside\n%@, %@", tryTwoError, [tryTwoError userInfo]);
            }
         }else{
            NSLog(@"Unable to move database file aside.");
            launchSuceeded = NO;
         }
      }else{
         //If the database isn't there, and Growl couldn't create it, there is something seriously weird going on the users system. 
         NSLog(@"Error creating persistent store\n%@, %@", error, [error userInfo]);
         launchSuceeded = NO;
      }
   }
   
   if(!launchSuceeded){
      [self launchFailed];
      
      NSError *memError = nil;
      if (![persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&memError]) {
         NSLog(@"Error Creating an in memory store for the purposes of this session\n%@, %@", memError, [memError userInfo]);
         NSBeginCriticalAlertSheet(NSLocalizedString(@"Fatal Error", @"fatal alert"),
                                   NSLocalizedString(@"Quit", @""), 
                                   nil, nil, nil,
                                   self,
                                   @selector(fatalErrorAlert:returnCode:contextInfo:),
                                   NULL, NULL, 
                                   [NSString stringWithFormat:NSLocalizedString(@"Growl has encountered a fatal error trying to setup the %@, and will terminate upon closing this window.  Please contact us at support@growl.info.", @""), storeType]);
      }else{
         return persistentStoreCoordinator;
      }
      return nil;
   }
   
   return persistentStoreCoordinator;
}

- (void) fatalErrorAlert:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
   exit(-1);
}

-(void)dealloc
{
   [[NSNotificationCenter defaultCenter] removeObserver:self];
   [managedObjectContext release]; managedObjectContext = nil;
   [managedObjectModel release]; managedObjectModel = nil;
   [persistentStoreCoordinator release]; persistentStoreCoordinator = nil;
   [super dealloc];
}

@end
