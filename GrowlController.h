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
	NSLock						*_registrationLock;
	NSMutableArray				*_notificationQueue;
	NSMutableArray				*_registrationQueue;
	id <GrowlDisplayPlugin>		_displayController;
}

+ (id) singleton;

- (void) dispatchNotification:(NSNotification *) note;
- (void) dispatchNotificationWithDictionary:(NSDictionary *) dict overrideCheck:(BOOL) override;

- (void) loadTickets;
- (void) saveTickets;

- (void) reloadPreferences: (NSNotification *) note;

@end

