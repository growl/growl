//
//  GrowlTicketDatabaseTicket.h
//  Growl
//
//  Created by Daniel Siemer on 2/22/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GrowlTicketDatabaseTicket, GrowlTicketDatabaseDisplay, GrowlTicketDatabasePlugin;

@interface GrowlTicketDatabaseTicket : NSManagedObject

@property (nonatomic, retain) NSNumber * enabled;
@property (nonatomic, retain) NSData * iconData;
@property (nonatomic, retain) NSNumber * loggingEnabled;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * positionType;
@property (nonatomic, retain) NSNumber * selectedPosition;
@property (nonatomic, retain) NSString * ticketDescription;
@property (nonatomic, retain) NSNumber * useDisplay;
@property (nonatomic, retain) NSNumber * useParentActions;
@property (nonatomic, retain) NSOrderedSet *actions;
@property (nonatomic, retain) NSSet *children;
@property (nonatomic, retain) GrowlTicketDatabaseTicket *parent;
@property (nonatomic, retain) GrowlTicketDatabaseDisplay *display;
@end

@interface GrowlTicketDatabaseTicket (CoreDataGeneratedAccessors)

- (void)insertObject:(NSManagedObject *)value inActionsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromActionsAtIndex:(NSUInteger)idx;
- (void)insertActions:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeActionsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInActionsAtIndex:(NSUInteger)idx withObject:(NSManagedObject *)value;
- (void)replaceActionsAtIndexes:(NSIndexSet *)indexes withActions:(NSArray *)values;
- (void)addActionsObject:(NSManagedObject *)value;
- (void)removeActionsObject:(NSManagedObject *)value;
- (void)addActions:(NSOrderedSet *)values;
- (void)removeActions:(NSOrderedSet *)values;
- (void)addChildrenObject:(GrowlTicketDatabaseTicket *)value;
- (void)removeChildrenObject:(GrowlTicketDatabaseTicket *)value;
- (void)addChildren:(NSSet *)values;
- (void)removeChildren:(NSSet *)values;

-(BOOL)isTicketAllowed;
-(GrowlTicketDatabaseDisplay*)resolvedDisplayConfig;
-(NSSet*)resolvedActionConfigSet;

-(void)setNewDisplayName:(NSString*)name;
-(void)importDisplayOrActionForName:(NSString*)name;

@end
