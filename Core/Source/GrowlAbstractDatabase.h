//
//  GrowlAbstractDatabase.h
//  Growl
//
//  Created by Daniel Siemer on 9/23/10.
//  Copyright 2010 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define RemoteDatabaseDidUpdate @"RemoteDatabaseDidUpdate"

@interface GrowlAbstractDatabase : GrowlAbstractSingletonObject {
   NSPersistentStoreCoordinator *persistentStoreCoordinator;
   NSManagedObjectModel *managedObjectModel;
   NSManagedObjectContext *managedObjectContext;
   
}
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(NSString*)storePath;
-(NSString*)storeType;
-(NSString*)modelName;
-(void)databaseDidSave:(NSNotification*)note;
-(void)databaseDidChange:(NSNotification*)note;
-(void)saveDatabase:(BOOL)doItNow;

@end
