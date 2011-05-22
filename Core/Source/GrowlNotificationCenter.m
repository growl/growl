//
//  GrowlNotificationCenter.m
//  Growl
//
//  Created by Ingmar Stein on 27.04.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlNotificationCenter.h"

@implementation GrowlNotificationCenter
- (id) init {
	if ((self = [super init])) {
		observers = [[NSMutableArray alloc] init];
	}
	return self;
}
- (void) dealloc {
	[observers release];

	[super dealloc];
}

- (oneway void) addObserver:(byref id<GrowlNotificationObserver>)observer {
	[observers addObject:observer];
}

- (oneway void) removeObserver:(byref id<GrowlNotificationObserver>)observer {
	[observers removeObject:observer];
}

- (void) notifyObservers:(NSDictionary *)notificationDict {
	for (id<GrowlNotificationObserver> observer in observers) {
		@try {
			[observer notifyWithDictionary:notificationDict];
		} @catch(NSException *ex) {
			NSLog(@"Exception while notifying observer: %@", ex);
		}
	}
}

@end
