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
@class NSPreferencePane;

@implementation GrowlBubblesController

#pragma mark Growl Gets Satisfaction

- (id) init {
	if ( (self = [super init] ) ) {
		bubblePrefPane = [[GrowlBubblesPrefsController alloc] initWithBundle:[NSBundle bundleForClass:[GrowlBubblesPrefsController class]]];
	}
	return self;
}

- (void) dealloc {
	[bubblePrefPane release];
	[super dealloc];
}

- (void) loadPlugin {
	//if I had setup procedures I would do them here
}

- (NSString *) author {
	return @"Karl Adam and Timothy Hatcher";
}

- (NSString *) name {
	return @"Bubbles";
}

- (NSString *) userDescription {
	return @"Bubbley Status Notifications";
}

- (NSString *) version {
	return @"1.0a";
}

- (void) unloadPlugin {
	// if I had things to clean up/undo I would do it here,
	// fortunately Bubbles do their job pretty cleanly without touching others.
}

- (NSDictionary *) pluginInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"Bubbles", @"Name",
		@"Karl Adam and Timothy Hatcher", @"Author",
		@"1.0a", @"Version",
		@"Happy Bubbles!", @"Description",
		nil];
}

- (NSPreferencePane *) preferencePane {
	return bubblePrefPane;
}

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlBubblesWindowController *nuBubble = [GrowlBubblesWindowController bubbleWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
																			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
																			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
																			priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
																			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[nuBubble startFadeIn];
//	NSLog( @"bubble - %@", nuBubble );
}

@end
