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
	NSArray			*_allNotifications;			// All the notifications possible for this app
	NSArray			*_defaultNotifications;		// The default notifications
	NSArray			*_allowedNotifications;		// The allowed notifications
	
	GrowlController *_parent;					// The GrowlController from which we came
	
	BOOL			_useDefaults;				// Flag for whether this ticket just uses default
}

- (id) initWithApplication:(NSString *)inAppName 
				  withIcon:(NSImage *)inIcon 
		  andNotifications:(NSArray *) inAllNotifications 
		   andDefaultNotes:(NSArray *) inDefaults 
				fromParent:(GrowlController *) parent;

- (id) initTicketFromPath:(NSString *) inPath withParent:(GrowlController *) inParent;
- (void) saveTicket;

#pragma mark -

- (NSImage *) icon;
- (void) setIcon:(NSImage *) inIcon;

#pragma mark -

- (NSArray *) allNotifications;
- (void) setAllNotifications:(NSArray *) inArray;

- (NSArray *) defaultNotifications;
- (void) setDefaultNotifications:(NSArray *) inArray;

#pragma mark -

- (void) registerParentForNotifications:(NSArray *) inArray;
- (void) unregisterParentForNotifications:(NSArray *) inArray;
@end

