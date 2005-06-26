//
//  GrowlSmokeDisplay.m
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlSmokeDisplay.h"
#import "GrowlSmokeWindowController.h"
#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefinesInternal.h"
#import "NSDictionaryAdditions.h"

static unsigned smokeDepth = 0U;

@implementation GrowlSmokeDisplay

- (id) init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(smokeGone:)
													 name:@"SmokeGone"
												   object:nil];
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

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	GrowlSmokeWindowController *controller = [[GrowlSmokeWindowController alloc]
		initWithDictionary:noteDict
					 depth:smokeDepth];

	[controller setTarget:self];
	[controller setNotifyingApplicationName:[noteDict objectForKey:GROWL_APP_NAME]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];
	[controller setScreenshotModeEnabled:[noteDict boolForKey:GROWL_SCREENSHOT_MODE]];
	[controller setProgress:[noteDict objectForKey:GROWL_NOTIFICATION_PROGRESS]];

	// update the depth for the next notification with the depth given by this new one
	// which will take into account the new notification's height
	smokeDepth = [controller depth] + GrowlSmokePadding;
	[controller startFadeIn];
	[controller release];
}

- (void) smokeGone:(NSNotification *)note {
	unsigned notifiedDepth = [[[note userInfo] objectForKey:@"Depth"] unsignedIntValue];
	//NSLog(@"Received notification of departure with depth %u, my depth is %u\n", notifiedDepth, smokeDepth);
	if (smokeDepth > notifiedDepth)
		smokeDepth = notifiedDepth;
	//NSLog(@"My depth is now %u\n", smokeDepth);
}
@end
