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

@synthesize name;
@synthesize humanReadableName;
@synthesize priority;
@synthesize enabled;
@synthesize logNotification;
@synthesize sticky;
@synthesize ticket;
@synthesize displayPluginName;
@synthesize sound;
@synthesize notificationDescription;

+ (GrowlNotificationTicket *) notificationWithName:(NSString *)theName {
	return [[[GrowlNotificationTicket alloc] initWithName:theName] autorelease];
}

+ (GrowlNotificationTicket *) notificationWithDictionary:(NSDictionary *)dict {
	return [[[GrowlNotificationTicket alloc] initWithDictionary:dict] autorelease];
}

- (GrowlNotificationTicket *) initWithDictionary:(NSDictionary *)dict {
	NSString *inName = [dict objectForKey:@"Name"];

	NSString *inHumanReadableName = [dict objectForKey:@"HumanReadableName"];

	NSString *inNotificationDescription = [dict objectForKey:@"NotificationDescription"];

	id value = [dict objectForKey:@"Priority"];
	enum GrowlPriority inPriority = value ? [value intValue] : GrowlPriorityUnset;

	BOOL inEnabled = [[dict objectForKey:@"Enabled"] boolValue];

	int  inSticky  = [[dict objectForKey:@"Sticky"] intValue];
	inSticky = (inSticky >= 0 ? (inSticky > 0 ? NSOnState : NSOffState) : NSMixedState);

	NSString *inDisplay = [dict objectForKey:@"Display"];
	NSString *inSound = [dict objectForKey:@"Sound"];

   BOOL logEnabled = YES;
   if([dict valueForKey:@"Logging"])
       logEnabled = [[dict objectForKey:@"Logging"] boolValue];

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
		self.name                       = inName;
		self.humanReadableName          = inHumanReadableName;
		self.notificationDescription    = inNotificationDescription;
		self.priority                   = inPriority;
		self.enabled					= inEnabled;
        self.logNotification            = inLogEnabled;
		self.sticky                     = inSticky;
		self.displayPluginName          = display;
		self.sound                      = inSound;
        
        [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"humanReadableName" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"notificationDescription" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"priority" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"enabled" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"logNotification" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"sticky" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"displayPluginName" options:NSKeyValueObservingOptionNew context:&self];
        [self addObserver:self forKeyPath:@"sound" options:NSKeyValueObservingOptionNew context:&self];
        
	}
	return self;
}

- (void) dealloc {
    
    [self removeObserver:self forKeyPath:@"name"];
    [self removeObserver:self forKeyPath:@"humanReadableName"];
    [self removeObserver:self forKeyPath:@"notificationDescription"];
    [self removeObserver:self forKeyPath:@"priority"];
    [self removeObserver:self forKeyPath:@"enabled"];
    [self removeObserver:self forKeyPath:@"logNotification"];
    [self removeObserver:self forKeyPath:@"sticky"];
    [self removeObserver:self forKeyPath:@"displayPluginName"];
    [self removeObserver:self forKeyPath:@"sound"];
    
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"priority"]) {
        [ticket synchronize];
    } else if( [keyPath isEqualToString:@"enabled"]) {
        [ticket setUseDefaults:NO];
        [ticket synchronize];
    } else if( [keyPath isEqualToString:@"logNotification"]) {
        [ticket synchronize];
    } else if( [keyPath isEqualToString:@"sticky"]) {
        [ticket synchronize];
    } else if( [keyPath isEqualToString:@"displayPluginName"]) {
        displayPlugin = nil;
        [ticket synchronize];
    } else if( [keyPath isEqualToString:@"sound"]) {
        [ticket synchronize];
    }
}

- (NSString *) humanReadableName {
	return (humanReadableName ? humanReadableName : [self name]);
}

- (GrowlDisplayPlugin *) displayPlugin {
	if (!displayPlugin && displayPluginName)
		displayPlugin = (GrowlDisplayPlugin *)[[GrowlPluginController sharedController] displayPluginInstanceWithName:displayPluginName author:nil version:nil type:nil];
	return displayPlugin;
}

- (NSComparisonResult) humanReadableNameCompare:(GrowlNotificationTicket *)inTicket {
	return [[self humanReadableName] caseInsensitiveCompare:[inTicket humanReadableName]];
}

@end
