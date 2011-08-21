//
//  GrowlApplicationTicket.h
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import <Foundation/Foundation.h>

@class GrowlNotificationTicket, GrowlDisplayPlugin;

@interface GrowlApplicationTicket : NSObject {
   NSString    *appNameHostName;           // This is <appName> - <hostName>
	NSString		*appName;					// This app's name for display by notifications that want it
   NSString    *hostName;              // This is the host which registered this
	NSString		*appId;						// This app's bundle identifier
	NSString		*appPath;					// This app's location on disk (cached here and in saved tickets)
	NSData			*iconData;					// This app's icon data
	NSImage			*icon;						// This app's icon

	NSDictionary	*allNotifications;			// All the notifications possible for this app
	NSArray			*allNotificationNames;		// Keys of allNotifications, in the order in which they were originally passed

	NSArray			*defaultNotifications;		// The default notifications

	NSDictionary	*humanReadableNames;		// Dictionary of human readable names
	NSDictionary	*notificationDescriptions;	// Dictionary of notification descriptions

	NSString		*displayPluginName;
	GrowlDisplayPlugin *displayPlugin;		    // Non-nil if this ticket uses a custom display plugin
	
	NSInteger		positionType;				// Integer that tracks the selected position type (default or custom currently)
	NSInteger		selectedCustomPosition;		// Integer that tracks the selected custom position [int value translated from enum] FRAGILE

	BOOL            changed;
	BOOL			useDefaults;				// Flag for whether this ticket just uses default
	BOOL			ticketEnabled;
	BOOL			clickHandlersEnabled;		// Flag whether click handlers are enabled
	
	BOOL			synchronizeOnChanges;
   BOOL        isLocalHost;               //If we are local host, this is a faster way of checking than doing string checks
	
}

//these are specifically for auto-discovery tickets, hence the requirement of GROWL_TICKET_VERSION.
+ (BOOL) isValidTicketDictionary:(NSDictionary *)dict;
+ (BOOL) isKnownTicketVersion:(NSDictionary *)dict;

#pragma mark -

//designated initialiser.
+ (id) ticketWithDictionary:(NSDictionary *)ticketDict;
- (id) initWithDictionary:(NSDictionary *)dict;

- (id) initTicketFromPath:(NSString *) inPath;
- (id) initTicketForApplication: (NSString *) inApp;

- (void) saveTicket;
- (void) saveTicketToPath:(NSString *)destDir;
- (NSString *) path;
- (void) synchronize;

#pragma mark -

@property (nonatomic, assign) BOOL hasChanged;

- (NSData *) iconData;
- (void) setIconData:(NSData *) inIconData;

- (NSString *) applicationName;
@property (nonatomic, readonly) NSString* appNameHostName;
@property (nonatomic, readonly) BOOL isLocalHost;

@property (nonatomic, assign) BOOL ticketEnabled;
@property (nonatomic, assign) BOOL clickHandlersEnabled;
@property (nonatomic, assign) BOOL useDefaults;
@property (nonatomic, assign) NSInteger positionType;
@property (nonatomic, assign) NSInteger selectedPosition;
@property (nonatomic, copy) NSString *displayPluginName;

- (GrowlDisplayPlugin *) displayPlugin;

#pragma mark -

- (void) reregisterWithAllNotifications:(NSArray *) inAllNotes
							   defaults:(id) inDefaults
							   iconData:(NSData *) inIconData;
- (void) reregisterWithDictionary:(NSDictionary *) dict;

- (NSArray *) allNotifications;
- (void) setAllNotifications:(NSArray *) inArray;

- (NSArray *) defaultNotifications;
- (void) setDefaultNotifications:(id) inObject;

- (NSArray *) allowedNotifications;
- (void) setAllowedNotifications:(NSArray *) inArray;
- (void) setAllowedNotificationsToDefault;

- (BOOL) isNotificationAllowed:(NSString *) name;

#pragma mark Notification accessors
- (NSArray *) notifications;
- (GrowlNotificationTicket *) notificationTicketForName:(NSString *)name;

@end
