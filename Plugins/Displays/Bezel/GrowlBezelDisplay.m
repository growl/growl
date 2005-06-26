//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlBezelDisplay.h"
#import "GrowlBezelWindowController.h"
#import "GrowlBezelPrefs.h"
#import "GrowlDefinesInternal.h"
#import "NSDictionaryAdditions.h"

@implementation GrowlBezelDisplay

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
		preferencePane = [[GrowlBezelPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Bezel"]];
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	NSString *identifier = [noteDict objectForKey:GROWL_NOTIFICATION_IDENTIFIER];
	unsigned count = [notificationQueue count];

	if (count > 0U) {
		GrowlBezelWindowController *aNotification;
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

	GrowlBezelWindowController *nuBezel = [[GrowlBezelWindowController alloc]
		initWithTitle:[noteDict objectForKey: GROWL_NOTIFICATION_TITLE]
				 text:[noteDict objectForKey: GROWL_NOTIFICATION_DESCRIPTION]
				 icon:[noteDict objectForKey: GROWL_NOTIFICATION_ICON]
			 priority:[noteDict integerForKey:GROWL_NOTIFICATION_PRIORITY]
		   identifier:identifier];

	[nuBezel setDelegate:self];
	[nuBezel setTarget:self];
	[nuBezel setNotifyingApplicationName:[noteDict objectForKey:GROWL_APP_NAME]];
	[nuBezel setNotifyingApplicationProcessIdentifier:[noteDict objectForKey:GROWL_APP_PID]];
	[nuBezel setClickContext:[noteDict objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT]];
	[nuBezel setClickHandlerEnabled:[noteDict objectForKey:@"ClickHandlerEnabled"]];
	[nuBezel setScreenshotModeEnabled:[noteDict boolForKey:GROWL_SCREENSHOT_MODE]];

	if (count > 0U) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlBezelWindowController *aNotification;
		unsigned theIndex = 0U;

		while ((aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuBezel priority]) {
				[notificationQueue insertObject: nuBezel atIndex:theIndex];
				if (theIndex == 0U) {
					[aNotification stopFadeOut];
					[nuBezel startFadeIn];
				}
				break;
			}
			theIndex++;
		}

		if (theIndex == count)
			[notificationQueue addObject:nuBezel];
	} else {
		[notificationQueue addObject:nuBezel];
		[nuBezel startFadeIn];
	}
	[nuBezel release];
}

- (void) displayWindowControllerWillFadeOut:(GrowlDisplayFadingWindowController *)sender {
	GrowlBezelWindowController *olBezel;
	if ([notificationQueue count] > 1U) {
		olBezel = (GrowlBezelWindowController *)sender;
		[olBezel setFlipOut:YES];
	}
}

- (void) displayWindowControllerDidFadeOut:(GrowlDisplayFadingWindowController *)sender {
#pragma unused(sender)
	GrowlBezelWindowController *olBezel;
	[notificationQueue removeObjectAtIndex:0U];
	if ([notificationQueue count] > 0U) {
		olBezel = [notificationQueue objectAtIndex:0U];
		[olBezel setFlipIn:YES];
		[olBezel startFadeIn];
	}
}
@end
