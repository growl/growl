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
	GrowlWebKitWindowController *nuBubble = [GrowlWebKitWindowController
		bubbleWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
				   text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
				   icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			   priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
				 sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[nuBubble setTarget:self];
	[nuBubble setAction:@selector(_bubbleClicked:)];
	[nuBubble setAppName:[noteDict objectForKey:GROWL_APP_NAME]];
	[nuBubble setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[nuBubble setScreenshotModeEnabled:[[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]];

	[nuBubble startFadeIn];
//	NSLog( @"bubble - %@", nuBubble );
}

- (void) _bubbleClicked:(GrowlWebKitWindowController *)bubble {
	id clickContext;

	if ((clickContext = [bubble clickContext])) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
														   object:[bubble appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[bubble setClickContext:nil];
	}
}

@end
