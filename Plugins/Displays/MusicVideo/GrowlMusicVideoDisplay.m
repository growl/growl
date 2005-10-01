//
//  GrowlMusicVideoDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlMusicVideoDisplay.h"
#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoPrefs.h"
#import "GrowlDefinesInternal.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlMusicVideoDisplay

- (id) init {
	if ((self = [super init])) {
		notificationQueue = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[notificationQueue release];
	[preferencePane    release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.MusicVideo"]];
	return preferencePane;
}

#pragma mark -

- (void) displayNotification:(GrowlApplicationNotification *)notification {
	NSDictionary *noteDict = [notification dictionaryRepresentation];
	NSString *identifier = [noteDict objectForKey:GROWL_NOTIFICATION_IDENTIFIER];
	unsigned count = [notificationQueue count];

	if (count > 0U) {
		GrowlMusicVideoWindowController *aNotification;
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		unsigned theIndex = 0U;

		while ((aNotification = [enumerator nextObject])) {
			if ([[aNotification identifier] isEqualToString:identifier]) {
				if (![aNotification isFadingOut]) {
					// coalescing
					[aNotification setPriority:getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY)];
					[aNotification setTitle:getObjectForKey(noteDict, GROWL_NOTIFICATION_TITLE)];
					[aNotification setText:getObjectForKey(noteDict, GROWL_NOTIFICATION_DESCRIPTION)];
					[aNotification setIcon:getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON)];
					[aNotification setNotifyingApplicationName:getObjectForKey(noteDict, GROWL_APP_NAME)];
					[aNotification setNotifyingApplicationProcessIdentifier:getObjectForKey(noteDict, GROWL_APP_PID)];
					[aNotification setClickContext:getObjectForKey(noteDict, GROWL_NOTIFICATION_CLICK_CONTEXT)];
					[aNotification setClickHandlerEnabled:getObjectForKey(noteDict, @"ClickHandlerEnabled")];
					[aNotification setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
					if (theIndex == 0U)
						[aNotification startDisplay];
					return;
				}
				break;
			}
			++theIndex;
		}
	}

	GrowlMusicVideoWindowController *nuMusicVideo = [[GrowlMusicVideoWindowController alloc]
		initWithTitle:getObjectForKey(noteDict, GROWL_NOTIFICATION_TITLE)
				 text:getObjectForKey(noteDict, GROWL_NOTIFICATION_DESCRIPTION)
				 icon:getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON)
			 priority:getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY)
		   identifier:identifier];
	[nuMusicVideo setDelegate:self];
	[nuMusicVideo setTarget:self];
	[nuMusicVideo setNotifyingApplicationName:getObjectForKey(noteDict, GROWL_APP_NAME)];
	[nuMusicVideo setNotifyingApplicationProcessIdentifier:getObjectForKey(noteDict, GROWL_APP_PID)];
	[nuMusicVideo setClickContext:getObjectForKey(noteDict, GROWL_NOTIFICATION_CLICK_CONTEXT)];
	[nuMusicVideo setClickHandlerEnabled:getObjectForKey(noteDict, @"ClickHandlerEnabled")];
	[nuMusicVideo setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];

	if (count > 0U) {
		GrowlMusicVideoWindowController *aNotification;
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		unsigned theIndex = 0U;

		while ((aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuMusicVideo priority]) {
				[notificationQueue insertObject:nuMusicVideo atIndex:theIndex];
				if (theIndex == 0U) {
					[aNotification stopFadeOut];
					[nuMusicVideo startDisplay];
				}
				break;
			}
			++theIndex;
		}

		if (theIndex == count)
			[notificationQueue addObject:nuMusicVideo];
	} else {
		[notificationQueue addObject:nuMusicVideo];
		[nuMusicVideo startDisplay];
	}
	[nuMusicVideo release];
}

- (void) displayWindowControllerWillFadeOut:(NSNotification *)notification {
#pragma unused(notification)
	if ([notificationQueue count] > 1U)
		[[notificationQueue objectAtIndex:1U] startDisplay];
}

- (void) displayWindowControllerDidFadeOut:(NSNotification *)notification {
#pragma unused(notification)
	[notificationQueue removeObjectAtIndex:0U];
	if ([notificationQueue count] > 0U) {
		GrowlDisplayFadingWindowController *controller = [notificationQueue objectAtIndex:0U];
		if (!([controller isFadingIn] || [controller didFadeIn]))
			[controller startDisplay];
	}
}
@end
