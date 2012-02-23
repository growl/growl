//
//  GrowlTicketDatabaseAction.h
//  Growl
//
//  Created by Daniel Siemer on 2/23/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GrowlTicketDatabaseCompoundAction, GrowlTicketDatabaseTicket;

@interface GrowlTicketDatabaseAction : NSManagedObject

@property (nonatomic, retain) NSData * configuration;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *compounds;
@property (nonatomic, retain) NSSet *actionTickets;
@end

@interface GrowlTicketDatabaseAction (CoreDataGeneratedAccessors)

- (void)addCompoundsObject:(GrowlTicketDatabaseCompoundAction *)value;
- (void)removeCompoundsObject:(GrowlTicketDatabaseCompoundAction *)value;
- (void)addCompounds:(NSSet *)values;
- (void)removeCompounds:(NSSet *)values;

- (void)addActionTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)removeActionTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)addActionTickets:(NSSet *)values;
- (void)removeActionTickets:(NSSet *)values;

@end
