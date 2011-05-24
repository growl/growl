//
//  GrowlNotificationTicket.m
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005-2006 matrixPointer. All rights reserved.
//

#import "GrowlNotificationTicket.h"
#import "GrowlApplicationTicket.h"
#import "GrowlPluginController.h"
#import "GrowlDisplayPlugin.h"
#include "CFDictionaryAdditions.h"
#include "CFMutableDictionaryAdditions.h"

@implementation GrowlNotificationTicket

+ (GrowlNotificationTicket *) notificationWithName:(NSString *)theName {
	return [[[GrowlNotificationTicket alloc] initWithName:theName] autorelease];
}

+ (GrowlNotificationTicket *) notificationWithDictionary:(NSDictionary *)dict {
	return [[[GrowlNotificationTicket alloc] initWithDictionary:dict] autorelease];
}

- (GrowlNotificationTicket *) initWithDictionary:(NSDictionary *)dict {
	NSString *inName = getObjectForKey(dict, @"Name");

	NSString *inHumanReadableName = getObjectForKey(dict, @"HumanReadableName");

	NSString *inNotificationDescription = getObjectForKey(dict, @"NotificationDescription");

	id value = getObjectForKey(dict, @"Priority");
	enum GrowlPriority inPriority = value ? [value intValue] : GrowlPriorityUnset;

	BOOL inEnabled = getBooleanForKey(dict, @"Enabled");

	int  inSticky  = getIntegerForKey(dict, @"Sticky");
	inSticky = (inSticky >= 0 ? (inSticky > 0 ? NSOnState : NSOffState) : NSMixedState);

	NSString *inDisplay = [dict objectForKey:@"Display"];
	NSString *inSound = [dict objectForKey:@"Sound"];

   BOOL logEnabled = YES;
   if([dict valueForKey:@"Logging"])
      logEnabled = getBooleanForKey(dict, @"Logging");

	return [self initWithName:inName
			humanReadableName:inHumanReadableName
	  notificationDescription:inNotificationDescription
					 priority:inPriority
					  enabled:inEnabled
              logEnabled:logEnabled
					   sticky:inSticky
			displayPluginName:inDisplay
						sound:inSound];
}

- (GrowlNotificationTicket *) initWithName:(NSString *)theName {
	return [self initWithName:theName
			humanReadableName:nil
	  notificationDescription:nil
					 priority:GrowlPriorityUnset
					  enabled:YES
              logEnabled:YES
					   sticky:NSMixedState
			displayPluginName:nil
						sound:nil];
}

- (GrowlNotificationTicket *) initWithName:(NSString *)inName
						 humanReadableName:(NSString *)inHumanReadableName
				   notificationDescription:(NSString *)inNotificationDescription
								  priority:(enum GrowlPriority)inPriority
								   enabled:(BOOL)inEnabled
                        logEnabled:(BOOL)inLogEnabled
									sticky:(int)inSticky
						 displayPluginName:(NSString *)display
									 sound:(NSString *)inSound
{
	if ((self = [self init])) {
		name					= [inName retain];
		humanReadableName		= [inHumanReadableName retain];
		notificationDescription = [inNotificationDescription retain];
		priority				= inPriority;
		enabled					= inEnabled;
      logNotification      = inLogEnabled;
		sticky					= inSticky;
		displayPluginName		= [display copy];
		sound					= [inSound retain];
	}
	return self;
}

- (void) dealloc {
	[name release];
	[humanReadableName release];
	[displayPluginName release];
	[notificationDescription release];
	[sound release];

	[super dealloc];
}

#pragma mark -

- (NSDictionary *) dictionaryRepresentation {
	NSNumber    *enabledValue = [[NSNumber alloc] initWithBool:enabled];
	NSNumber     *stickyValue = [[NSNumber alloc] initWithInt:sticky];
   NSNumber    *loggingValue = [[NSNumber alloc] initWithBool:logNotification];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name,         @"Name",
		enabledValue, @"Enabled",
		stickyValue,  @"Sticky",
      loggingValue, @"Logging",
		nil];
	[enabledValue release];
	[stickyValue  release];
   [loggingValue release];
	if (priority != GrowlPriorityUnset)
		setIntegerForKey(dict, @"Priority", priority);
	if (displayPluginName)
		setObjectForKey(dict, @"Display", displayPluginName);
	if (notificationDescription)
		setObjectForKey(dict, @"NotificationDescription", notificationDescription);
	if (humanReadableName)
		setObjectForKey(dict, @"HumanReadableName", humanReadableName);
	if (sound)
		setObjectForKey(dict, @"Sound", sound);

	return dict;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"<%@ %p %@>", [self class], self, [[self dictionaryRepresentation] description]];
}

- (BOOL) isEqualToNotification:(GrowlNotificationTicket *) other {
	return [[self name] isEqualToString:[other name]];
}
#define GENERIC_EQUALITY_METHOD(other) {                                                                      \
	return ([other isKindOfClass:[GrowlNotificationTicket class]] && [self isEqualToNotification:other]); \
}
//NSObject's way
- (BOOL) isEqualTo:(id) other GENERIC_EQUALITY_METHOD(other)
//Object's way
- (BOOL) isEqual:(id) other GENERIC_EQUALITY_METHOD(other)
#undef GENERIC_EQUALITY_METHOD

#pragma mark -

- (NSString *) name {
	return [[name retain] autorelease];
}

- (NSString *) humanReadableName {
	return (humanReadableName ? [[humanReadableName retain] autorelease] : [self name]);
}

- (void) setHumanReadableName:(NSString *)inHumanReadableName {
	if (humanReadableName != inHumanReadableName) {
		[humanReadableName release];
		humanReadableName = [inHumanReadableName retain];
	}
}

- (NSString *) notificationDescription {
	return notificationDescription;
}

- (void) setNotificationDescription:(NSString *)inNotificationDescription {
	if (notificationDescription != inNotificationDescription) {
		[notificationDescription release];
		notificationDescription = [inNotificationDescription retain];
	}
}

- (enum GrowlPriority) priority {
	return priority;
}
- (void) setPriority:(enum GrowlPriority)newPriority {
	priority = newPriority;
	[ticket synchronize];
}

- (BOOL) enabled {
	return enabled;
}
- (void) setEnabled:(BOOL)flag {
	enabled = flag;
	[ticket setUseDefaults:NO];
	[ticket synchronize];
}

- (BOOL) logNotification {
   return logNotification;
}

- (void) setLogNotification:(BOOL)flag {
   logNotification = flag;
	[ticket synchronize];
}

- (GrowlApplicationTicket *) ticket {
	return ticket;
}
- (void) setTicket:(GrowlApplicationTicket *)newTicket {
	ticket = newTicket;
}

// With sticky, 1 is on, 0 is off, -1 means use what's passed
// This corresponds to NSOnState, NSOffState, and NSMixedState
- (int) sticky {
	return sticky;
}
- (void) setSticky:(int)value {
	sticky = value;
	[ticket synchronize];
}

- (NSString *) displayPluginName {
	return displayPluginName;
}
- (void) setDisplayPluginName:(NSString *)pluginName {
	[displayPluginName release];
	displayPluginName = [pluginName copy];
	displayPlugin = nil;
	[ticket synchronize];
}

- (GrowlDisplayPlugin *) displayPlugin {
	if (!displayPlugin && displayPluginName)
		displayPlugin = (GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName author:nil version:nil type:nil];
	return displayPlugin;
}

- (NSComparisonResult) humanReadableNameCompare:(GrowlNotificationTicket *)inTicket {
	return [[self humanReadableName] caseInsensitiveCompare:[inTicket humanReadableName]];
}

- (NSString *) sound {
	return sound;
}
- (void) setSound:(NSString *)value {
	if (value != sound) {
		[sound release];
		sound = [value retain];
		[ticket synchronize];
	}
}

@end
