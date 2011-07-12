//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlBezelDisplay.h"
#import "GrowlBezelWindowController.h"
#import "GrowlBezelPrefs.h"
#import "GrowlDefinesInternal.h"
#import "GrowlNotification.h"
#import "GrowlNotificationDisplayBridge.h"

#include "CFDictionaryAdditions.h"

@implementation GrowlBezelDisplay

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlBezelWindowController");
	}
	return self;
}

- (void) dealloc {
	[preferencePane    release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBezelPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Bezel"]];
	return preferencePane;
}

//we implement requiresPositioning entirely because it was added as a requirement for doing 1.1 plugins, however
//we don't really care if positioning is required or not, because we have our own fixed positions
- (BOOL)requiresPositioning {
	return NO;
}

@end
