//
//  GrowlNotificationTicket.m
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005 matrixPointer. All rights reserved.
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

+ (GrowlNotificationTicket *) notificationWithName:(NSString *)name
										  priority:(enum GrowlPriority)priority
										   enabled:(BOOL)enabled
											sticky:(int)sticky
								 displayPluginName:(NSString *)display
{
	return [[[self alloc] initWithName:name
							  priority:priority
							   enabled:enabled
								sticky:sticky
					 displayPluginName:display] autorelease];
}

- (GrowlNotificationTicket *) initWithDictionary:(NSDictionary *)dict {
	NSString *inName = getObjectForKey(dict, @"Name");

	id value = getObjectForKey(dict, @"Priority");
	enum GrowlPriority inPriority = value ? [value intValue] : GrowlPriorityUnset;

	BOOL inEnabled = getBooleanForKey(dict, @"Enabled");

	int  inSticky  = getIntegerForKey(dict, @"Sticky");
	inSticky = (inSticky >= 0 ? (inSticky > 0 ? NSOnState : NSOffState) : NSMixedState);

	NSString *inDisplay = [dict objectForKey:@"Display"];

	return [self initWithName:inName
					 priority:inPriority
					  enabled:inEnabled
					   sticky:inSticky
			displayPluginName:inDisplay];
}

- (GrowlNotificationTicket *) initWithName:(NSString *)theName {
	return [self initWithName:theName priority:GrowlPriorityUnset enabled:YES sticky:NSMixedState displayPluginName:nil];
}

- (GrowlNotificationTicket *) initWithName:(NSString *)inName
								  priority:(enum GrowlPriority)inPriority
								   enabled:(BOOL)inEnabled
									sticky:(int)inSticky
						 displayPluginName:(NSString *)display
{
	if ((self = [super init])) {
		name              = [inName retain];
		priority          = inPriority;
		enabled           = inEnabled;
		sticky            = inSticky;
		displayPluginName = [display copy];
	}
	return self;
}

- (void) dealloc {
	[name release];

	[super dealloc];
}

#pragma mark -

- (NSDictionary *) dictionaryRepresentation {
	NSNumber    *enabledValue = [[NSNumber alloc] initWithBool:enabled];
	NSNumber     *stickyValue = [[NSNumber alloc] initWithInt:sticky];
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name,         @"Name",
		enabledValue, @"Enabled",
		stickyValue,  @"Sticky",
		nil];
	[enabledValue release];
	[stickyValue  release];
	if (priority != GrowlPriorityUnset)
		setIntegerForKey(dict, @"Priority", priority);
	if (displayPluginName)
		setObjectForKey(dict, @"Display", displayPluginName);
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
		displayPlugin = [[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName];
	return displayPlugin;
}

@end
