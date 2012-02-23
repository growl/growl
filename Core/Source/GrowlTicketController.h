//
//  GrowlTicketController.h
//  Growl
//
//  Created by Peter Hosey on 2005-06-08.
//  Copyright 2005-2006 Peter Hosey. All rights reserved.
//


@class GrowlApplicationTicket;

@interface GrowlTicketController: NSObject
{
	NSMutableDictionary *ticketsByApplicationName;
}

- (NSArray *) allSavedTickets;

- (GrowlApplicationTicket *) ticketForApplicationName:(NSString *) appName hostName:(NSString*)hostName;
- (void) addTicket:(GrowlApplicationTicket *) newTicket;
- (void) removeTicketForApplicationName:(NSString *)appName;

- (void) loadAllSavedTickets;
@end
