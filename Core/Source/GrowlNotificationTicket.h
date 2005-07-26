//
//  GrowlNotificationTicket.h
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005 matrixPointer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlApplicationTicket;
@protocol GrowlDisplayPlugin;

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
	GrowlApplicationTicket  *ticket;        // Our owner
	NSString				*displayPluginName;
	id <GrowlDisplayPlugin>	 displayPlugin;
	int                      sticky;
	enum GrowlPriority       priority;
	unsigned                 GANReserved: 31;
	unsigned                 enabled: 1;
}

+ (GrowlNotificationTicket *) notificationWithName:(NSString *)name;
+ (GrowlNotificationTicket *) notificationWithDictionary:(NSDictionary *)dict;
+ (GrowlNotificationTicket *) notificationWithName:(NSString *)name
										  priority:(enum GrowlPriority)priority
										   enabled:(BOOL)enabled
											sticky:(int)sticky
								 displayPluginName:(NSString *)display;

- (GrowlNotificationTicket *) initWithName:(NSString *)name;
- (GrowlNotificationTicket *) initWithDictionary:(NSDictionary *)dict;
- (GrowlNotificationTicket *) initWithName:(NSString *)name
								  priority:(enum GrowlPriority)priority
								   enabled:(BOOL)enabled
									sticky:(int)sticky
						 displayPluginName:(NSString *)display;

#pragma mark -

- (NSDictionary *) dictionaryRepresentation;

- (BOOL) isEqualToNotification:(GrowlNotificationTicket *) other;

#pragma mark -

- (NSString *) name;

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
- (id <GrowlDisplayPlugin>) displayPlugin;

@end
