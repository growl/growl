//
//  GrowlMusicVideoDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlMusicVideoDisplay.h"
#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoPrefs.h"
#import <GrowlDefinesInternal.h>

#define B_AUTHOR @"Jorge Salvador Caffarena"
#define B_NAME @"Music Video"
#define B_DESCRIPTION @"Music Video notifications, for your tunes"
#define B_VERSION @"0.1.0"

@class NSPreferencePane;

@implementation GrowlMusicVideoDisplay

- (id) init {
	if ( (self = [super init] ) ) {
		musicVideoPrefPane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlMusicVideoPrefs class]]];
	}
	return self;
}

- (void) dealloc {
	[musicVideoPrefPane release];
	[super dealloc];
}

- (void) loadPlugin {
	notificationQueue = [[NSMutableArray array] retain];
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
	return musicVideoPrefPane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlMusicVideoWindowController *nuMusicVideo = [GrowlMusicVideoWindowController musicVideoWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	
	[nuMusicVideo setDelegate:self];
	[nuMusicVideo setTarget:self];
	[nuMusicVideo setAction:@selector(_musicVideoClicked:)];
	[nuMusicVideo setAppName:[noteDict objectForKey:GROWL_APP_NAME]];
	[nuMusicVideo setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];	
	[nuMusicVideo setScreenshotModeEnabled:[[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]];
	
	if ( [notificationQueue count] > 0U ) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlMusicVideoWindowController *aNotification;
		BOOL		inserted = FALSE;
		unsigned	theIndex = 0U;
		
		while (!inserted && (aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuMusicVideo priority]) {
				[notificationQueue insertObject: nuMusicVideo atIndex:theIndex];
				if (theIndex == 0U) {
					[aNotification stopFadeOut];
					[nuMusicVideo startFadeIn];
				}
				inserted = TRUE;
			}
			theIndex++;
		}
		
		if (!inserted) {
			[notificationQueue addObject:nuMusicVideo];
		}
	} else {
		[notificationQueue addObject:nuMusicVideo];
		[nuMusicVideo startFadeIn];
	}
}

- (void) didFadeOut:(FadingWindowController *)sender {
	GrowlMusicVideoWindowController *olMusicVideo;
	[notificationQueue removeObjectAtIndex:0U];
	if ( [notificationQueue count] > 0U ) {
		olMusicVideo = [notificationQueue objectAtIndex:0U];
		[olMusicVideo startFadeIn];
	}
}

- (void) _musicVideoClicked:(GrowlMusicVideoWindowController *)musicVideo
{
	id clickContext;
	
	if ( (clickContext = [musicVideo clickContext]) ) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:[musicVideo appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[musicVideo setClickContext:nil];
	}
}

@end
