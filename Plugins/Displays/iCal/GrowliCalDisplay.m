//
//  GrowliCalDisplay.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleController.h by Justin Burns on Fri Nov 05 2004.
//  Name changed from GrowlBubblesController.h by rudy on Tue Nov 29 2005.
//	Adapted for iCal by Takumi Murayama on Thu Aug 17 2006.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowliCalDisplay.h"
#import "GrowliCalWindowController.h"
#import "GrowliCalPrefsController.h"
#import "GrowlNotification.h"
#import "GrowlNotificationDisplayBridge.h"

#include "CFDictionaryAdditions.h"

@implementation GrowliCalDisplay

#pragma mark -

- (id) init {
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowliCalWindowController");
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowliCalPrefsController alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.iCal"]];
	return preferencePane;
}

- (BOOL)requiresPositioning {
	return YES;
}

@end
