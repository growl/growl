//
//  GrowlRemotePathway.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-03-12.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"

@implementation GrowlRemotePathway

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	if ([[GrowlPreferencesController sharedController] boolForKey:GrowlRemoteRegistrationKey]) {
		NSMutableDictionary *modifiedDict = [dict mutableCopy];
		[modifiedDict setObject:@"DO" forKey:GROWL_REMOTE_ADDRESS];

		[super registerApplicationWithDictionary:modifiedDict];

		[modifiedDict release];
	}
}

- (void) postNotificationWithDictionary:(NSDictionary *)dict {
	NSMutableDictionary *modifiedDict = [dict mutableCopy];
	[modifiedDict setObject:@"DO" forKey:GROWL_REMOTE_ADDRESS];

	[super postNotificationWithDictionary:modifiedDict];

	[modifiedDict release];
}

@end
