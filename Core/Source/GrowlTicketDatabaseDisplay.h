//
//  GrowlTicketDatabaseDisplay.h
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GrowlTicketDatabasePlugin.h"

@class GrowlTicketDatabaseTicket;

@interface GrowlTicketDatabaseDisplay : GrowlTicketDatabasePlugin

@property (nonatomic, retain) NSSet *tickets;
@end

@interface GrowlTicketDatabaseDisplay (CoreDataGeneratedAccessors)

- (void)addTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)removeTicketsObject:(GrowlTicketDatabaseTicket *)value;
- (void)addTickets:(NSSet *)values;
- (void)removeTickets:(NSSet *)values;

@end
