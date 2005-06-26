//
//  GrowlWebKitController.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWebKitController.h"
#import "GrowlWebKitWindowController.h"
#import "GrowlWebKitPrefsController.h"
#import "GrowlDefines.h"
#import "NSDictionaryAdditions.h"

@implementation GrowlWebKitController

#pragma mark -
- (id) initWithStyle:(NSString *)styleName {
	if ((self = [super init])) {
		style = [styleName retain];
	}
	return self;
}

- (void) dealloc {
	[style          release];
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane) {
		// load GrowlWebKitPrefsController dynamically so that GHA does not
		// have to link against it and all of its dependencies
		Class prefsController = NSClassFromString(@"GrowlWebKitPrefsController");
		preferencePane = [[prefsController alloc] initWithStyle:style];
	}
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	// load GrowlWebKitWindowController dynamically so that the prefpane does not
	// have to link against it and all of its dependencies
	Class webKitWindowController = NSClassFromString(@"GrowlWebKitWindowController");
	GrowlWebKitWindowController *controller = [[webKitWindowController alloc]
		initWithDictionary:noteDict
					 style:style];
	[controller setTarget:self];
	[controller setNotifyingApplicationName:[noteDict objectForKey:GROWL_APP_NAME]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];
	[controller setScreenshotModeEnabled:[noteDict boolForKey:GROWL_SCREENSHOT_MODE]];
	[controller release];
}
@end
