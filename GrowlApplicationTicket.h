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
	NSMutableArray	*_allowedNotifications;		// The allowed notifications
	
	BOOL			_useDefaults;				// Flag for whether this ticket just uses default
	BOOL			ticketEnabled;
}

+ (NSDictionary *)allSavedTickets;
+ (void)loadTicketsFromDirectory:(NSString *)srcDir intoDictionary:(NSMutableDictionary *)dict clobbering:(BOOL)clobber;

- (id) initWithApplication:(NSString *)inAppName
				  withIcon:(NSImage *)inIcon
		  andNotifications:(NSArray *) inAllNotifications
		   andDefaultNotes:(NSArray *) inDefaults;

- (id) initTicketFromPath:(NSString *) inPath;
- (void) saveTicket;
- (void) saveTicketToPath:(NSString *)destDir;

#pragma mark -

- (NSImage *) icon;
- (void) setIcon:(NSImage *) inIcon;

- (NSString *) applicationName;

#pragma mark -

- (BOOL) ticketEnabled;
- (void) setEnabled:(BOOL)inEnabled;

- (NSArray *) allNotifications;
- (void) setAllNotifications:(NSArray *) inArray;

- (NSArray *) defaultNotifications;
- (void) setDefaultNotifications:(NSArray *) inArray;

- (NSArray *) allowedNotifications;
- (void) setAllowedNotifications:(NSArray *) inArray;
- (void) setAllowedNotificationsToDefault;

- (void) setNotificationEnabled:(NSString *) name;
- (void) setNotificationDisabled:(NSString *) name;
- (BOOL) isNotificationAllowed:(NSString *) name;
- (BOOL) isNotificationEnabled:(NSString *) name;
@end

