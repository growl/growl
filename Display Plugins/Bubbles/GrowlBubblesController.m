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

@implementation GrowlBubblesController

#pragma mark -

- (id) init {
	if ((self = [super init])) {
		bundle = [[NSBundle bundleForClass:[GrowlBubblesPrefsController class]] retain];
		preferencePane = [[GrowlBubblesPrefsController alloc] initWithBundle:bundle];
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[bundle         release];
	[super dealloc];
}

- (void) loadPlugin {
	//if I had setup procedures I would do them here
}

- (void) unloadPlugin {
	// if I had things to clean up/undo I would do it here,
	// fortunately Bubbles do their job pretty cleanly without touching others.
}

- (NSDictionary *) pluginInfo {
	return [bundle infoDictionary];
}

- (NSPreferencePane *) preferencePane {
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlBubblesWindowController *nuBubble = [GrowlBubblesWindowController bubbleWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
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

- (void) _bubbleClicked:(GrowlBubblesWindowController *)bubble
{
	id clickContext;

	if ( (clickContext = [bubble clickContext]) ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
														   object:[bubble appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[bubble setClickContext:nil];
	}
}

@end
