//
//  RRGrowlMenu.m
//  
//
//  Created by rudy on Sun Apr 17 2005.
//  Copyright (c) 2005 Rudy Richter. All rights reserved.
//

#import "GrowlMenu.h"
#import "GrowlPreferences.h"
#import "GrowlPathUtil.h"
#import "GrowlPluginController.h"

#import <Cocoa/Cocoa.h>

@implementation GrowlMenu

#define kRestartGrowl         NSLocalizedStringFromTableInBundle(@"Restart Growl", nil, [self bundle], @"")
#define kStartGrowl           NSLocalizedStringFromTableInBundle(@"Start Growl", nil, [self bundle], @"")
#define kStopGrowl            NSLocalizedStringFromTableInBundle(@"Stop Growl", nil, [self bundle], @"")
#define kDefaultDisplay       NSLocalizedStringFromTableInBundle(@"Default display", nil, [self bundle], @"")
#define kOpenGrowlPreferences NSLocalizedStringFromTableInBundle(@"Open Growl preferences...", nil, [self bundle], @"")

- (id) initWithBundle:(NSBundle *)bundle {
	if ((self = [super initWithBundle:bundle])) {
		preferences = [GrowlPreferences preferences];

		img = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon" ofType:@"tiff"]];
		altImg = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-alt" ofType:@"tiff"]];

		[self setImage:img];
		[self setAlternateImage:altImg];

		[self setMenu:[self buildMenu]];
	}
	return self;
}

- (void) dealloc {
	[menu release];

	[img release];
	[altImg release];

	[super dealloc];
}

- (NSMenu *) menu {
	return menu;
}

- (void) setMenu: (NSMenu *)m {
	if (m != menu) {
		[menu release];
		menu = [m retain];
	}
}

- (IBAction) openGrowl:(id)sender {
	NSString *prefPane = [[GrowlPathUtil growlPrefPaneBundle] bundlePath];
	[[NSWorkspace sharedWorkspace] openFile:prefPane];
}

- (IBAction) defaultDisplay:(id)sender {
	[preferences setObject:[sender title] forKey:GrowlDisplayPluginKey];
}

- (IBAction) stopGrowl:(id)sender {
	//If Growl is running, we should stop it.
	if ([preferences isGrowlRunning])
		[preferences setGrowlRunning:NO noMatterWhat:NO];
}

- (IBAction) startGrowl:(id)sender {
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

- (NSMenu *)buildMenu {
	NSMenu *m = [[NSMenu allocWithZone:[NSMenu menuZone]] init];

	NSMenuItem *tempMenuItem;

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStartGrowl action:@selector(startGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:1];

	if ([preferences isGrowlRunning])
		[tempMenuItem setTitle:kRestartGrowl];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowl action:@selector(stopGrowl:) keyEquivalent:@""];
	[tempMenuItem setTag:2];
	[tempMenuItem setTarget:self];

	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kDefaultDisplay action:NULL keyEquivalent:@""];
	[tempMenuItem setTarget:self];

	NSMenu *displays = [[NSMenu allocWithZone:[NSMenu menuZone]] init];
	NSString *name;
	NSEnumerator *displayEnumerator = [[[GrowlPluginController controller] allDisplayPlugins] objectEnumerator];
	while ((name = [displayEnumerator nextObject])) {
		[[displays addItemWithTitle:name action:@selector(defaultDisplay:) keyEquivalent:@""] setTarget:self];
	}
	[tempMenuItem setSubmenu:displays];
	[displays release];
	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kOpenGrowlPreferences action:@selector(openGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];

	return [m autorelease];
}

- (BOOL) validateMenuItem:(NSMenuItem *)item {
	NSString *defaultDisplay = [preferences objectForKey:GrowlDisplayPluginKey];
	NSString *title = [item title];
	int tag = [item tag];

	if (tag == 1) {
		if ([preferences isGrowlRunning]) {
			[item setTitle:kRestartGrowl];
		} else {
			[item setTitle:kStartGrowl];
		}
	} else if (tag == 2) {
		return [preferences isGrowlRunning];
	} else if ([title isEqualToString:defaultDisplay]) {
		[item setState:YES];
	}
	return YES;
}

@end
