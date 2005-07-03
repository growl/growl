//
//  GrowlApplicationNotification.m
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005 matrixPointer. All rights reserved.
//

#import "GrowlApplicationNotification.h"
#import "GrowlApplicationTicket.h"
#import "GrowlPluginController.h"
#import "GrowlDisplayProtocol.h"
#import "NSDictionaryAdditions.h"
#import "NSMutableDictionaryAdditions.h"

@implementation GrowlApplicationNotification

+ (GrowlApplicationNotification *) notificationWithName:(NSString *)theName {
	return [[[GrowlApplicationNotification alloc] initWithName:theName] autorelease];
}

+ (GrowlApplicationNotification *) notificationWithDictionary:(NSDictionary *)dict {
	return [[[GrowlApplicationNotification alloc] initWithDictionary:dict] autorelease];
}

+ (GrowlApplicationNotification *) notificationWithName:(NSString *)name
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

- (GrowlApplicationNotification *) initWithDictionary:(NSDictionary *)dict {
	NSString *inName = [dict objectForKey:@"Name"];

	id value = [dict objectForKey:@"Priority"];
	enum GrowlPriority inPriority = value ? [value intValue] : GrowlPriorityUnset;

	BOOL inEnabled = [dict boolForKey:@"Enabled"];

	int  inSticky  = [dict integerForKey:@"Sticky"];
	inSticky = (inSticky >= 0 ? (inSticky > 0 ? NSOnState : NSOffState) : NSMixedState);

	NSString *inDisplay = [dict objectForKey:@"Display"];

	return [self initWithName:inName
					 priority:inPriority
					  enabled:inEnabled
					   sticky:inSticky
			displayPluginName:inDisplay];
}

- (GrowlApplicationNotification *) initWithName:(NSString *)theName {
	return [self initWithName:theName priority:GrowlPriorityUnset enabled:YES sticky:NSMixedState displayPluginName:nil];
}

- (GrowlApplicationNotification *) initWithName:(NSString *)inName
									   priority:(enum GrowlPriority)inPriority
										enabled:(BOOL)inEnabled
										 sticky:(int)inSticky
							  displayPluginName:(NSString *)display
{
	if ((self = [super init])) {
		name     = [inName retain];
		priority = inPriority;
		enabled  = inEnabled;
		sticky   = inSticky;
		[self setDisplayPluginName:display];
	}
	return self;
}

- (void) dealloc {
	[name              release];

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
		[dict setInteger:priority forKey:@"Priority"];
	return dict;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"<%@ %p %@>", [self class], self, [[self dictionaryRepresentation] description]];
}

- (BOOL) isEqualToNotification:(GrowlApplicationNotification *) other {
	return [[self name] isEqualToString:[other name]];
}
#define GENERIC_EQUALITY_METHOD(other) {                                                                      \
	return ([other isKindOfClass:[GrowlApplicationNotification class]] && [self isEqualToNotification:other]); \
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
- (void) setDisplayPluginName: (NSString *)pluginName {
	[displayPluginName release];
	displayPluginName = [pluginName copy];
	if (displayPluginName)
		displayPlugin = [[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName];
	else
		displayPlugin = nil;
	[ticket synchronize];
}

- (id <GrowlDisplayPlugin>) displayPlugin {
	return displayPlugin;
}

@end
