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

@implementation GrowlMusicVideoDisplay

- (id) init {
	if ((self = [super init])) {
		notificationQueue = [[NSMutableArray array] retain];
	}
	return self;
}

- (void) dealloc {
	[notificationQueue release];
	[preferencePane    release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane) {
		preferencePane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlMusicVideoPrefs class]]];
	}
	return preferencePane;
}

#pragma mark -

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlMusicVideoWindowController *nuMusicVideo = [GrowlMusicVideoWindowController
		musicVideoWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
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

	if ([notificationQueue count] > 0U) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlMusicVideoWindowController *aNotification;
		BOOL		inserted = NO;
		unsigned	theIndex = 0U;
		
		while (!inserted && (aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuMusicVideo priority]) {
				[notificationQueue insertObject: nuMusicVideo atIndex:theIndex];
				if (theIndex == 0U) {
					[aNotification stopFadeOut];
					[nuMusicVideo startFadeIn];
				}
				inserted = YES;
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

- (void) willFadeOut:(FadingWindowController *)sender {
	if ([notificationQueue count] > 1U) {
		[[notificationQueue objectAtIndex:1U] startFadeIn];
	}
}

- (void) didFadeOut:(FadingWindowController *)sender {
	[notificationQueue removeObjectAtIndex:0U];
}

- (void) _musicVideoClicked:(GrowlMusicVideoWindowController *)musicVideo {
	id clickContext;

	if ((clickContext = [musicVideo clickContext])) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:[musicVideo appName]
														  userInfo:clickContext];
		
		//Avoid duplicate click messages by immediately clearing the clickContext
		[musicVideo setClickContext:nil];
	}
}

@end
