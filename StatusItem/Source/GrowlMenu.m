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
#import "GrowlPluginController.h"

#define kRestartGrowl                NSLocalizedString(@"Restart Growl", @"")
#define kRestartGrowlTooltip         NSLocalizedString(@"Restart Growl", @"")
#define kStartGrowl                  NSLocalizedString(@"Start Growl", @"")
#define kStartGrowlTooltip           NSLocalizedString(@"Start Growl", @"")
#define kStopGrowl                   NSLocalizedString(@"Stop Growl", @"")
#define kStopGrowlTooltip            NSLocalizedString(@"Stop Growl", @"")
#define kDefaultDisplay              NSLocalizedString(@"Default display", @"")
#define kDefaultDisplayTooltip       NSLocalizedString(@"Set the default display style", @"")
#define kOpenGrowlPreferences        NSLocalizedString(@"Open Growl preferences...", @"")
#define kOpenGrowlPreferencesTooltip NSLocalizedString(@"Open the Growl preference pane", @"")
#define kSquelchMode                 NSLocalizedString(@"Log only, don't display", @"")
#define kSquelchModeTooltip          NSLocalizedString(@"Don't show notifications, but still log them", @"")
#define kStopGrowlMenu               NSLocalizedString(@"Quit GrowlMenu", @"")
#define kStopGrowlMenuTooltip        NSLocalizedString(@"Remove this status item", @"")

int main(void) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApplication sharedApplication];

	GrowlMenu *menu = [[GrowlMenu alloc] init];
	[NSApp setDelegate:menu];
	[NSApp run];

	// dead code
	[pool release];

	return EXIT_SUCCESS;
}

@implementation GrowlMenu

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
#pragma unused(aNotification)
	pid = [[NSProcessInfo processInfo] processIdentifier];
	preferences = [GrowlPreferencesController sharedController];

	NSMenu *m = [self createMenu];

	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];

	NSBundle *bundle = [NSBundle mainBundle];

	clawImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growlmenu" ofType:@"png"]];
	clawHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growlmenu-alt" ofType:@"png"]];
	squelchImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"squelch" ofType:@"png"]];
	squelchHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"squelch-alt" ofType:@"png"]];

	[self setImage];

	[statusItem setMenu:m]; // retains m
	[statusItem setToolTip:@"Growl"];
	[statusItem setHighlightMode:YES];

	[m release];

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
}

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
	[squelchHighlightImage release];
	[super dealloc];
}

- (void) shutdown:(id)sender {
	[self setGrowlMenuEnabled:NO];
	[NSApp terminate:sender];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSNumber *pidValue = [[notification userInfo] objectForKey:@"pid"];
	if (!pidValue || [pidValue intValue] != pid)
		[self setImage];
}

- (void) openGrowlPreferences:(id)sender {
#pragma unused(sender)
	NSString *prefPane = [[GrowlPathUtilities growlPrefPaneBundle] bundlePath];
	[[NSWorkspace sharedWorkspace] openFile:prefPane];
}

- (void) defaultDisplay:(id)sender {
	[preferences setDefaultDisplayPluginName:[sender title]];
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

- (void) setImage {
	if ([preferences squelchMode]) {
		[statusItem setImage:squelchImage];
		[statusItem setAlternateImage:squelchHighlightImage];
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

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowlMenu action:@selector(shutdown:) keyEquivalent:@""];
	[tempMenuItem setTag:5];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kStopGrowlMenuTooltip];

	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kSquelchMode action:@selector(squelchMode:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:4];
	[tempMenuItem setToolTip:kSquelchModeTooltip];

	NSMenu *displays = [[NSMenu allocWithZone:menuZone] init];
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
	[displays release];
	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kOpenGrowlPreferences action:@selector(openGrowlPreferences:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kOpenGrowlPreferencesTooltip];

	return m;
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
	}
	return YES;
}

@end
