//
//  GrowlApplicationNotification.m
//  Growl
//
//  Created by Karl Adam on 01.10.05.
//  Copyright 2005 matrixPointer. All rights reserved.
//

#import "GrowlApplicationNotification.h"


@implementation GrowlApplicationNotification
+ (GrowlApplicationNotification*) notificationWithName:(NSString*)theName {
	return [[[GrowlApplicationNotification alloc] initWithName:theName priority:GP_unset enabled:YES sticky:NSMixedState] autorelease];
}

+ (GrowlApplicationNotification*) notificationFromDict:(NSDictionary*)dict {
	NSString* inName = [dict objectForKey:@"Name"];
	GrowlPriority inPriority;
	if ([dict objectForKey:@"Priority"]) {
		inPriority = [[dict objectForKey:@"Priority"] intValue];
	} else {
		inPriority = GP_unset;
	}
	BOOL inEnabled = [[dict objectForKey:@"Enabled"] boolValue];
	int inSticky = ([[dict objectForKey:@"Sticky"] intValue] >= 0 ? ([[dict objectForKey:@"Sticky"] intValue] > 0 ? NSOnState : NSOffState) : NSMixedState);
	return [[[GrowlApplicationNotification alloc] initWithName:inName priority:inPriority enabled:inEnabled sticky:inSticky] autorelease];
}

- (GrowlApplicationNotification*) initWithName:(NSString*)inName priority:(GrowlPriority)inPriority enabled:(BOOL)inEnabled sticky:(int)inSticky {
	if ( (self = [super init] ) ) {
		name = [inName retain];
		priority = inPriority;
		enabled = inEnabled;
		sticky = inSticky;
	}
	return self;
}

- (NSDictionary*) notificationAsDict {
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		name, @"Name",
		[NSNumber numberWithBool:enabled], @"Enabled",
		[NSNumber numberWithInt:sticky], @"Sticky",
		nil];
	if (priority != GP_unset) {
		[dict setObject:[NSNumber numberWithInt:priority] forKey:@"Priority"];
	}
	return dict;
}

- (void) dealloc {
	[name release];
	[super dealloc];
}

#pragma mark -
- (NSString*) name {
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
@end

