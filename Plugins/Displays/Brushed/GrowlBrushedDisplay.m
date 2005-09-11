//
//  GrowlBrushedDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlBrushedDisplay.h"
#import "GrowlBrushedWindowController.h"
#import "GrowlBrushedPrefsController.h"
#import "GrowlBrushedDefines.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "NSDictionaryAdditions.h"

static unsigned brushedDepth = 0U;

static void brushedGone(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
#pragma unused(center,observer,name,object)
	CFNumberRef depth = CFDictionaryGetValue(userInfo, CFSTR("Depth"));
	if (depth) {
		unsigned notifiedDepth;
		CFNumberGetValue(depth, kCFNumberIntType, &notifiedDepth);
		//NSLog(@"Received notification of departure with depth %u, my depth is %u\n", notifiedDepth, brushedDepth);
		if (brushedDepth > notifiedDepth)
			brushedDepth = notifiedDepth;
		//NSLog(@"My depth is now %u\n", brushedDepth);
	}
}

@implementation GrowlBrushedDisplay

- (id) init {
	if ((self = [super init])) {
		CFNotificationCenterAddObserver(CFNotificationCenterGetLocalCenter(),
										/*observer*/ NULL,
										brushedGone,
										CFSTR("BrushedGone"),
										/*object*/ NULL,
										CFNotificationSuspensionBehaviorCoalesce);
	}
	return self;
}

- (void) dealloc {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(),
									   /*observer*/ NULL,
									   CFSTR("BrushedGone"),
									   /*object*/ NULL);
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBrushedPrefsController alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Brushed"]];
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	GrowlBrushedWindowController *controller = [[GrowlBrushedWindowController alloc]
		initWithDictionary:noteDict
					 depth:brushedDepth];

	[controller setNotifyingApplicationName:[noteDict objectForKey:GROWL_APP_NAME]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:[noteDict boolForKey:GROWL_SCREENSHOT_MODE]];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];

	// update the depth for the next notification with the depth given by this new one
	// which will take into account the new notification's height
	brushedDepth = [controller depth] + GrowlBrushedPadding;
	[controller startFadeIn];
	[controller release];
}
@end
