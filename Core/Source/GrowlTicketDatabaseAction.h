//
//  GrowlTicketDatabaseAction.h
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabasePlugin.h"

@class GrowlTicketDatabaseCompoundAction, GrowlTicketDatabaseTicket;

@interface GrowlTicketDatabaseAction : GrowlTicketDatabasePlugin

@property (nonatomic, retain) NSSet *tickets;
@property (nonatomic, retain) NSSet *compounds;
@end

@interface GrowlTicketDatabaseAction (CoreDataGeneratedAccessors)

- (void)addTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)removeTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)addTickets:(NSSet *)values;
- (void)removeTickets:(NSSet *)values;

- (void)addCompoundsObject:(GrowlTicketDatabaseCompoundAction *)value;
- (void)removeCompoundsObject:(GrowlTicketDatabaseCompoundAction *)value;
- (void)addCompounds:(NSSet *)values;
- (void)removeCompounds:(NSSet *)values;

@end
