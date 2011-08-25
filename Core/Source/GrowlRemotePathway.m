//
//  GrowlRemotePathway.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-03-12.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"

@implementation GrowlRemotePathway

- (BOOL) registerApplicationWithDictionary:(bycopy NSDictionary *)dict {
	if (enabled && [[GrowlPreferencesController sharedController] isGrowlServerEnabled]) {
		[super registerApplicationWithDictionary:dict];		
		return YES;
	} else {
		return NO;
	}
}

- (oneway void) postNotificationWithDictionary:(bycopy NSDictionary *)dict {
	if (enabled) {
		[super postNotificationWithDictionary:dict];
	}
}

#pragma mark -

@synthesize enabled;

@end
