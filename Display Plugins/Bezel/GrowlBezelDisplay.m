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
		bundle = [[NSBundle bundleForClass:[GrowlBezelPrefs class]] retain];
		preferencePane = [[GrowlBezelPrefs alloc] initWithBundle:bundle];
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[bundle         release];
	[super dealloc];
}

- (void) loadPlugin {
	notificationQueue = [[NSMutableArray alloc] init];
}

- (void) unloadPlugin {
	[notificationQueue release];
}

- (NSDictionary *) pluginInfo {
	return [bundle infoDictionary];
}

- (NSPreferencePane *) preferencePane {
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlBezelWindowController *nuBezel = [GrowlBezelWindowController bezelWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];

	[nuBezel setDelegate:self];
	[nuBezel setTarget:self];
	[nuBezel setAction:@selector(_bezelClicked:)];
	[nuBezel setAppName:[noteDict objectForKey:GROWL_APP_NAME]];
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
	GrowlBezelWindowController *olBezel;
	[notificationQueue removeObjectAtIndex:0U];
	if ([notificationQueue count] > 0U) {
		olBezel = [notificationQueue objectAtIndex:0U];
		[olBezel setFlipIn:YES];
		[olBezel startFadeIn];
	}
}

- (void) _bezelClicked:(GrowlBezelWindowController *)bezel {
	id clickContext;

	if ((clickContext = [bezel clickContext])) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:[bezel appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[bezel setClickContext:nil];
	}
}

@end
