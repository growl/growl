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
#import "GrowlApplicationNotification.h"
#import "GrowlNotificationDisplayBridge.h"

#include "CFDictionaryAdditions.h"

@implementation GrowlMusicVideoDisplay

- (id) init {
	NSLog(@"%s\n", __FUNCTION__);
	if ((self = [super init])) {
		windowControllerClass = NSClassFromString(@"GrowlMusicVideoWindowController");
		//notificationQueue = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	//[notificationQueue release];
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.MusicVideo"]];
	return preferencePane;
}

#pragma mark -
- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	NSLog(@"%s\n", __FUNCTION__);
	GrowlMusicVideoWindowController *controller = [[theBridge windowControllers] objectAtIndex:0U];
	GrowlApplicationNotification *note = [theBridge notification];
	NSDictionary *noteDict = [note dictionaryRepresentation];

	[controller setNotifyingApplicationName:[note applicationName]];
	[controller setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[controller setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[controller setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];
	[controller setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];

}

/*- (void) displayNotification:(GrowlApplicationNotification *)notification {
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
					[aNotification setTitle:[notification title]];
					[aNotification setText:[notification description]];
					[aNotification setIcon:getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON)];
					[aNotification setNotifyingApplicationName:[notification applicationName]];
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
		initWithTitle:[notification title]
				 text:[notification notificationDescription]
				 icon:getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON)
			 priority:getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY)
		   identifier:identifier];
	[nuMusicVideo setDelegate:self];
	[nuMusicVideo setTarget:self];
	[nuMusicVideo setNotifyingApplicationName:[notification applicationName]];
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
}*/
@end
