//
//  GrowlController.h
//  Growl
//
//  Created by Karl Adam on Thu Apr 22 2004.
//

#import <Foundation/Foundation.h>
#import "GrowlAdminPathway.h"

@protocol GrowlDisplayPlugin;

@interface GrowlController : NSObject {
	NSMutableDictionary			*_tickets;				//Application tickets
	NSMutableArray				*_notificationQueue;
	NSMutableArray				*_registrationQueue;
	GrowlPreferences			*_prefs;				// The ONE preference instance
	GrowlAdminPathway			*_adminPathway;			// The prefPane can talk back to us
	
	id <GrowlDisplayPlugin>		displayController;
}

+ (id) singleton;

- (void) dispatchNotification:(NSNotification *) note;
- (void) dispatchNotificationWithDictionary:(NSDictionary *) dict overrideCheck:(BOOL) override;

- (void) loadTickets;
- (void) saveTickets;

- (void) preferencesChanged: (NSNotification *) note;
- (GrowlPreferences *) preferences;

@end

