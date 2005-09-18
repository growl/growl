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
#import "CFDictionaryAdditions.h"

static unsigned smokeDepth = 0U;

static void smokeGone(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
#pragma unused(center,observer,name,object)
	CFNumberRef depth = CFDictionaryGetValue(userInfo, CFSTR("Depth"));
	if (depth) {
		unsigned notifiedDepth;
		CFNumberGetValue(depth, kCFNumberIntType, &notifiedDepth);
		//NSLog(@"Received notification of departure with depth %u, my depth is %u\n", notifiedDepth, smokeDepth);
		if (smokeDepth > notifiedDepth)
			smokeDepth = notifiedDepth;
		//NSLog(@"My depth is now %u\n", smokeDepth);
	}
}

@implementation GrowlSmokeDisplay

- (id) init {
	if ((self = [super init])) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
										/*observer*/ NULL,
										smokeGone,
										CFSTR("SmokeGone"),
										/*object*/ NULL,
										CFNotificationSuspensionBehaviorCoalesce);
	}
	return self;
}

- (void) dealloc {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(),
									   /*observer*/ NULL,
									   CFSTR("SmokeGone"),
									   /*object*/ NULL);
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
	[controller setNotifyingApplicationName:getObjectForKey(noteDict, GROWL_APP_NAME)];
	[controller setNotifyingApplicationProcessIdentifier:getObjectForKey(noteDict, GROWL_APP_PID)];
	[controller setClickContext:getObjectForKey(noteDict, GROWL_NOTIFICATION_CLICK_CONTEXT)];
	[controller setClickHandlerEnabled:getObjectForKey(noteDict, @"ClickHandlerEnabled")];
	[controller setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
	[controller setProgress:getObjectForKey(noteDict, GROWL_NOTIFICATION_PROGRESS)];

	// update the depth for the next notification with the depth given by this new one
	// which will take into account the new notification's height
	smokeDepth = [controller depth] + GrowlSmokePadding;
	[controller startDisplay];
	[controller release];
}
@end
