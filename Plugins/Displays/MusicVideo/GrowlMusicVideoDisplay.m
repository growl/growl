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
#import "NSDictionaryAdditions.h"

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

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
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
					[aNotification setPriority:[noteDict integerForKey:GROWL_NOTIFICATION_PRIORITY]];
					[aNotification setTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE]];
					[aNotification setText:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]];
					[aNotification setIcon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]];
					[aNotification setNotifyingApplicationName:[noteDict objectForKey:GROWL_APP_NAME]];
					[aNotification setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
					[aNotification setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
					[aNotification setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];
					[aNotification setScreenshotModeEnabled:[noteDict boolForKey:GROWL_SCREENSHOT_MODE]];
					if (theIndex == 0U)
						[aNotification startFadeIn];
					return;
				}
				break;
			}
			++theIndex;
		}
	}

	GrowlMusicVideoWindowController *nuMusicVideo = [[GrowlMusicVideoWindowController alloc]
		initWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE]
				 text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]
				 icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			 priority:[noteDict integerForKey:GROWL_NOTIFICATION_PRIORITY]
		   identifier:identifier];
	[nuMusicVideo setDelegate:self];
	[nuMusicVideo setTarget:self];
	[nuMusicVideo setNotifyingApplicationName:[noteDict objectForKey:GROWL_APP_NAME]];
	[nuMusicVideo setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[nuMusicVideo setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[nuMusicVideo setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];
	[nuMusicVideo setScreenshotModeEnabled:[noteDict boolForKey:GROWL_SCREENSHOT_MODE]];

	if (count > 0U) {
		GrowlMusicVideoWindowController *aNotification;
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		unsigned theIndex = 0U;

		while ((aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuMusicVideo priority]) {
				[notificationQueue insertObject:nuMusicVideo atIndex:theIndex];
				if (theIndex == 0U) {
					[aNotification stopFadeOut];
					[nuMusicVideo startFadeIn];
				}
				break;
			}
			++theIndex;
		}

		if (theIndex == count)
			[notificationQueue addObject:nuMusicVideo];
	} else {
		[notificationQueue addObject:nuMusicVideo];
		[nuMusicVideo startFadeIn];
	}
	[nuMusicVideo release];
}

- (void) displayWindowControllerWillFadeOut:(GrowlDisplayFadingWindowController *)sender {
#pragma unused(sender)
	if ([notificationQueue count] > 1U)
		[[notificationQueue objectAtIndex:1U] startFadeIn];
}

- (void) displayWindowControllerDidFadeOut:(GrowlDisplayFadingWindowController *)sender {
#pragma unused(sender)
	[notificationQueue removeObjectAtIndex:0U];
	if ([notificationQueue count] > 0U) {
		GrowlDisplayFadingWindowController *controller = [notificationQueue objectAtIndex:0U];
		if (![controller isFadingIn])
			[controller startFadeIn];
	}
}
@end
