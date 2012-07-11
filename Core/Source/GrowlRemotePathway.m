//
//  GrowlRemotePathway.m
//  Growl
//
//  Created by Peter Hosey on 2005-03-12.
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

- (GrowlNotificationResult) postNotificationWithDictionary:(bycopy NSDictionary *)dict {
	if (enabled) {
		return [super postNotificationWithDictionary:dict];
	}
	return GrowlNotificationResultDisabled;
}

#pragma mark -

@synthesize enabled;

@end
