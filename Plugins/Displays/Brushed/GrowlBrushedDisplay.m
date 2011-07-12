//
//  GrowlBrushedDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlNotificationDisplayBridge.h"
#import "GrowlBrushedDisplay.h"
#import "GrowlBrushedWindowController.h"
#import "GrowlBrushedPrefsController.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlNotification.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlBrushedDisplay

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlBrushedWindowController");
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBrushedPrefsController alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Brushed"]];
	return preferencePane;
}

- (BOOL) requiresPositioning {
	return YES;
}

@end
