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

- initWithBundle:(NSBundle*)bundle
{
	self = [super initWithBundle:bundle];

    if( !self )
        return nil;
	
    preferences = [GrowlPreferences preferences];
	
	img = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon" ofType:@"tiff"]];
    altImg = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-alt" ofType:@"tiff"]];
    
	defaultDisplay = [preferences objectForKey:GrowlDisplayPluginKey];

    [self setImage:img];
    [self setAlternateImage:altImg];
    
    [self setMenu:[self buildMenu]];
    	
    return self;
}

- (void)dealloc
{
    [img release];
    [altImg release];
    [super dealloc];
}

- (NSMenu*)menu
{
	menu = [self buildMenu];
    return menu;
}

- (void) setMenu: (NSMenu*)m
{
    if( m == menu )
        return;
    
    [menu release];
    menu = [m retain];
}

- (IBAction) openGrowl:(id)sender {
	NSString *prefPane = [[GrowlPathUtil growlPrefPaneBundle] bundlePath];
	[[NSWorkspace sharedWorkspace] openFile:prefPane];
}

- (IBAction) defaultDisplay:(id)sender {
	[preferences setObject:[sender title] forKey:GrowlDisplayPluginKey];
}

- (IBAction) stopGrowl:(id)sender {
	//Growl is running, we should stop it.
	if([preferences isGrowlRunning])
		[preferences setGrowlRunning:NO noMatterWhat:NO];
}

- (IBAction) startGrowl:(id)sender {
	
	if(![preferences isGrowlRunning]) {
		//Growl isn't running, we should start it
		[preferences setGrowlRunning:YES noMatterWhat:NO];
	}
	else {
		//Growl is running, the title is Restart Growl, we should HUP it.
		[preferences setGrowlRunning:NO noMatterWhat:NO];
		[preferences setGrowlRunning:YES noMatterWhat:YES];
	}
}

- (NSMenu*)buildMenu {
    NSMenu *m = [[NSMenu alloc] init];
	NSMenu *displays = [[NSMenu alloc] init];
	
	NSMenuItem *tempMenuItem;
	NSEnumerator *displayEnumerator;
	
	tempMenuItem = (NSMenuItem*)[m addItemWithTitle:@"Start Growl" action:@selector(startGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	
	if([preferences isGrowlRunning])
		[tempMenuItem setTitle:@"Restart Growl"];

	tempMenuItem = (NSMenuItem*)[m addItemWithTitle:@"Stop Growl" action:@selector(stopGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	
	[m addItem:[NSMenuItem separatorItem]];
	
	tempMenuItem = (NSMenuItem*)[m addItemWithTitle:@"Default Display" action:NULL keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	
	NSString *name;
	displayEnumerator = [[[GrowlPluginController controller] allDisplayPlugins] objectEnumerator];
	while( name = [displayEnumerator nextObject]) {
		[[displays addItemWithTitle:name action:@selector(defaultDisplay:) keyEquivalent:@""] setTarget:self];
	}
	[tempMenuItem setSubmenu:displays];
	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem*)[m addItemWithTitle:@"Open Growl…" action:@selector(openGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	
    return m;
}

- (void)clearMenu:(NSMenu*)m {
    int i = 0;
    int counter = [m numberOfItems];
    for(i = 0; i < counter; i++) {
        [m removeItemAtIndex:0];
    }
}

- (BOOL) validateMenuItem:(NSMenuItem*)item {
	defaultDisplay = [preferences objectForKey:GrowlDisplayPluginKey];

	if([[item title] isEqual:@"Stop Growl"]) {
		if(![preferences isGrowlRunning])
			return NO;
		else
			return YES;
	}
	if([[item title] isEqual:@"Start Growl"]) {
		if([preferences isGrowlRunning]) {
			[item setTitle:@"Restart Growl"];
			return YES;
		}
	}
	
	if([[item title] isEqual:defaultDisplay]) {
		[item setState:YES];
		return YES;
	}
	return YES;
}


#define _getModifiers GetCurrentKeyModifiers

//Boolean IsOptionDown( void )
//{
//	return (_getModifiers() & optionKey) != 0;
//}

@end
