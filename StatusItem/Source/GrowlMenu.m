//
//  GrowlMenu.m
//
//
//  Created by rudy on Sun Apr 17 2005.
//  Copyright (c) 2005 The Growl Project. All rights reserved.
//

#import "GrowlMenu.h"
#import "GrowlPreferencesController.h"
#import "GrowlPathUtilities.h"
//#import "GrowlPluginController.h"
#include <unistd.h>

#define kRestartGrowl                NSLocalizedString(@"Restart Growl", @"")
#define kRestartGrowlTooltip         NSLocalizedString(@"Restart Growl", @"")
#define kStartGrowl                  NSLocalizedString(@"Start Growl", @"")
#define kStartGrowlTooltip           NSLocalizedString(@"Start Growl", @"")
#define kStopGrowl                   NSLocalizedString(@"Stop Growl", @"")
#define kStopGrowlTooltip            NSLocalizedString(@"Stop Growl", @"")
#define kDefaultDisplay              NSLocalizedString(@"Default display", @"")
#define kDefaultDisplayTooltip       NSLocalizedString(@"Set the default display style", @"")
#define kOpenGrowlPreferences        NSLocalizedString(@"Open Growl Preferences...", @"")
#define kOpenGrowlPreferencesTooltip NSLocalizedString(@"Open the Growl preference pane", @"")
#define kSquelchMode                 NSLocalizedString(@"Log only, don't display", @"")
#define kSquelchModeTooltip          NSLocalizedString(@"Don't show notifications, but still log them", @"")
#define kStopGrowlMenu               NSLocalizedString(@"Hide Status Item", @"")
#define kStopGrowlMenuTooltip        NSLocalizedString(@"Hide this status item", @"")
#define kStickyWhenAwayMenu			 NSLocalizedString(@"Sticky Notifications", @"")
#define kStickyWhenAwayMenuTooltip   NSLocalizedString(@"Toggles the sticky notification state", @"")
#define kDefaultDisplayChanged       NSLocalizedString(@"Default display changed to %@", @"")

int main(void) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];

	GrowlMenu *menu = [[[GrowlMenu alloc] init] autorelease];
	[NSApp setDelegate:menu];
	[NSApp run];

	// dead code
	[pool release];

	return EXIT_SUCCESS;
}

@implementation GrowlMenu

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
#pragma unused(aNotification)
	pid = getpid();
	preferences = [GrowlPreferencesController sharedController];

	NSMenu *m = [self createMenu];

	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];

	NSBundle *bundle = [NSBundle mainBundle];

	clawImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growlmenu" ofType:@"png"]];
	clawHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growlmenu-alt" ofType:@"png"]];
	squelchImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"squelch" ofType:@"png"]];

	[self setImage];

	[statusItem setMenu:m]; // retains m
	[statusItem setToolTip:@"Growl"];
	[statusItem setHighlightMode:YES];

	[self setGrowlMenuEnabled:YES];

	NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
	[nc addObserver:self
		   selector:@selector(shutdown:)
			   name:@"GrowlMenuShutdown"
			 object:nil];
	[nc addObserver:self
		   selector:@selector(reloadPrefs:)
			   name:GrowlPreferencesChanged
			 object:nil];

	[GrowlApplicationBridge setGrowlDelegate:self];
}

#pragma mark Growl delegate methods

- (NSString *) applicationNameForGrowl {
	return @"GrowlMenu";
}

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *notifications = [NSArray arrayWithObject:@"Display changed"];
	NSDictionary *registrationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
											notifications, GROWL_NOTIFICATIONS_ALL,
											notifications, GROWL_NOTIFICATIONS_DEFAULT,
											[NSDictionary dictionaryWithObject:NSLocalizedString(@"Display changed", "Notification posted by GrowlMenu when the display style changes")
																		forKey:@"Display changed"], GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
											nil];

	return registrationDictionary;
}

#pragma mark -

- (void) setGrowlMenuEnabled:(BOOL)state {
	NSString *growlMenuPath = [[NSBundle mainBundle] bundlePath];
	[preferences setStartAtLogin:growlMenuPath enabled:state];
	[preferences setBool:state forKey:GrowlMenuExtraKey];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification {
#pragma unused(aNotification)
	[self release];
}

- (void) dealloc {
//	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
//	[statusItem            release];
	[clawImage             release];
	[clawHighlightImage    release];
	[squelchImage          release];
	[super dealloc];
}

- (void) shutdown:(id)sender {
	[self setGrowlMenuEnabled:NO];
	[NSApp terminate:sender];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSNumber *pidValue = [[notification userInfo] objectForKey:@"pid"];
	if (!pidValue || [pidValue intValue] != pid)
		[self setImage];
	[pool release];
}

- (void) openGrowlPreferences:(id)sender {
#pragma unused(sender)
	NSString *prefPane = [[GrowlPathUtilities growlPrefPaneBundle] bundlePath];
	[[NSWorkspace sharedWorkspace] openFile:prefPane];
}

- (void) defaultDisplay:(id)sender {
	NSString *pluginName = [sender title];
	[preferences setDefaultDisplayPluginName:pluginName];

	CFStringRef description = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, (CFStringRef)kDefaultDisplayChanged, pluginName);
	const NSString *keys[5] = { GROWL_APP_NAME, GROWL_NOTIFICATION_NAME, GROWL_NOTIFICATION_TITLE, GROWL_NOTIFICATION_DESCRIPTION, GROWL_DISPLAY_PLUGIN };
	const CFStringRef values[5] = { CFSTR("GrowlMenu"), CFSTR("Display changed"), CFSTR("Display changed"), description, (CFStringRef)pluginName };
	CFDictionaryRef feedbackDictionary = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 5, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(description);
	[GrowlApplicationBridge notifyWithDictionary:(NSDictionary *)feedbackDictionary];
	CFRelease(feedbackDictionary);
}

- (void) stopGrowl:(id)sender {
#pragma unused(sender)
	//If Growl is running, we should stop it.
	if ([preferences isGrowlRunning])
		[preferences setGrowlRunning:NO noMatterWhat:NO];
}

- (void) startGrowl:(id)sender {
#pragma unused(sender)
	if (![preferences isGrowlRunning]) {
		//If Growl isn't running, we should start it.
		[preferences setGrowlRunning:YES noMatterWhat:NO];
	} else {
		//If Growl is running, we should restart it.
		//Actually, we should HUP it, but we don't.
		[preferences setGrowlRunning:NO noMatterWhat:NO];
		[preferences setGrowlRunning:YES noMatterWhat:YES];
	}
}

- (void) squelchMode:(id)sender {
#pragma unused(sender)
	BOOL squelchMode = ![preferences squelchMode];
	[preferences setSquelchMode:squelchMode];
	[self setImage];
}

- (void) stickyWhenIdle:(id)sender {
#pragma unused(sender)
	BOOL idleModeState = ![preferences stickyWhenAway];
	[preferences setStickyWhenAway:idleModeState];
}

- (void) setImage {
	if ([preferences squelchMode]) {
		[statusItem setImage:squelchImage];
	} else {
		[statusItem setImage:clawImage];
		[statusItem setAlternateImage:clawHighlightImage];
	}
}

- (NSMenu *) createMenu {
	NSZone *menuZone = [NSMenu menuZone];
	NSMenu *m = [[NSMenu allocWithZone:menuZone] init];

	NSMenuItem *tempMenuItem;

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStartGrowl action:@selector(startGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:1];

	if ([preferences isGrowlRunning]) {
		[tempMenuItem setTitle:kRestartGrowl];
		[tempMenuItem setToolTip:kRestartGrowlTooltip];
	} else {
		[tempMenuItem setToolTip:kStartGrowlTooltip];
	}

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowl action:@selector(stopGrowl:) keyEquivalent:@""];
	[tempMenuItem setTag:2];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kStopGrowlTooltip];

	[m addItem:[NSMenuItem separatorItem]];

	/*
	 //Squelch mode is "log-only" mode... but logging was removed from Growl 1.1.
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kSquelchMode action:@selector(squelchMode:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:4];
	[tempMenuItem setToolTip:kSquelchModeTooltip];
	 */
	
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStickyWhenAwayMenu action:@selector(stickyWhenIdle:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:6];
	[tempMenuItem setToolTip:kStickyWhenAwayMenuTooltip];

	/*NSMenu *displays = [[NSMenu allocWithZone:menuZone] init];
	NSString *name;
	NSEnumerator *displayEnumerator = [[[GrowlPluginController sharedController] displayPlugins] objectEnumerator];
	while ((name = [displayEnumerator nextObject])) {
		tempMenuItem = (NSMenuItem *)[displays addItemWithTitle:name action:@selector(defaultDisplay:) keyEquivalent:@""];
		[tempMenuItem setTarget:self];
		[tempMenuItem setTag:3];
	}
	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kDefaultDisplay action:NULL keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setSubmenu:displays];
	[displays release];*/
	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowlMenu action:@selector(shutdown:) keyEquivalent:@""];
	[tempMenuItem setTag:5];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kStopGrowlMenuTooltip];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kOpenGrowlPreferences action:@selector(openGrowlPreferences:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kOpenGrowlPreferencesTooltip];

	return [m autorelease];
}

- (BOOL) validateMenuItem:(NSMenuItem *)item {
	switch ([item tag]) {
		case 1:
			if ([preferences isGrowlRunning]) {
				[item setTitle:kRestartGrowl];
				[item setToolTip:kRestartGrowlTooltip];
			} else {
				[item setTitle:kStartGrowl];
				[item setToolTip:kStartGrowlTooltip];
			}
			break;
		case 2:
			return [preferences isGrowlRunning];
		case 3:
			[item setState:[[item title] isEqualToString:[preferences defaultDisplayPluginName]]];
			break;
		case 4:
			[item setState:[preferences squelchMode]];
			break;
		case 6:
			[item setState:[preferences stickyWhenAway]];
			break;
	}
	return YES;
}

@end
