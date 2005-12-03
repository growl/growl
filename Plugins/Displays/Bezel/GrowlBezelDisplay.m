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
#import "GrowlApplicationNotification.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlBezelDisplay

- (id) init {
	NSLog(@"%s\n", __FUNCTION__);
	if ((self = [super init])) {
		//notificationQueue = [[NSMutableArray alloc] init];
		windowControllerClass = NSClassFromString(@"GrowlBezelWindowController");
	}
	return self;
}

- (void) dealloc {
	//[notificationQueue release];
	[preferencePane    release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlBezelPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.Growl.Bezel"]];
	return preferencePane;
}

- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	NSLog(@"%s\n", __FUNCTION__);
	GrowlBezelWindowController *controller = [[theBridge windowControllers] objectAtIndex:0U];
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
		GrowlBezelWindowController *aNotification;
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

	GrowlBezelWindowController *nuBezel = [[GrowlBezelWindowController alloc]
		initWithTitle:[notification title]
				 text:[notification description]
				 icon:getObjectForKey(noteDict, GROWL_NOTIFICATION_ICON)
			 priority:getIntegerForKey(noteDict, GROWL_NOTIFICATION_PRIORITY)
		   identifier:identifier];

	[nuBezel setDelegate:self];
	[nuBezel setTarget:self];
	[nuBezel setNotifyingApplicationName:[notification applicationName]];
	[nuBezel setNotifyingApplicationProcessIdentifier:getObjectForKey(noteDict, GROWL_APP_PID)];
	[nuBezel setClickContext:getObjectForKey(noteDict, GROWL_NOTIFICATION_CLICK_CONTEXT)];
	[nuBezel setClickHandlerEnabled:getObjectForKey(noteDict, @"ClickHandlerEnabled")];
	[nuBezel setScreenshotModeEnabled:getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)];

	if (count > 0U) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlBezelWindowController *aNotification;
		unsigned theIndex = 0U;

		while ((aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuBezel priority]) {
				[notificationQueue insertObject: nuBezel atIndex:theIndex];
				if (theIndex == 0U) {
					[aNotification stopFadeOut];
					[nuBezel startDisplay];
				}
				break;
			}
			theIndex++;
		}

		if (theIndex == count)
			[notificationQueue addObject:nuBezel];
	} else {
		[notificationQueue addObject:nuBezel];
		[nuBezel startDisplay];
	}
	[nuBezel release];
}

- (void) displayWindowControllerWillFadeOut:(NSNotification *)notification {
	GrowlBezelWindowController *olBezel;
	if ([notificationQueue count] > 1U) {
		olBezel = (GrowlBezelWindowController *)[notification object];
		[olBezel setFlipOut:YES];
	}
}

- (void) displayWindowControllerDidFadeOut:(NSNotification *)notification {
#pragma unused(notification)
	GrowlBezelWindowController *olBezel;
	[notificationQueue removeObjectAtIndex:0U];
	if ([notificationQueue count] > 0U) {
		olBezel = [notificationQueue objectAtIndex:0U];
		[olBezel setFlipIn:YES];
		[olBezel startDisplay];
	}
}*/
@end
