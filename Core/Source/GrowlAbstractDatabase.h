//
//  GrowlAbstractDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 9/23/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define RemoteDatabaseDidUpdate @"RemoteDatabaseDidUpdate"

@class GrowlAbstractDatabase;

@protocol GrowlDatabaseUpdateDelegate
-(BOOL)CanGrowlDatabaseHardReset:(GrowlAbstractDatabase*)database;
-(void)GrowlDatabaseDidUpdate:(GrowlAbstractDatabase*)database;
@end

@interface GrowlAbstractDatabase : GrowlAbstractSingletonObject {
   NSPersistentStoreCoordinator *persistentStoreCoordinator;
   NSManagedObjectModel *managedObjectModel;
   NSManagedObjectContext *managedObjectContext;
   NSManagedObjectContext *uiManagedObjectContext;
   
   id<GrowlDatabaseUpdateDelegate> updateDelegate;
   NSNumber *processID;
}
@property (nonatomic, retain) id<GrowlDatabaseUpdateDelegate> updateDelegate;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectContext *uiManagedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(NSString*)storePath;
-(NSString*)storeType;
-(NSString*)modelName;
-(void)databaseDidSave:(NSNotification*)note;
-(void)databaseDidUpdate:(NSNotification*)note;

@end
