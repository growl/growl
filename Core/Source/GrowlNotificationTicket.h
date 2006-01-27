//
//  GrowlNotificationTicket.h
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005-2006 matrixPointer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlApplicationTicket, GrowlDisplayPlugin;

enum GrowlPriority {
	GrowlPriorityUnset     = -1000,
	GrowlPriorityVeryLow   = -2,
	GrowlPriorityLow       = -1,
	GrowlPriorityNormal    =  0,
	GrowlPriorityHigh      =  1,
	GrowlPriorityEmergency =  2
};

@interface GrowlNotificationTicket : NSObject {
	NSString                *name;
	NSString				*humanReadableName;
	NSString				*notificationDescription;

	GrowlApplicationTicket  *ticket;        // Our owner
	NSString				*displayPluginName;
	GrowlDisplayPlugin      *displayPlugin;
	int                      sticky;
	enum GrowlPriority       priority;
	unsigned                 GANReserved: 31;
	unsigned                 enabled: 1;
}

+ (GrowlNotificationTicket *) notificationWithName:(NSString *)name;
+ (GrowlNotificationTicket *) notificationWithDictionary:(NSDictionary *)dict;
+ (GrowlNotificationTicket *) notificationWithName:(NSString *)name
								 humanReadableName:(NSString *)inHumanReadableName
						   notificationDescription:(NSString *)inNotificationDescription
										  priority:(enum GrowlPriority)priority
										   enabled:(BOOL)enabled
											sticky:(int)sticky
								 displayPluginName:(NSString *)display;

- (GrowlNotificationTicket *) initWithName:(NSString *)name;
- (GrowlNotificationTicket *) initWithDictionary:(NSDictionary *)dict;
- (GrowlNotificationTicket *) initWithName:(NSString *)inName
						 humanReadableName:(NSString *)inHumanReadableName
				   notificationDescription:(NSString *)inNotificationDescription
								  priority:(enum GrowlPriority)inPriority
								   enabled:(BOOL)inEnabled
									sticky:(int)inSticky
						 displayPluginName:(NSString *)display;

#pragma mark -

- (NSDictionary *) dictionaryRepresentation;

- (BOOL) isEqualToNotification:(GrowlNotificationTicket *) other;

#pragma mark -

- (NSString *) name;

- (NSString *) humanReadableName;
- (void) setHumanReadableName:(NSString *)inHumanReadableName;

- (NSString *) notificationDescription;
- (void) setNotificationDescription:(NSString *)inNotificationDescription;

- (enum GrowlPriority) priority;
- (void) setPriority:(enum GrowlPriority)newPriority;

- (BOOL) enabled;
- (void) setEnabled:(BOOL)flag;

- (int) sticky;
- (void) setSticky:(int)sticky;

- (GrowlApplicationTicket *) ticket;
- (void) setTicket:(GrowlApplicationTicket *)newTicket;

- (NSString *) displayPluginName;
- (void) setDisplayPluginName: (NSString *)pluginName;
- (GrowlDisplayPlugin *) displayPlugin;

@end
