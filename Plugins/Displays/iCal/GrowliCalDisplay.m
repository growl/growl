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
#import "GrowlApplicationNotification.h"
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

- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	GrowliCalWindowController *controller = [[theBridge windowControllers] objectAtIndex:0U];
	GrowlApplicationNotification *note = [theBridge notification];
	NSDictionary *noteDict = [note dictionaryRepresentation];

	[controller setNotifyingApplicationName:[note applicationName]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];

}
@end
