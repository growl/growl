//
//  GrowlRemotePathway.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-03-12.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"

@implementation GrowlRemotePathway

- (void) registerApplicationWithDictionary:(NSDictionary *)dict {
	if ([[GrowlPreferencesController sharedController] boolForKey:GrowlRemoteRegistrationKey]) {
		CFMutableDictionaryRef modifiedDict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, (CFDictionaryRef)dict);
		CFDictionarySetValue(modifiedDict, GROWL_REMOTE_ADDRESS, @"DO");
		[super registerApplicationWithDictionary:(NSDictionary *)modifiedDict];
		CFRelease(modifiedDict);
	}
}

- (void) postNotificationWithDictionary:(NSDictionary *)notification {
	CFMutableDictionaryRef modifiedDict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, (CFDictionaryRef)notification);
	CFDictionarySetValue(modifiedDict, GROWL_REMOTE_ADDRESS, @"DO");
	[super postNotificationWithDictionary:(NSDictionary *)modifiedDict];
	CFRelease(modifiedDict);
}

@end
