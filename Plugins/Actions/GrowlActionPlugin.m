//
//  GrowlActionPlugin.m
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlActionPlugin.h>

@implementation GrowlActionPlugin

-(BOOL)requiresMainThread {
	return NO;
}

-(NSDictionary*)requiredEntitlements {
	return nil;
}

@end
