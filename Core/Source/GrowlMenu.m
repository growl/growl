//
//  GrowlMenu.m
//
//
//  Created by rudy on Sun Apr 17 2005.
//  Copyright (c) 2005 The Growl Project. All rights reserved.
//

#import "GrowlMenu.h"
#import "GrowlPreferencesController.h"
#import "GrowlPreferencePane.h"
#import "GrowlPathUtilities.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlHistoryNotification.h"
#import "GrowlApplicationController.h"
#import "GrowlMenuImageView.h"
#import <Quartz/Quartz.h>
#include <unistd.h>

#define kStartGrowl                  NSLocalizedString(@"Resume Growl", @"")
#define kStartGrowlTooltip           NSLocalizedString(@"Resume Growl visual notifications", @"")
#define kStopGrowl                   NSLocalizedString(@"Pause Growl", @"")
#define kStopGrowlTooltip            NSLocalizedString(@"Pause Growl visual notifications", @"")
#define kShowRollup                  NSLocalizedString(@"Show Rollup", @"")
#define kShowRollupTooltip           NSLocalizedString(@"Show the History Rollup", @"")
#define kHideRollup                  NSLocalizedString(@"Hide Rollup", @"")
#define kHideRollupTooltip           NSLocalizedString(@"Hide the History Rollup", @"")
#define kOpenGrowlPreferences        NSLocalizedString(@"Open Growl Preferences...", @"")
#define kOpenGrowlPreferencesTooltip NSLocalizedString(@"Open the Growl preference pane", @"")
#define kNoRecentNotifications       NSLocalizedString(@"No Recent Notifications", @"")
#define kOpenGrowlLogTooltip         NSLocalizedString(@"Application: %@\nTitle: %@\nDescription: %@\nClick to open the log", @"")
#define kGrowlHistoryLogDisabled     NSLocalizedString(@"Growl History Disabled", @"")
#define kGrowlQuit                   NSLocalizedString(@"Quit", @"")
#define kQuitGrowlMenuTooltip        NSLocalizedString(@"Quit Growl entirely", @"")

#define kStartStopMenuTag           1
#define kShowHideRollupTag          2
#define kHistoryItemTag             6
#define kMenuItemsBeforeHistory     6

@implementation GrowlMenu

@synthesize settingsWindow;
@synthesize statusItem;
@synthesize menu;

#pragma mark -

- (id) init {
    
    if ((self = [super init])) {
        preferences = [GrowlPreferencesController sharedController];
        
        self.menu = [self createMenu:NO];
               
        [self setGrowlMenuEnabled:YES];
        
        //NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        /*[nc addObserver:self
         selector:@selector(reloadPrefs:)
         name:GrowlPreferencesChanged
         object:nil];*/
        
        GrowlNotificationDatabase *db = [GrowlNotificationDatabase sharedInstance];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(growlDatabaseDidUpdate:) 
                                                     name:@"GrowlDatabaseUpdated"
                                                   object:db];
        
        [preferences addObserver:self forKeyPath:@"squelchMode" options:NSKeyValueObservingOptionNew context:&self];
    }
    return self;
}

- (void) dealloc {
	[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
	[statusItem release];
   statusItem = nil;
   [menu release];
   menu = nil;

   [preferences removeObserver:self forKeyPath:@"squelchMode"];
   [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"squelchMode"])
    {
        NSMenuItem *menuItem = [[menu itemArray] objectAtIndex:0U];
        BOOL squelch = [preferences squelchMode] ? NO : YES;        
        if (!squelch) {
            [menuItem setTitle:kStopGrowl];
            [menuItem setToolTip:kStopGrowlTooltip];
        } else {
            [menuItem setTitle:kStartGrowl];
            [menuItem setToolTip:kStartGrowlTooltip];
        }
        [self setImage:[NSNumber numberWithBool:squelch]];
    }
}

- (void)toggleStatusMenu:(BOOL)show
{
   if(show){
      if(statusItem)
         return;
      
      self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
      
      
      
      [statusItem setToolTip:@"Growl"];
      [statusItem setHighlightMode:YES];
      GrowlMenuImageView *buttonView = [[GrowlMenuImageView alloc] init];
      buttonView.menuItem = self;
      [statusItem setView:buttonView];
      [self setImage:[NSNumber numberWithBool:![preferences squelchMode]]];
      [buttonView release];
   }else{
      if(!statusItem)
         return;
      
      [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
      [statusItem release];
      statusItem = nil;
   }
}

- (void)startPulse{
   if(!keepPulsing){
      keepPulsing = YES;
      [self pulseStatusItem];
   }
}

- (void)stopPulse{
   keepPulsing = NO;
}

- (void)pulseStatusItem
{
   if(!statusItem || !keepPulsing)
      return;
   
   NSStatusItem *blockItem = statusItem;
   __block GrowlMenu *blockMenu = self;
   [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
      [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
      [context setDuration:1.0f];
      [[[blockItem view] animator] setAlphaValue:0.0];
   } completionHandler:^(void) {
      [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
         [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
         [context setDuration:1.0f];
         [[[blockItem view] animator] setAlphaValue:1.0];
      } completionHandler:^(void) {
         [blockMenu pulseStatusItem];
      }];
   }];
   
}

#pragma mark -
#pragma mark Growl History
#pragma mark -

-(void)growlDatabaseDidUpdate:(NSNotification*)notification
{
   NSArray *noteArray = [[GrowlNotificationDatabase sharedInstance] mostRecentNotifications:5];
   NSArray *menuItems = [menu itemArray];
   
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
            [menu itemChanged:[menuItems objectAtIndex:menuIndex]];
         }else {
            NSMenuItem *tempMenuItem = (NSMenuItem *)[menu addItemWithTitle:[note Title] action:@selector(openGrowlLog:) keyEquivalent:@""];
            [tempMenuItem setTarget:self];
            [tempMenuItem setToolTip:tooltip];
            [menu itemChanged:tempMenuItem];
         }
         menuIndex++;
      }
      //Did we get back less than are on the menu? remove any extra listings
      if ([noteArray count] < [[menu itemArray] count] - kMenuItemsBeforeHistory) {
         NSInteger toRemove = 0;
         for(toRemove = [[menu itemArray] count] - [noteArray count] - kMenuItemsBeforeHistory ; toRemove > 0; toRemove--)
         {
            [menu removeItemAtIndex:menuIndex];
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
         [menu removeItemAtIndex:toRemove - 1];
      }
   }

}

#pragma mark -
#pragma mark IBActions
#pragma mark -

- (IBAction) openGrowlPreferences:(id)sender {
   [[GrowlApplicationController sharedInstance] showPreferences];
}

- (IBAction) startStopGrowl:(id)sender {
    BOOL squelch = [preferences squelchMode] ? NO : YES;
    [preferences setSquelchMode:squelch];
}

- (IBAction)openGrowlLog:(id)sender
{
    [preferences setSelectedPreferenceTab:4];
    [self openGrowlPreferences:nil];
}

- (IBAction)toggleRollup:(id)sender
{
   [preferences setRollupShown:![preferences isRollupShown]];
}

#pragma mark -

- (void) setGrowlMenuEnabled:(BOOL)state {
	/*NSString *growlMenuPath = [[NSBundle mainBundle] bundlePath];
	[preferences setStartAtLogin:growlMenuPath enabled:state];*/
    
	[self setImage:[NSNumber numberWithBool:![preferences squelchMode]]];
}

- (void) setImage:(NSNumber*)state {
	
	NSImage *normalImage = nil;
	NSImage *pressedImage = nil;
	switch([state unsignedIntegerValue])
	{
		case kGrowlNotRunningState:
			normalImage = [NSImage imageNamed:@"squelch.png"];
			pressedImage = [NSImage imageNamed:@"growlmenu.png"];
			break;
		case kGrowlRunningState:
		default:
			normalImage = [NSImage imageNamed:@"growlmenu.png"];
			pressedImage = [NSImage imageNamed:@"growlmenu-alt.png"];
			break;
	}
	[(GrowlMenuImageView*)[statusItem view] setMainImage:normalImage];
	[(GrowlMenuImageView*)[statusItem view] setAlternateImage:pressedImage];
}

- (NSMenu *) createMenu:(BOOL)forDock {
	NSZone *menuZone = [NSMenu menuZone];
	NSMenu *m = [[NSMenu allocWithZone:menuZone] init];

	NSMenuItem *tempMenuItem;

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kStartGrowl action:@selector(startStopGrowl:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setTag:kStartStopMenuTag];

	if (![[GrowlPreferencesController sharedController] squelchMode]) {
		[tempMenuItem setTitle:kStopGrowl];
		[tempMenuItem setToolTip:kStopGrowlTooltip];
	} else {
		[tempMenuItem setToolTip:kStartGrowlTooltip];
	}
   
   tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kShowRollup action:@selector(toggleRollup:) keyEquivalent:@""];
   [tempMenuItem setTarget:self];
   [tempMenuItem setTag:kShowHideRollupTag];
   if([[GrowlPreferencesController sharedController] isRollupShown]){
      [tempMenuItem setTitle:kHideRollup];
      [tempMenuItem setToolTip:kHideRollupTooltip];
   }else{
      [tempMenuItem setToolTip:kShowRollupTooltip];
   }
   
   if(![[GrowlPreferencesController sharedController] isRollupEnabled])
      [tempMenuItem setEnabled:NO];

	[m addItem:[NSMenuItem separatorItem]];

	tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kOpenGrowlPreferences action:@selector(openGrowlPreferences:) keyEquivalent:@""];
	[tempMenuItem setTarget:self];
	[tempMenuItem setToolTip:kOpenGrowlPreferencesTooltip];
   
   if(!forDock){
      tempMenuItem = (NSMenuItem *)[m addItemWithTitle:kGrowlQuit action:@selector(terminate:) keyEquivalent:@""];
      [tempMenuItem setTarget:NSApp];
      [tempMenuItem setToolTip:kQuitGrowlMenuTooltip];
      
      [m addItem:[NSMenuItem separatorItem]];
      /*TODO: need to check against prefferences whether we are logging or not*/
      NSArray *noteArray = [[GrowlNotificationDatabase sharedInstance] mostRecentNotifications:5];
      if([noteArray count] > 0)
      {
         for(id note in noteArray)
         {
            tempMenuItem = (NSMenuItem *)[m addItemWithTitle:[note Title] 
                                                      action:@selector(openGrowlLog:)
                                               keyEquivalent:@""];
            [tempMenuItem setTarget:self];
            [tempMenuItem setToolTip:[NSString stringWithFormat:kOpenGrowlLogTooltip, [note ApplicationName], [note Title], [note Description]]];
            [tempMenuItem setTag:kHistoryItemTag];
         }
      }else {
         NSString *tempString;
         if ([[GrowlPreferencesController sharedController] isGrowlHistoryLogEnabled])
            tempString = kNoRecentNotifications;
         else
            tempString = kGrowlHistoryLogDisabled;
         tempMenuItem = (NSMenuItem *)[m addItemWithTitle:tempString 
                                                   action:@selector(openGrowlLog:)
                                            keyEquivalent:@""];
         [tempMenuItem setTarget:self];
         [tempMenuItem setEnabled:NO];
         [tempMenuItem setTag:kHistoryItemTag];
      }
   }
   

	return [m autorelease];
}

- (BOOL) validateMenuItem:(NSMenuItem *)item {
	BOOL isGrowlRunning = ![preferences squelchMode];
	//we do this because growl might have died or been launched, and NSWorkspace doesn't post 
	//notifications to its notificationCenter for LSUIElement apps for NSWorkspaceDidLaunchApplicationNotification or NSWorkspaceDidTerminateApplicationNotification
	[self setImage:[NSNumber numberWithBool:isGrowlRunning]];
	
	switch ([item tag]) {
		case kStartStopMenuTag:
			if (isGrowlRunning) {
				[item setTitle:kStopGrowl];
				[item setToolTip:kStopGrowlTooltip];
			} else {
				[item setTitle:kStartGrowl];
				[item setToolTip:kStartGrowlTooltip];
			}
			break;
      case kShowHideRollupTag:
         if ([preferences isRollupShown]) {
				[item setTitle:kHideRollup];
				[item setToolTip:kHideRollupTooltip];
			} else {
				[item setTitle:kShowRollup];
				[item setToolTip:kShowRollupTooltip];
			}
         
         if(![preferences isRollupEnabled])
            return NO;

         break;
      case kHistoryItemTag:
         return ![[item title] isEqualToString:kNoRecentNotifications] && ![[item title] isEqualToString:kGrowlHistoryLogDisabled];
         break;
	}
	return YES;
}

@end
