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
	menu = [self buildMenu];
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
	NSMenu *m = [[NSMenu alloc] init];
	NSMenu *displays = [[NSMenu alloc] init];
	
	NSMenuItem *tempMenuItem;
	NSEnumerator *displayEnumerator;

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:@"Start Growl" action:@selector(startGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];

	if ([preferences isGrowlRunning])
		[tempMenuItem setTitle:@"Restart Growl"];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Stop Growl", nil, [self bundle], @"") action:@selector(stopGrowl:) keyEquivalent:@""];
	[tempMenuItem setTag:1];
	[tempMenuItem setTarget:self];

	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:@"Default Display" action:NULL keyEquivalent:@""];
	[tempMenuItem setTarget:self];

	NSString *name;
	displayEnumerator = [[[GrowlPluginController controller] allDisplayPlugins] objectEnumerator];
	while ((name = [displayEnumerator nextObject])) {
		[[displays addItemWithTitle:name action:@selector(defaultDisplay:) keyEquivalent:@""] setTarget:self];
	}
	[tempMenuItem setSubmenu:displays];
	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Open Growl preferences...", nil, [self bundle], @"") action:@selector(openGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];

	return m;
}

- (void) clearMenu:(NSMenu *)m {
	for (register int counter = [m numberOfItems]; i > 0; --i) {
		[m removeItemAtIndex:0];
	}
}

- (BOOL) validateMenuItem:(NSMenuItem *)item {
	NSString *defaultDisplay = [preferences objectForKey:GrowlDisplayPluginKey];
	NSString *title = [item title];

	if ([item tag] == 1) {
		return [preferences isGrowlRunning];
	} else if ([title isEqualToString:@"Start Growl"]) {
		if ([preferences isGrowlRunning]) {
			[item setTitle:@"Restart Growl"];
		}
	} else if ([title isEqualToString:defaultDisplay]) {
		[item setState:YES];
	}
	return YES;
}

#define _getModifiers GetCurrentKeyModifiers

//Boolean IsOptionDown( void )
//{
//	return (_getModifiers() & optionKey) != 0;
//}

@end
