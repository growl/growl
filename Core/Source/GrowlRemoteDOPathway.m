//
//  GrowlNotificationServer.m
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlRemoteDOPathway.h"
#import "GrowlController.h"

@implementation GrowlRemoteDOPathway

- (void) registerApplication:(NSDictionary *)dict {
	BOOL enabled = [[[GrowlPreferences preferences] objectForKey:GrowlRemoteRegistrationKey] boolValue];
	if ( enabled ) {
		[[GrowlController standardController] registerApplicationWithDictionary:dict];
	}
}

- (void) postNotification:(NSDictionary *)notification {
	[[GrowlController standardController] dispatchNotificationWithDictionary:notification];
}

- (NSString *) growlVersion {
	return [[GrowlController standardController] growlVersion];
}
@end
