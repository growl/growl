//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import <Foundation/Foundation.h>

@protocol GrowlDisplayPlugin;

@interface GrowlController : NSObject {
	NSMutableDictionary			*_tickets;				//Application tickets
	id <GrowlDisplayPlugin>		_displayController;
}

+ (id) singleton;

- (void) dispatchNotification:(NSNotification *) note;
- (void) dispatchNotificationWithDictionary:(NSDictionary *) dict;

- (void) loadTickets;
- (void) saveTickets;

@end

