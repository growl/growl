//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlBezelDisplay.h"
#import "GrowlBezelWindowController.h"
#import "GrowlBezelPrefs.h"
#import <GrowlDefinesInternal.h>

@implementation GrowlBezelDisplay

- (id) init {
	if ((self = [super init])) {
		notificationQueue = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[notificationQueue   release];
	[preferencePane      release];
	[clickHandlerEnabled release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane) {
		preferencePane = [[GrowlBezelPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlBezelPrefs class]]];
	}
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	clickHandlerEnabled = [[noteDict objectForKey:@"ClickHandlerEnabled"] retain];
	GrowlBezelWindowController *nuBezel = [GrowlBezelWindowController bezelWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE]
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];

	[nuBezel setDelegate:self];
	[nuBezel setTarget:self];
	[nuBezel setAction:@selector(_bezelClicked:)];
	[nuBezel setAppName:[noteDict objectForKey:GROWL_APP_NAME]];
	[nuBezel setAppPid:[noteDict objectForKey:GROWL_APP_PID]];
	[nuBezel setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[nuBezel setScreenshotModeEnabled:[[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]];

	if ([notificationQueue count] > 0U) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlBezelWindowController *aNotification;
		BOOL	inserted = NO;
		int		theIndex = 0;

		while (!inserted && (aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuBezel priority]) {
				[notificationQueue insertObject: nuBezel atIndex:theIndex];
				if (theIndex == 0) {
					[aNotification stopFadeOut];
					[nuBezel startFadeIn];
				}
				inserted = YES;
			}
			theIndex++;
		}

		if (!inserted) {
			[notificationQueue addObject:nuBezel];
		}
	} else {
		[notificationQueue addObject:nuBezel];
		[nuBezel startFadeIn];
	}
}

- (void) willFadeOut:(FadingWindowController *)sender {
	GrowlBezelWindowController *olBezel;
	if ([notificationQueue count] > 1U) {
		olBezel = (GrowlBezelWindowController *)sender;
		[olBezel setFlipOut:YES];
	}
}

- (void) didFadeOut:(FadingWindowController *)sender {
#pragma unused(sender)
	GrowlBezelWindowController *olBezel;
	[notificationQueue removeObjectAtIndex:0U];
	if ([notificationQueue count] > 0U) {
		olBezel = [notificationQueue objectAtIndex:0U];
		[olBezel setFlipIn:YES];
		[olBezel startFadeIn];
	}
}

- (void) _bezelClicked:(GrowlBezelWindowController *)controller {
	id clickContext;

	if ((clickContext = [controller clickContext])) {
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			clickHandlerEnabled, @"ClickHandlerEnabled",
			clickContext,        GROWL_KEY_CLICKED_CONTEXT,
			[controller appPid], GROWL_APP_PID,
			nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:[controller appName]
														  userInfo:userInfo];
		[userInfo release];

		//Avoid duplicate click messages by immediately clearing the clickContext
		[controller setClickContext:nil];
	}
}

@end
