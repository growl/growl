//
//  GrowlApplicationNotification.m
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005 matrixPointer. All rights reserved.
//

#import "GrowlApplicationNotification.h"
#import "GrowlPluginController.h"
#import "GrowlDisplayProtocol.h"

@implementation GrowlApplicationNotification
+ (GrowlApplicationNotification *) notificationWithName:(NSString *)theName {
	return [[[GrowlApplicationNotification alloc] initWithName:theName] autorelease];
}

+ (GrowlApplicationNotification *) notificationFromDict:(NSDictionary *)dict {
	return [[[GrowlApplicationNotification alloc] initWithDict:dict] autorelease];
}

- (GrowlApplicationNotification *) initWithDict:(NSDictionary *)dict {
	NSString *inName = [dict objectForKey:@"Name"];
	GrowlPriority inPriority;
	id value = [dict objectForKey:@"Priority"];
	if (value) {
		inPriority = [value intValue];
	} else {
		inPriority = GP_unset;
	}
	BOOL inEnabled = [[dict objectForKey:@"Enabled"] boolValue];
	int inSticky = [[dict objectForKey:@"Sticky"] intValue];
	inSticky = (inSticky >= 0 ? (inSticky > 0 ? NSOnState : NSOffState) : NSMixedState);
	NSString *inDisplay = [dict objectForKey:@"Display"];

	return [self initWithName:inName priority:inPriority enabled:inEnabled sticky:inSticky displayPlugin:inDisplay];
}

- (GrowlApplicationNotification *) initWithName:(NSString *)theName {
	return [self initWithName:theName priority:GP_unset enabled:YES sticky:NSMixedState displayPlugin:nil];
}

- (GrowlApplicationNotification *) initWithName:(NSString *)inName priority:(GrowlPriority)inPriority enabled:(BOOL)inEnabled sticky:(int)inSticky displayPlugin:(NSString *)display {
	if ((self = [super init])) {
		name = [inName retain];
		priority = inPriority;
		enabled = inEnabled;
		sticky = inSticky;
		displayPluginName = display;
		if (display) {
			displayPlugin = [[GrowlPluginController controller] displayPluginNamed:display];
		}
	}
	return self;
}

- (NSDictionary *) notificationAsDict {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name, @"Name",
		[NSNumber numberWithBool:enabled], @"Enabled",
		[NSNumber numberWithInt:sticky], @"Sticky",
		nil];
	if (priority != GP_unset) {
		[dict setObject:[NSNumber numberWithInt:priority] forKey:@"Priority"];
	}
	if (displayPluginName) {
		[dict setObject:displayPluginName forKey:@"Display"];
	}
	return dict;
}

- (void) dealloc {
	[name              release];
	[displayPluginName release];
	[super dealloc];
}

#pragma mark -
- (NSString *) name {
	return [[name retain] autorelease];
}

- (GrowlPriority) priority {
	return priority;
}

- (void) setPriority:(GrowlPriority)newPriority {
	priority = newPriority;
}

- (void) resetPriority {
	priority = GP_unset;
}

- (BOOL) enabled {
	return enabled;
}

- (void) setEnabled:(BOOL)flag {
	enabled = flag;
}

- (void) enable {
	[self setEnabled:YES];
}

- (void) disable {
	[self setEnabled:NO];
}

- (int) sticky {
	return sticky;
}

- (void) setSticky:(int)value {
	sticky = value;
}

- (id <GrowlDisplayPlugin>) displayPlugin {
	return displayPlugin;
}

- (NSString *)displayPluginName {
	return displayPluginName;
}

- (void) setDisplayPluginNamed: (NSString *)pluginName {
	[displayPluginName release];
	displayPluginName = [pluginName retain];
	if (displayPluginName) {
		displayPlugin = [[GrowlPluginController controller] displayPluginNamed:displayPluginName];
	} else {
		displayPlugin = nil;
	}
}
@end
