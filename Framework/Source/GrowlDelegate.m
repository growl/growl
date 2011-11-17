//
//  GrowlDelegate.m
//  Growl
//
//  Created by Ingmar Stein on 16.04.05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDelegate.h"

@implementation GrowlDelegate
@synthesize applicationNameForGrowl;
@synthesize applicationIconDataForGrowl;
@synthesize registrationDictionaryForGrowl = registrationDictionary;

- (id) initWithAllNotifications:(NSArray *)allNotifications defaultNotifications:(NSArray *)defaultNotifications {
	if ((self = [self init])) {
		self.registrationDictionaryForGrowl = [[[NSDictionary alloc] initWithObjectsAndKeys:
			allNotifications,     GROWL_NOTIFICATIONS_ALL,
			defaultNotifications, GROWL_NOTIFICATIONS_DEFAULT,
			nil] autorelease];
	}
	return self;
}

- (void) dealloc {
	[registrationDictionary release];
	[applicationNameForGrowl release];
	[applicationIconDataForGrowl release];
	[super dealloc];
}

@end
