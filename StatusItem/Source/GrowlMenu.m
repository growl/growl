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
#define kStopGrowlMenu               NSLocalizedString(@"Hide Status Item", @"")
#define kStopGrowlMenuTooltip        NSLocalizedString(@"Hide this status item", @"")
#define kStickyWhenAwayMenu			 NSLocalizedString(@"Sticky Notifications", @"")
#define kStickyWhenAwayMenuTooltip   NSLocalizedString(@"Toggles the sticky notification state", @"")
#define kNoRecentNotifications       NSLocalizedString(@"No Recent Notifications", @"")
#define kOpenGrowlLogTooltip         NSLocalizedString(@"Application: %@%\nTitle: %@\nDescription: %@\nClick to open the log", @"")
#define kGrowlHistoryLogDisabled     NSLocalizedString(@"Growl History Disabled", @"")

#define kMenuItemsBeforeHistory      6

@implementation GrowlMenu

- (id) init {
    
    if ((self = [super init]))
    {
        pid = getpid();
        preferences = [GrowlPreferencesController sharedController];
        
        NSMenu *m = [self createMenu];
        
        statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
        
        NSBundle *bundle = [NSBundle mainBundle];
        
        clawImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growlmenu" ofType:@"png"]];
        clawHighlightImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"growlmenu-alt" ofType:@"png"]];
        disabledImage = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"squelch" ofType:@"png"]];
        
        [self setImage:[NSNumber numberWithBool:[preferences isGrowlRunning]]];
        
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
    return self;
}

#pragma mark -

- (void) setGrowlMenuEnabled:(BOOL)state {
	NSString *growlMenuPath = [[NSBundle mainBundle] bundlePath];
	[preferences setStartAtLogin:growlMenuPath enabled:state];

	[self performSelector:@selector(setImage:) withObject:[NSNumber numberWithBool:[preferences isGrowlRunning]] afterDelay:1.0f inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, NSModalPanelRunLoopMode, nil ]];
}

- (void) dealloc {
//	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
//	[statusItem            release];
	[clawImage             release];
	[clawHighlightImage    release];
	[disabledImage          release];
	[super dealloc];
}

- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSNumber *pidValue = [[notification userInfo] objectForKey:@"pid"];
	if (!pidValue || [pidValue intValue] != pid)
		[self setImage:kGrowlNotRunningState];
	else {
		[self setImage:[NSNumber numberWithUnsignedInteger:kGrowlRunningState]];
	}

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
   
   unsigned int menuIndex = kMenuItemsBeforeHistory;
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
      //Did we get back less than are on the menu? remove any extra listings
      if ([noteArray count] < [[[statusItem menu] itemArray] count] - kMenuItemsBeforeHistory) {
         NSInteger toRemove = 0;
         for(toRemove = [[[statusItem menu] itemArray] count] - [noteArray count] - kMenuItemsBeforeHistory ; toRemove > 0; toRemove--)
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
      NSInteger toRemove = 0;
      for(toRemove = [menuItems count]; toRemove > kMenuItemsBeforeHistory + 1; toRemove--)
      {
         [[statusItem menu] removeItemAtIndex:toRemove - 1];
      }
   }

}

- (void) openGrowlPreferences:(id)sender {
//TODO: open the config window here
}

- (void) stopGrowl:(id)sender {
//TODO: turn on squelch mode
}

- (void) startGrowl:(id)sender {
//TODO: turn off squelch mode
}

- (void) stickyWhenIdle:(id)sender {
	BOOL idleModeState = ![preferences stickyWhenAway];
	[preferences setStickyWhenAway:idleModeState];
}

- (void) setImage:(NSNumber*)state {
	
	NSImage *normalImage = nil;
	NSImage *pressedImage = nil;
	switch([state unsignedIntegerValue])
	{
		case kGrowlNotRunningState:
			normalImage = disabledImage;
			pressedImage = clawHighlightImage;
			break;
		case kGrowlRunningState:
		default:
			normalImage = clawImage;
			pressedImage = clawHighlightImage;
			break;
	}
	[statusItem setImage:normalImage];
	[statusItem setAlternateImage:pressedImage];
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
	BOOL isGrowlRunning = [preferences isGrowlRunning];
	//we do this because growl might have died or been launched, and NSWorkspace doesn't post 
	//notifications to its notificationCenter for LSUIElement apps for NSWorkspaceDidLaunchApplicationNotification or NSWorkspaceDidTerminateApplicationNotification
	[self setImage:[NSNumber numberWithBool:isGrowlRunning]];
	
	switch ([item tag]) {
		case 1:
			if (isGrowlRunning) {
				[item setTitle:kRestartGrowl];
				[item setToolTip:kRestartGrowlTooltip];
			} else {
				[item setTitle:kStartGrowl];
				[item setToolTip:kStartGrowlTooltip];
			}
			break;
		case 2:
			return isGrowlRunning;
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
         return ![[item title] isEqualToString:kNoRecentNotifications] && ![[item title] isEqualToString:kGrowlHistoryLogDisabled];
         break;
	}
	return YES;
}

@end
