//
//  GrowlApplicationNotification.m
//  Growl
//
//  Created by Karl Adam on 10/29/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import "GrowlApplicationNotification.h"


@implementation GrowlApplicationNotification
+ (GrowlApplicationNotification *) notificationWithName:(NSString *)name {
    return [[[GrowlApplicationNotification alloc] initWithName:name priority:GP_normal enabled:YES sticky:NSMixedState] autorelease];
}

+ (GrowlApplicationNotification *) notificationFromDict:(NSDictionary *)dict {
    NSString* name = [dict objectForKey:@"Name"];
    GrowlPriority priority = [[dict objectForKey:@"Priority"] intValue];
    BOOL enabled = [[dict objectForKey:@"Enabled"] boolValue];
    int sticky = ([[dict objectForKey:@"Sticky"] intValue] >= 0 ? ([[dict objectForKey:@"Sticky"] intValue] > 0 ? NSOnState : NSOffState) : NSMixedState);
    return [[[GrowlApplicationNotification alloc] initWithName:name priority:priority enabled:enabled sticky:sticky] autorelease];
}

- (GrowlApplicationNotification *) initWithName:(NSString *)name priority:(GrowlPriority)priority enabled:(BOOL)enabled sticky:(int)sticky {
    [self init];
    _name = [name retain];
    _priority = priority;
    _enabled = enabled;
    _sticky = sticky;
    return self;
}

- (void) dealloc {
    if (_name) [_name release];
	
	_name = nil;
	
	[super dealloc];
}

- (NSDictionary *) notificationAsDict {
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
        _name, @"Name",
        [NSNumber numberWithInt:(int)_priority], @"Priority",
        [NSNumber numberWithBool:_enabled], @"Enabled",
        [NSNumber numberWithInt:_sticky], @"Sticky",
        nil];
    return dict;
}

#pragma mark -
- (NSString *) name {
	return [[_name copy] autorelease];
}

- (GrowlPriority) priority {
	return _priority;
}

- (void) setPriority:(GrowlPriority)newPriority {
    _priority = newPriority;
}

- (BOOL) enabled {
	return _enabled;
}

- (void) setEnabled:(BOOL)yorn {
    _enabled = yorn;
}

- (void) enable {
    [self setEnabled:YES];
}

- (void) disable {
    [self setEnabled:NO];
}

- (int) sticky {
    return _sticky;
}

- (void) setSticky:(int)sticky {
    _sticky = sticky;
}
@end

