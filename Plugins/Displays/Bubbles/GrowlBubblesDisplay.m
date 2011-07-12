//
//  GrowlBubblesDisplay.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleController.h by Justin Burns on Fri Nov 05 2004.
//  Name changed from GrowlBubblesController.h by rudy on Tue Nov 29 2005.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlBubblesDisplay.h"
#import "GrowlBubblesWindowController.h"
#import "GrowlBubblesPrefsController.h"
#import "GrowlNotification.h"
#import "GrowlNotificationDisplayBridge.h"

#include "CFDictionaryAdditions.h"

@implementation GrowlBubblesController

#pragma mark -

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlBubblesWindowController");
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (BOOL)requiresPositioning {
	return YES;
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBubblesPrefsController alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Bubbles"]];
	return preferencePane;
}

@end
