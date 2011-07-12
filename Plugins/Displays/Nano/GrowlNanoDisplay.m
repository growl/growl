//
//  GrowlNanoDisplay.m
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005-2006, The Growl Project. All rights reserved.
//

#import "GrowlNanoDisplay.h"
#import "GrowlNanoWindowController.h"
#import "GrowlNanoPrefs.h"
#import "GrowlDefinesInternal.h"
#import "GrowlNotification.h"
#import "GrowlNotificationDisplayBridge.h"

#include "CFDictionaryAdditions.h"

@implementation GrowlNanoDisplay

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlNanoWindowController");
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlNanoPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Nano"]];
	return preferencePane;
}

//we implement requiresPositioning entirely because it was added as a requirement for doing 1.1 plugins, however
//we don't really care if positioning is required or not, because we are only ever in the menubar.
- (BOOL)requiresPositioning {
	return NO;
}

@end
