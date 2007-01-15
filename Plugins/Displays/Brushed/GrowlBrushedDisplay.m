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
#import "GrowlApplicationNotification.h"
#include "CFDictionaryAdditions.h"

static unsigned brushedDepth = 0U;

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

- (BOOL)requiresPositioning {
	return YES;
}

- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	// Note: currently we assume there is only one WC...
	GrowlBrushedWindowController *controller = [[theBridge windowControllers] objectAtIndex:0U];
	GrowlApplicationNotification *note = [theBridge notification];
	NSDictionary *noteDict = [note dictionaryRepresentation];
	[controller setNotifyingApplicationName:[note applicationName]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];
}

@end
