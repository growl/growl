//
//  GrowlApplicationTicket.h
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//

#import <Foundation/Foundation.h>

@class GrowlController;

@interface GrowlApplicationTicket : NSObject {
	NSString		*_appName;					// The Applications's name for display by notifications that want it
	NSImage			*_icon;						// This app's icon for notifications and display methods that want it
	NSSet			*_allNotifications;			// All the notifications possible for this app
	NSSet			*_defaultNotifications;		// The default notifications
	NSArray			*_allowedNotifications;		// The allowed notifications
	
	GrowlController *_parent;					// The GrowlController from which we came
	
	BOOL			_useDefaults;				// Flag for whether this ticket just uses default
}

- (id) initWithApplication:(NSString *)inAppName 
				  withIcon:(NSImage *)inIcon 
		  andNotifications:(NSSet *) inAllNotifications 
			 andDefaultSet:(NSSet *) inDefaultSet 
				fromParent:(GrowlController *) parent;

- (id) initTicketFromPath:(NSString *) inPath;
- (void) saveTicket;

#pragma mark -

- (NSImage *) icon;

#pragma mark -

- (NSSet *) allNotifications;
- (void) setAllNotifications:(NSSet *) inSet;

- (NSSet *) defaultNotifications;
- (void) setDefaultNotifications:(NSSet *) inSet;

#pragma mark -

- (void) registerParentForNotifications:(NSSet *) inSet;
- (void) unregisterParentForNotifications:(NSArray *) inArray;
@end
