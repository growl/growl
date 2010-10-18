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
#import "GrowlNotificationDatabase.h"
#import "GrowlHistoryNotification.h"
#include <unistd.h>

#define kRestartGrowl                NSLocalizedString(@"Restart Growl", @"")
#define kRestartGrowlTooltip         NSLocalizedString(@"Restart Growl", @"")
#define kStartGrowl                  NSLocalizedString(@"Start Growl", @"")
#define kStartGrowlTooltip           NSLocalizedString(@"Start Growl", @"")
#define kStopGrowl                   NSLocalizedString(@"Stop Growl", @"")
#define kStopGrowlTooltip            NSLocalizedString(@"Stop Growl", @"")
#define kOpenGrowlPreferences        NSLocalizedString(@"Open Growl Preferences...", @"")
#define kOpenGrowlPreferencesTooltip NSLocalizedString(@"Open the Growl preference pane", @"")
#define kSquelchMode                 NSLocalizedString(@"Log only, don't display", @"")
#define kSquelchModeTooltip          NSLocalizedString(@"Don't show notifications, but still log them", @"")
#define kStopGrowlMenu               NSLocalizedString(@"Hide Status Item", @"")
#define kStopGrowlMenuTooltip        NSLocalizedString(@"Hide this status item", @"")
#define kStickyWhenAwayMenu			 NSLocalizedString(@"Sticky Notifications", @"")
#define kStickyWhenAwayMenuTooltip   NSLocalizedString(@"Toggles the sticky notification state", @"")
#define kNoRecentNotifications       NSLocalizedString(@"No Recent Notifications", @"")
#define kOpenGrowlLogTooltip         NSLocalizedString(@"Application: %@%\nTitle: %@\nDescription: %@\nClick to open the log", @"")
#define kGrowlHistoryLogDisabled     NSLocalizedString(@"Growl History Disabled", @"")

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
   
   [[GrowlNotificationDatabase sharedInstance] setUpdateDelegate:self];
}

#pragma mark -

- (void) setGrowlMenuEnabled:(BOOL)state {
	NSString *growlMenuPath = [[NSBundle mainBundle] bundlePath];
	[preferences setStartAtLogin:growlMenuPath enabled:state];
	[preferences setBool:state forKey:GrowlMenuExtraKey];
}

- (void) applicationWillTerminate:(NSNotification *)aNotification {
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

-(BOOL)CanGrowlDatabaseHardReset:(GrowlAbstractDatabase *)database
{
   //We don't need to do anything because we don't retain references to any ManagedObjects
   return YES;
}

-(void)GrowlDatabaseDidUpdate:(GrowlAbstractDatabase*)database
{
   NSArray *noteArray = [[GrowlNotificationDatabase sharedInstance] mostRecentNotifications:5];
   NSArray *menuItems = [[statusItem menu] itemArray];
   
   unsigned int menuIndex = 8;
   if([noteArray count] > 0)
   {
      for(id note in noteArray)
      {
         NSString *tooltip = [NSString stringWithFormat:kOpenGrowlLogTooltip, [note ApplicationName], [note Title], [note Description]];
         //Do we presently have a menu item for this note? if so, change it, if not, add a new one
         if(menuIndex < [menuItems count])
         {
            [[menuItems objectAtIndex:menuIndex] setTitle:[note Title]];
            [[menuItems objectAtIndex:menuIndex] setToolTip:tooltip];
            [[statusItem menu] itemChanged:[menuItems objectAtIndex:menuIndex]];
         }else {
            NSMenuItem *tempMenuItem = (NSMenuItem *)[[statusItem menu] addItemWithTitle:[note Title] action:@selector(openGrowlLog:) keyEquivalent:@""];
            [tempMenuItem setTarget:self];
            [tempMenuItem setToolTip:tooltip];
            [[statusItem menu] itemChanged:tempMenuItem];
         }
         menuIndex++;
      }
      //Did we not get back less than are on the menu? remove any extra listings
      if ([noteArray count] < [[[statusItem menu] itemArray] count] - 8) {
         unsigned long int toRemove = 0;
         for(toRemove = [[[statusItem menu] itemArray] count] - [noteArray count] - 8 ; toRemove > 0; toRemove--)
         {
            [[statusItem menu] removeItemAtIndex:menuIndex];
         }
      }
   }else {
      if ([preferences isGrowlHistoryLogEnabled])
         [[menuItems objectAtIndex:menuIndex] setTitle:kNoRecentNotifications];
      else
         [[menuItems objectAtIndex:menuIndex] setTitle:kGrowlHistoryLogDisabled];
      [[menuItems objectAtIndex:menuIndex] setToolTip:@""];
      [[menuItems objectAtIndex:menuIndex] setTarget:self];
      
      //Make sure there arent extra items at the moment since we don't seem to have any
      unsigned int toRemove = 0;
      for(toRemove = 0; toRemove < 4; toRemove++)
      {
         [[statusItem menu] removeItemAtIndex:toRemove + 9];
      }
   }

}

- (void) openGrowlPreferences:(id)sender {
	NSString *prefPane = [[GrowlPathUtilities growlPrefPaneBundle] bundlePath];
	[[NSWorkspace sharedWorkspace] openFile:prefPane];
}

- (void) stopGrowl:(id)sender {
	//If Growl is running, we should stop it.
	if ([preferences isGrowlRunning])
		[preferences setGrowlRunning:NO noMatterWhat:NO];
}

- (void) startGrowl:(id)sender {
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
	BOOL squelchMode = ![preferences squelchMode];
	[preferences setSquelchMode:squelchMode];
	[self setImage];
}

- (void) stickyWhenIdle:(id)sender {
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

-(void)openGrowlLog:(id)sender
{
   [preferences setSelectedPreferenceTab:4];
   [self openGrowlPreferences:nil];
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

	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStopGrowlMenu action:@selector(shutdown:) keyEquivalent:@""];
	[tempMenuItem setTag:5];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kStopGrowlMenuTooltip];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kOpenGrowlPreferences action:@selector(openGrowlPreferences:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kOpenGrowlPreferencesTooltip];
   
	[m addItem:[NSMenuItem separatorItem]];
   /*TODO: need to check against prefferences whether we are logging or not*/
   NSArray *noteArray = [[GrowlNotificationDatabase sharedInstance] mostRecentNotifications:5];
   if([noteArray count] > 0)
   {
      unsigned int tag = 8;
      for(id note in noteArray)
      {
         tempMenuItem = (NSMenuItem *)[m addItemWithTitle:[note Title] 
                                                   action:@selector(openGrowlLog:)
                                            keyEquivalent:@""];
         [tempMenuItem setTarget:self];
         [tempMenuItem setToolTip:[NSString stringWithFormat:kOpenGrowlLogTooltip, [note ApplicationName], [note Title], [note Description]]];
         [tempMenuItem setTag:tag];
         tag++;
      }
   }else {
      NSString *tempString;
      if ([preferences isGrowlHistoryLogEnabled])
         tempString = kNoRecentNotifications;
      else
         tempString = kGrowlHistoryLogDisabled;
      tempMenuItem = (NSMenuItem *)[m addItemWithTitle:tempString 
                                                action:@selector(openGrowlLog:)
                                         keyEquivalent:@""];
      [tempMenuItem setTarget:self];
      [tempMenuItem setEnabled:NO];
      [tempMenuItem setTag:8];
   }


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
		case 4:
			[item setState:[preferences squelchMode]];
			break;
		case 6:
			[item setState:[preferences stickyWhenAway]];
			break;
      case 8:
         return ![[item title] isEqualToString:kNoRecentNotifications] && ![[item title] isEqualToString:kGrowlHistoryLogDisabled];
         break;
	}
	return YES;
}

@end
