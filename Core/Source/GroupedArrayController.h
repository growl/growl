//
//  GroupedArrayController.h
//  Growl
//
//  Created by Daniel Siemer on 7/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GrowlNotificationDatabase;

@interface GroupedArrayController : NSObject

- (id)initWithEntityName:(NSString*)entity
     basePredicateString:(NSString*)predicate
                groupKey:(NSString*)key
    managedObjectContext:(NSManagedObjectContext*)aContext;

@property (nonatomic) BOOL grouped;
@property (nonatomic) BOOL updateArray;
@property (nonatomic, retain) NSManagedObjectContext *context;
@property (nonatomic, retain) NSString *entityName;
@property (nonatomic, retain) NSString *basePredicateString;
@property (nonatomic, retain) NSString *groupKey;
@property (nonatomic, retain) NSMutableArray *currentGroups;
@property (nonatomic, retain) NSMutableDictionary *groupControllers;
@property (nonatomic, retain) NSArrayController *countController;

-(NSArray*)arrangedObjects;
-(void)notifyUpdates;
-(void)updateArrayGroups;

@end
