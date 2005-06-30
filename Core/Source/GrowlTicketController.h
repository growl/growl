//
//  GrowlTicketController.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-08.
//  Copyright 2005 Mac-arena the Bored Zo. All rights reserved.
//

@class GrowlApplicationTicket;

@interface GrowlTicketController: NSObject
{
	NSMutableDictionary *ticketsByApplicationName;
}

+ (id) sharedController;

- (NSDictionary *) allSavedTickets;

- (GrowlApplicationTicket *) ticketForApplicationName:(NSString *) appName;
- (void) addTicket:(GrowlApplicationTicket *) newTicket;
- (void) removeTicketForApplicationName:(NSString *)appName;

- (void) loadAllSavedTickets;
@end
