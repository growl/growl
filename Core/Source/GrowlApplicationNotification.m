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

+ (GrowlApplicationNotification *) notificationFromDictionary:(NSDictionary *)dict {
	return [[[GrowlApplicationNotification alloc] initWithDictionary:dict] autorelease];
}

+ (GrowlApplicationNotification *) notificationWithName:(NSString *)name
											   priority:(enum GrowlPriority)priority
												enabled:(BOOL)enabled
												 sticky:(int)sticky
{
	return [[[self alloc] initWithName:name
							  priority:priority
							   enabled:enabled
								sticky:sticky] autorelease];
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
{
	if ((self = [super init])) {
		name     = [inName retain];
		priority = inPriority;
		enabled  = inEnabled;
		sticky   = inSticky;
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

@end
