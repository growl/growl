//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import <Foundation/Foundation.h>

#define GROWL_SUPPORT_DIR   [@"~/Library/Growl Support" stringByExpandingTildeInPath]
#define GROWL_TICKETS_DIR   [GROWL_SUPPORT_DIR stringByAppendingString:@"/Application Tickets"]
#define GROWL_PLUGINS_DIR   [GROWL_SUPPORT_DIR stringByAppendingString:@"/Plugins"]

@protocol GrowlDisplayPlugin;

@interface GrowlController : NSObject {
	NSMutableDictionary			*_tickets;				//Application tickets
	id <GrowlDisplayPlugin>		_displayController;
}

- (void) dispatchNotification:(NSNotification *) note;

- (void) loadTickets;
- (void) saveTickets;
@end
