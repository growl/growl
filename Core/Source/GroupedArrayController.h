//
//  GroupedArrayController.h
//  Growl
//
//  Created by Daniel Siemer on 7/29/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GrowlNotificationDatabase, GroupedArrayController;

@protocol GroupedArrayControllerDelegate <NSObject>
@optional
-(void)groupedControllerUpdatedTotalCount:(GroupedArrayController*)groupedController;
-(void)groupedControllerBeginUpdates:(GroupedArrayController*)groupedController;
-(void)groupedControllerEndUpdates:(GroupedArrayController*)groupedController;
-(void)groupedController:(GroupedArrayController*)groupedController insertIndexes:(NSIndexSet*)indexSet;
-(void)groupedController:(GroupedArrayController*)groupedController removeIndexes:(NSIndexSet*)indexSet;
-(void)groupedController:(GroupedArrayController*)groupedController moveIndex:(NSUInteger)start toIndex:(NSUInteger)end;

@end

@interface GroupedArrayController : NSObject

- (id)initWithEntityName:(NSString*)entity
     basePredicateString:(NSString*)predicate
                groupKey:(NSString*)key
    managedObjectContext:(NSManagedObjectContext*)aContext;

@property (nonatomic, assign) id<GroupedArrayControllerDelegate> delegate;
@property (nonatomic, assign) NSManagedObjectContext *context;
@property (nonatomic, assign) NSTableView *tableView; 
@property (nonatomic, retain) NSString *entityName;
@property (nonatomic, retain) NSString *basePredicateString;
@property (nonatomic, retain) NSString *groupKey;
@property (nonatomic, retain) NSMutableArray *currentGroups;
@property (nonatomic, retain) NSMutableDictionary *groupControllers;
@property (nonatomic, retain) NSArrayController *countController;
@property (nonatomic, retain) NSArray *arrangedObjects;
@property (nonatomic, copy) NSComparator groupCompareBlock;
@property (nonatomic, retain) id selection;
@property (nonatomic) BOOL grouped;
@property (nonatomic) BOOL doNotShowSingleGroupHeader;
@property (nonatomic) BOOL showEmptyGroups;
@property (nonatomic) BOOL transitionGroup;

-(NSArray*)arrangedObjects;
-(void)toggleGrouped;
-(void)toggleShowGroup:(NSString*)groupID;
-(NSArray*)updatedArray;
-(void)updateArray;
-(void)updateArrayGroups;

-(NSUInteger)indexOfFirstNonGroupItem;
-(id)selection;
-(NSArray*)selectedObjects;

-(void)updatedTotalCount;
-(void)beginUpdates;
-(void)endUpdates;
-(void)insertIndexes:(NSIndexSet*)indexSet;
-(void)removeIndexes:(NSIndexSet*)indexSet;
-(void)moveIndex:(NSUInteger)start toIndex:(NSUInteger)end;


@end
