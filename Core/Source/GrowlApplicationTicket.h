//
//  GrowlApplicationTicket.h
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import <Foundation/Foundation.h>

@protocol GrowlDisplayPlugin;

@interface GrowlApplicationTicket : NSObject {
	NSString		*appName;					// The Applications's name for display by notifications that want it
	NSImage			*icon;						// This app's icon for notifications and display methods that want it

	NSDictionary	*allNotifications;			// All the notifications possible for this app
	NSArray			*allNotificationNames;		// Keys of allNotifications, in the order in which they were originally passed

	NSArray			*defaultNotifications;		// The default notifications
	
	BOOL			usesCustomDisplay;
	id <GrowlDisplayPlugin> displayPlugin;
	
	BOOL			useDefaults;				// Flag for whether this ticket just uses default
	BOOL			ticketEnabled;
}

+ (NSDictionary *) allSavedTickets;
+ (void) loadTicketsFromDirectory:(NSString *)srcDir intoDictionary:(NSMutableDictionary *)dict clobbering:(BOOL)clobber;

//these are specifically for auto-discovery tickets, hence the requirement of GROWL_TICKET_VERSION.
+ (BOOL)isValidTicketDictionary:(NSDictionary *)dict;
+ (BOOL)isKnownTicketVersion:(NSDictionary *)dict;

- (id) initWithApplication:(NSString *) inAppName
				  withIcon:(NSImage *) inIcon
		  andNotifications:(NSArray *) inAllNotifications
		   andDefaultNotes:(id) inDefaults;

- (id) initTicketFromPath:(NSString *) inPath;
- (id) initTicketForApplication: (NSString *) inApp;

- (void) saveTicket;
- (void) saveTicketToPath:(NSString *)destDir;
- (NSString *) path;

#pragma mark -

- (NSImage *) icon;
- (void) setIcon:(NSImage *) inIcon;

- (NSString *) applicationName;

- (BOOL) ticketEnabled;
- (void) setEnabled:(BOOL)inEnabled;

- (BOOL) usesCustomDisplay;
- (void) setUsesCustomDisplay: (BOOL)inUsesCustomDisplay;

- (id <GrowlDisplayPlugin>) displayPlugin;
- (void) setDisplayPluginNamed: (NSString *)name;

#pragma mark -

-(void) reregisterWithAllNotifications:(NSArray *) inAllNotes defaults: (id) inDefaults icon:(NSImage *) inIcon;

- (NSArray *) allNotifications;
- (void) setAllNotifications:(NSArray *) inArray;

- (NSArray *) defaultNotifications;
- (void) setDefaultNotifications:(id) inObject;

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
- (void) resetPriorityForNotification:(NSString *) name;
@end

