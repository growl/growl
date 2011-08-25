//
//  GrowlSmokeDisplay.m
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlSmokeDisplay.h"
#import "GrowlSmokeWindowController.h"
#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlNotification.h"
#import "GrowlNotificationDisplayBridge.h"


@implementation GrowlSmokeDisplay

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlSmokeWindowController");
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlSmokePrefsController alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Smoke"]];
	return preferencePane;
}

- (BOOL)requiresPositioning {
	return YES;
}

@end
