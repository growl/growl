//
//  GrowlTicketDatabaseDisplay.h
//  Growl
//
//  Created by Daniel Siemer on 2/23/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabaseAction.h"

@class GrowlTicketDatabaseTicket;

@interface GrowlTicketDatabaseDisplay : GrowlTicketDatabaseAction

@property (nonatomic, retain) NSSet *displayTickets;
@end

@interface GrowlTicketDatabaseDisplay (CoreDataGeneratedAccessors)

- (void)addDisplayTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)removeDisplayTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)addDisplayTickets:(NSSet *)values;
- (void)removeDisplayTickets:(NSSet *)values;

@end
