//
//  GrowlApplicationTicket.h
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayProtocol.h"

@class GrowlController;

typedef enum GrowlPriority {
	GP_verylow		= -2,
	GP_low			= -1,
	GP_normal		=  0,
	GP_high         =  1,
	GP_emergency	=  2
} GrowlPriority;

@interface GrowlApplicationNotification : NSObject {
	NSString		*_name;
	GrowlPriority	 _priority;
	BOOL			 _enabled;
    int				 _sticky;
}

+ (GrowlApplicationNotification*) notificationWithName:(NSString*)name;
+ (GrowlApplicationNotification*) notificationFromDict:(NSDictionary*)dict;
- (GrowlApplicationNotification*) initWithName:(NSString*)name priority:(GrowlPriority)priority enabled:(BOOL)enabled sticky:(int)sticky;
- (NSDictionary*) notificationAsDict;

#pragma mark -

- (NSString*) name;

- (GrowlPriority) priority;
- (void) setPriority:(GrowlPriority)newPriority;

- (BOOL) enabled;
- (void) setEnabled:(BOOL)yorn;
- (void) enable;
- (void) disable;

- (int) sticky;
- (void) setSticky:(int)sticky;
@end

#pragma mark -
#pragma mark -

@interface GrowlApplicationTicket : NSObject {
	NSString		*_appName;					// The Applications's name for display by notifications that want it
	NSImage			*_icon;						// This app's icon for notifications and display methods that want it

	NSDictionary	*_allNotifications;		// All the notifications possible for this app

	NSArray			*_defaultNotifications;		// The default notifications
	
	BOOL			usesCustomDisplay;
	id <GrowlDisplayPlugin> displayPlugin;
	
	BOOL			_useDefaults;				// Flag for whether this ticket just uses default
	BOOL			ticketEnabled;
}

+ (NSDictionary *) allSavedTickets;
+ (void) loadTicketsFromDirectory:(NSString *)srcDir intoDictionary:(NSMutableDictionary *)dict clobbering:(BOOL)clobber;

- (id) initWithApplication:(NSString *) inAppName
				  withIcon:(NSImage *) inIcon
		  andNotifications:(NSArray *) inAllNotifications
		   andDefaultNotes:(NSArray *) inDefaults;

- (id) initTicketFromPath:(NSString *) inPath;
- (id) initTicketForApplication: (NSString *) inApp;

- (void) saveTicket;
- (void) saveTicketToPath:(NSString *)destDir;

#pragma mark -

- (NSImage *) icon;
- (void) setIcon:(NSImage *) inIcon;

- (NSString *) applicationName;

- (BOOL) ticketEnabled;
- (void) setEnabled:(BOOL)inEnabled;

- (BOOL)usesCustomDisplay;
- (void)setUsesCustomDisplay: (BOOL)inUsesCustomDisplay;

- (id <GrowlDisplayPlugin>) displayPlugin;
- (void) setDisplayPluginNamed: (NSString *)name;

#pragma mark -

-(void)reRegisterWithAllNotes:(NSArray *) inAllNotes defaults: (NSArray *) inDefaults icon:(NSImage *) inIcon;

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

#pragma mark Notification accessors
- (int) stickyForNotification:(NSString *) name;
- (void) setSticky:(int)sticky forNotification:(NSString *) name;

- (int) priorityForNotification:(NSString *) name;
- (void) setPriority:(int)priority forNotification:(NSString *) name;
@end

