//
//  GrowlMenu.m
//
//
//  Created by rudy on Sun Apr 17 2005.
//  Copyright (c) 2005 The Growl Project. All rights reserved.
//

#import "GrowlMenu.h"
#import "GrowlPreferences.h"
#import "GrowlPathUtil.h"
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
#define kSquelchMode                 NSLocalizedString(@"Squelch mode", @"")
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
	preferences = [GrowlPreferences preferences];

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

- (void) applicationWillTerminate:(NSNotification *)aNotification {
#pragma unused(aNotification)
	[self release];
}

- (void) dealloc {
//	[statusItem release];
	[clawImage release];
	[clawHighlightImage release];
	[squelchImage release];
	[squelchHighlightImage release];
	[super dealloc];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSNumber *pid = [[notification userInfo] objectForKey:@"pid"];
	if (!pid || [pid intValue] != [[NSProcessInfo processInfo] processIdentifier]) {
		[self setImage];
	}
}

- (void) shutdown:(NSNotification *)theNotification {
#pragma unused(theNotification)
	[NSApp terminate:self];
}

- (IBAction) openGrowlPreferences:(id)sender {
#pragma unused(sender)
	NSString *prefPane = [[GrowlPathUtil growlPrefPaneBundle] bundlePath];
	[[NSWorkspace sharedWorkspace] openFile:prefPane];
}

- (IBAction) defaultDisplay:(id)sender {
	[preferences setObject:[sender title] forKey:GrowlDisplayPluginKey];
}

- (IBAction) stopGrowl:(id)sender {
#pragma unused(sender)
	//If Growl is running, we should stop it.
	if ([preferences isGrowlRunning])
		[preferences setGrowlRunning:NO noMatterWhat:NO];
}

- (IBAction) startGrowl:(id)sender {
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

- (IBAction) squelchMode:(id)sender {
#pragma unused(sender)
	BOOL squelchMode = ![preferences boolForKey:GrowlSquelchModeKey];
	[preferences setBool:squelchMode forKey:GrowlSquelchModeKey];
	[self setImage];
}

- (void) setImage {
	BOOL squelchMode = [preferences boolForKey:GrowlSquelchModeKey];
	if (squelchMode) {
		[statusItem setImage:squelchImage];
		[statusItem setAlternateImage:squelchHighlightImage];
	} else {
		[statusItem setImage:clawImage];
		[statusItem setAlternateImage:clawHighlightImage];
	}
}

- (IBAction) quitGrowlMenu:(id)sender {
#pragma unused(sender)
	NSString *growlMenuPath = [[NSBundle mainBundle] bundlePath];
	[preferences setStartAtLogin:growlMenuPath enabled:NO];
	[preferences setBool:NO forKey:GrowlMenuExtraKey];

	[NSApp terminate:self];
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

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowlMenu action:@selector(quitGrowlMenu:) keyEquivalent:@""];
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
	NSEnumerator *displayEnumerator = [[[GrowlPluginController controller] allDisplayPlugins] objectEnumerator];
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
			[item setState:[[item title] isEqualToString:[preferences objectForKey:GrowlDisplayPluginKey]]];
			break;
		case 4:
			[item setState:[preferences boolForKey:GrowlSquelchModeKey]];
			break;
	}
	return YES;
}

@end
