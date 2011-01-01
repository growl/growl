//
//  GrowlDistributedNotificationPathway.m
//  Growl
//
//  Created by Peter Hosey on 2005-03-12.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlDistributedNotificationPathway.h"
#import "GrowlDefines.h"

@implementation GrowlDistributedNotificationPathway

- (id) init {
	if ((self = [super init])) {
		NSDistributedNotificationCenter *dnc = [NSDistributedNotificationCenter defaultCenter];
		[dnc addObserver:self
				selector:@selector(gotGrowlRegistration:)
					name:GROWL_APP_REGISTRATION
				  object:nil];
		[dnc addObserver:self
				selector:@selector(gotGrowlNotification:)
					name:GROWL_NOTIFICATION
				  object:nil];
	}
	return self;
}
- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self
															   name:nil
															 object:nil];
	[super dealloc];
}

#pragma mark -

- (void) gotGrowlRegistration:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerApplicationWithDictionary:[notification userInfo]];
	[pool release];
}

- (void) gotGrowlNotification:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self postNotificationWithDictionary:[notification userInfo]];
	[pool release];
}

@end
