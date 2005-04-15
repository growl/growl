//
//  GrowlWebKitController.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlWebKitController.h"
#import "GrowlWebKitWindowController.h"
#import "GrowlWebKitPrefsController.h"

@implementation GrowlWebKitController

#pragma mark -

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane) {
		preferencePane = [[GrowlWebKitPrefsController alloc] initWithBundle:[NSBundle bundleForClass:[GrowlWebKitPrefsController class]]];
	}
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlWebKitWindowController *controller = [GrowlWebKitWindowController
		notifyWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
				   text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
				   icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			   priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
				 sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[controller setTarget:self];
	[controller setAction:@selector(_notificationClicked:)];
	[controller setAppName:[noteDict objectForKey:GROWL_APP_NAME]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:[[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]];

	[controller startFadeIn];
}

- (void) _notificationClicked:(GrowlWebKitWindowController *)windowController {
	id clickContext;

	if ((clickContext = [windowController clickContext])) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
														   object:[windowController appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[windowController setClickContext:nil];
	}
}

@end
