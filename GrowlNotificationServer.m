//
//  GrowlNotificationServer.m
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlNotificationServer.h"
#import "GrowlController.h"

@implementation GrowlNotificationServer

- (void) registerApplication:(NSDictionary *)dict {
	BOOL enabled = [[[GrowlPreferences preferences] objectForKey:GrowlRemoteRegistrationKey] boolValue];
	if ( enabled ) {
		[[GrowlController singleton] registerApplicationWithDictionary:dict];
	}
}

- (void) postNotification:(NSDictionary *)notification {
	[[GrowlController singleton] dispatchNotificationWithDictionary:notification];
}

- (NSString *) growlVersion {
	return [[GrowlController singleton] growlVersion];
}
@end
