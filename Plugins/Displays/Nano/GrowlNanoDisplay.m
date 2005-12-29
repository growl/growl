//
//  GrowlNanoDisplay.m
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005, The Growl Project. All rights reserved.
//

#import "GrowlNanoDisplay.h"
#import "GrowlNanoWindowController.h"
#import "GrowlNanoPrefs.h"
#import "GrowlDefinesInternal.h"
#import "GrowlApplicationNotification.h"
#import "GrowlNotificationDisplayBridge.h"

#include "CFDictionaryAdditions.h"

@implementation GrowlNanoDisplay

- (id) init {
	NSLog(@"%s\n", __FUNCTION__);
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

#pragma mark -
- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	NSLog(@"%s\n", __FUNCTION__);
	GrowlNanoWindowController *controller = [[theBridge windowControllers] objectAtIndex:0U];
	GrowlApplicationNotification *note = [theBridge notification];
	NSDictionary *noteDict = [note dictionaryRepresentation];

	[controller setNotifyingApplicationName:[note applicationName]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];

}

@end
