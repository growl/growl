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

#define B_AUTHOR		@"Jorge Salvador Caffarena"
#define B_NAME			@"Bezel"
#define B_DESCRIPTION	@"Bezel like notifications, with a twist"
#define B_VERSION		@"1.2.0"

@implementation GrowlBezelDisplay

- (id) init {
	if ( (self = [super init] ) ) {
		preferencePane = [[GrowlBezelPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlBezelPrefs class]]];
	}
	return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (void) loadPlugin {
	notificationQueue = [[NSMutableArray alloc] init];
}

- (NSString *) author {
	return B_AUTHOR;
}

- (NSString *) name {
	return B_NAME;
}

- (NSString *) userDescription {
	return B_DESCRIPTION;
}

- (NSString *) version {
	return B_VERSION;
}

- (void) unloadPlugin {
	[notificationQueue release];
}

- (NSDictionary*) pluginInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		B_NAME, @"Name",
		B_AUTHOR, @"Author",
		B_VERSION, @"Version",
		B_DESCRIPTION, @"Description",
		nil];
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

	if ( [notificationQueue count] > 0U ) {
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
	if ( [notificationQueue count] > 1U ) {
		olBezel = (GrowlBezelWindowController *)sender;
		[olBezel setFlipOut:YES];
	}
}

- (void) didFadeOut:(FadingWindowController *)sender {
	GrowlBezelWindowController *olBezel;
	[notificationQueue removeObjectAtIndex:0U];
	if ( [notificationQueue count] > 0U ) {
		olBezel = [notificationQueue objectAtIndex:0U];
		[olBezel setFlipIn:YES];
		[olBezel startFadeIn];
	}
}

- (void) _bezelClicked:(GrowlBezelWindowController *)bezel {
	id clickContext;

	if ( (clickContext = [bezel clickContext]) ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:[bezel appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[bezel setClickContext:nil];
	}
}

@end
