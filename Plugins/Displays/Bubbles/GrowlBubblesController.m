//
//  GrowlBubblesController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlBubblesController.h"
#import "GrowlBubblesWindowController.h"
#import "GrowlBubblesPrefsController.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlBubblesController

#pragma mark -

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBubblesPrefsController alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Bubbles"]];
	return preferencePane;
}

- (void) displayNotification:(GrowlApplicationNotification *)notification {
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	GrowlBubblesWindowController *nuBubble = [[GrowlBubblesWindowController alloc]
		initWithDictionary:noteDict];
	[nuBubble setTarget:self];
	[nuBubble setNotifyingApplicationName:getObjectForKey(noteDict, GROWL_APP_NAME)];
	[nuBubble setNotifyingApplicationProcessIdentifier:getObjectForKey(noteDict, GROWL_APP_PID)];
	[nuBubble setClickContext:getObjectForKey(noteDict, GROWL_NOTIFICATION_CLICK_CONTEXT)];
	[nuBubble setClickHandlerEnabled:getObjectForKey(noteDict, @"ClickHandlerEnabled")];
	[nuBubble setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
	[nuBubble startDisplay];	// retains nuBubble
	[nuBubble release];
}
@end
