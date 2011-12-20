//
//  GrowlCalAppDelegate.m
//  GrowlCal
//
//  Created by Daniel Siemer on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlCalAppDelegate.h"
#import "GrowlCalCalendar.h"

#import <CalendarStore/CalendarStore.h>
#import <ServiceManagement/ServiceManagement.h>

@implementation GrowlCalAppDelegate
@synthesize preferencesWindow = _preferencesWindow;
@synthesize calendarController = _calendarController;
@synthesize startAtLoginControl = _startAtLoginControl;
@synthesize menu = _menu;
@synthesize statusItem = _statusItem;
@synthesize calendars = _calendars;
@synthesize position = _position;
@synthesize growlURLAvailable = _growlURLAvailable;

#pragma mark Application Delegate methods

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
   NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"StartAtLogin", 
                                                                       [NSNumber numberWithBool:NO], @"AllowStartAtLogin", nil];
   [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
   [[NSUserDefaults standardUserDefaults] synchronize];
   
   BOOL startAtLogin = [[NSUserDefaults standardUserDefaults] boolForKey:@"StartAtLogin"];
   
   [self setStartAtLogin:startAtLogin];
   
   
   NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
   [appleEventManager setEventHandler:self 
                          andSelector:@selector(handleGetURLEvent:withReplyEvent:) 
                        forEventClass:kInternetEventClass 
                           andEventID:kAEGetURL];
   
   [GrowlApplicationBridge setGrowlDelegate:self];
   self.growlURLAvailable = [GrowlApplicationBridge isGrowlURLSchemeAvailable];
   
   _position = [[NSUserDefaults standardUserDefaults] integerForKey:@"IconPosition"];
   switch (_position) {
      case IconInDock:
      case IconInBoth:
         [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
      default:
         //No need to do anything, we hide in the shadows
         break;
   }
   [self updateMenuState];
   NSArray *cached = [[NSUserDefaults standardUserDefaults] valueForKey:@"calendarCache"];
   __block NSMutableArray *blockCals = [NSMutableArray array];
   [cached enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      GrowlCalCalendar *cal = [[GrowlCalCalendar alloc] initWithDictionary:obj];
      if([cal calendar])
         [blockCals addObject:cal];
   }];
   
   BOOL removed = NO;
   if([blockCals count] < [cached count])
      removed = YES;
      
   NSArray *live = [[CalCalendarStore defaultCalendarStore] calendars];
   __block BOOL added = NO;
   [live enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if(![[blockCals valueForKey:@"uid"] containsObject:[obj uid]]){
         GrowlCalCalendar *newCal = [[GrowlCalCalendar alloc] initWithUID:[obj uid]];
         [blockCals addObject:newCal];
         added = YES;
      }
   }];
   self.calendars = blockCals;
   if(removed || added)
      [self saveCalendars];
   
}

- (NSMenu*)applicationDockMenu:(NSApplication*)app
{
   return _menu;
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
   //Open the prefs window here
   [self openPreferences:nil];
   return YES;
}

- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
   
}

- (void)setStartAtLogin:(BOOL)startAtLogin {
   [[NSUserDefaults standardUserDefaults] setBool:startAtLogin forKey:@"StartAtLogin"];
   [_startAtLoginControl setSelectedSegment:startAtLogin ? 0 : 1];
   NSURL *urlOfLoginItem = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/GrowlCalLauncher.app"];
   if(!LSRegisterURL((__bridge CFURLRef)urlOfLoginItem, YES))
      NSLog(@"Failure registering %@ with Launch Services", [urlOfLoginItem description]);
   
   if(!SMLoginItemSetEnabled(CFSTR("com.growl.GrowlCalLauncher"), startAtLogin))
      NSLog(@"Failure Setting GrowlCalLauncher to %@start at login", startAtLogin ? @"" : @"not ");
}

#pragma mark Calendar methods

- (void)saveCalendars {
   __block NSMutableArray *toSave = [NSMutableArray arrayWithCapacity:[_calendars count]];
   [_calendars enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [toSave addObject:[obj dictionaryRepresentation]];
   }];
   [[NSUserDefaults standardUserDefaults] setValue:toSave forKey:@"calendarCache"];
}

#pragma mark Menu methods

- (void)removeDockMenu {
   //We can't actually remove the dock menu without restarting, inform the user.
   if(_position != IconInDock && _position != IconInBoth)
      return;
   
   if(![[NSUserDefaults standardUserDefaults] boolForKey:@"RelaunchSuppress"]){
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:NSLocalizedString(@"GrowlCal must restart for this change to take effect.",nil)];
      [alert setShowsSuppressionButton:YES];
      [alert runModal];
      if([[alert suppressionButton] state] == NSOnState){
         [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"RelaunchSuppress"];
      }
   }
}

- (void)updateMenuState{
   BOOL show;
   switch (_position) {
      case IconInMenu:
      case IconInBoth:
         show = YES;
         break;
      case IconInDock:
      case IconInNone:
         show = NO;
         break;
   }
   if(show){
      if(_statusItem)
         return;
      
      self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
      [_statusItem setToolTip:@"Growl"];
      [_statusItem setHighlightMode:YES];
      [_statusItem setMenu:_menu];
      [_statusItem setImage:[NSImage imageNamed:NSImageNameIChatTheaterTemplate]];
   }else{
      if(!_statusItem)
         return;
      
      [[NSStatusBar systemStatusBar] removeStatusItem:_statusItem];
      self.statusItem = nil;
   }
}

- (void)setPositionNumber:(NSNumber*)number{
   [self setPosition:[number unsignedIntegerValue]];
}

- (void)setPosition:(IconPosition)state
{
   if(state == _position)
      return;
   
   switch (state) {
      case IconInMenu:
         if(_position == IconInDock || _position == IconInBoth){
            [self removeDockMenu];
         }
         break;
      case IconInDock:
      case IconInBoth:
         [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
         break;
      case IconInNone:
         if(![[NSUserDefaults standardUserDefaults] boolForKey:@"BackgroundAllowed"]){
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! Enabling this option will cause GrowlCal to run in the background", nil)
                                             defaultButton:NSLocalizedString(@"Ok", nil)
                                           alternateButton:NSLocalizedString(@"Cancel", nil)
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Enabling this option will cause GrowlCal to run without showing a dock icon or a menu item.\n\nTo access preferences, tap GrowlCal in Launchpad, or open GrowlCal in Finder.", nil)];
            [alert setShowsSuppressionButton:YES];
            NSInteger allow = [alert runModal];
            BOOL suppress = [[alert suppressionButton] state] == NSOnState;
            if(suppress)
               [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"BackgroundAllowed"];
            
            if(allow == NSAlertDefaultReturn)
               [self removeDockMenu];
            else{
               //While the state will already be reset below, we call the new setMenuNumber with our current, and thats enough to trigger the menu updating
               [self performSelector:@selector(setPositionNumber:) withObject:[NSNumber numberWithUnsignedInteger:_position] afterDelay:0];
               state = _position;
            }
         }else
            [self removeDockMenu];
         
         break;
      default:
         //Don't know what to do, leave it where it was
         return;
   }
   
   _position = state;
   [self updateMenuState];
   [[NSUserDefaults standardUserDefaults] setInteger:state forKey:@"IconPosition"];
}

#pragma mark UI methods

- (IBAction)openPreferences:(id)sender {   
   [NSApp activateIgnoringOtherApps:YES];
   if(![self.preferencesWindow isVisible]){
      [_preferencesWindow center];
      [_preferencesWindow setFrameAutosaveName:@"GrowlCalPrefsWindowFrame"];
      [_preferencesWindow setFrameUsingName:@"GrowlCalPrefsWindowFrame" force:YES];
   }
   [_preferencesWindow makeKeyAndOrderFront:sender];
}

- (IBAction)openGrowlPreferences:(id)sender {
   [GrowlApplicationBridge openGrowlPreferences:YES];
}

- (IBAction)setStartAtLoginAction:(id)sender {
   if([(NSSegmentedControl*)sender selectedSegment] == 0){
      if(![[NSUserDefaults standardUserDefaults] boolForKey:@"AllowStartAtLogin"]){
         NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert! Enabling this option will cause GrowlCal to launch when you login", nil)
                                          defaultButton:NSLocalizedString(@"Ok", nil)
                                        alternateButton:NSLocalizedString(@"Cancel", nil)
                                            otherButton:nil
                              informativeTextWithFormat:NSLocalizedString(@"Allowing this will let GrowlCal launch everytime you login, so that it can send notifications for events at all times", nil)];
         [alert setShowsSuppressionButton:YES];
         [alert beginSheetModalForWindow:[sender window]
                           modalDelegate:self
                          didEndSelector:@selector(startGrowlAtLoginAlert:didReturn:contextInfo:)
                             contextInfo:nil];
      }else{
         [self setStartAtLogin:YES];
      }
   }else{
      [self setStartAtLogin:NO];
   }
}

- (IBAction)startGrowlAtLoginAlert:(NSAlert*)alert didReturn:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
   switch (returnCode) {
      case NSAlertDefaultReturn:
         if([[alert suppressionButton] state] == NSOnState)
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AllowStartAtLogin"];
         [self setStartAtLogin:YES];
         break;
      default:
         [_startAtLoginControl setSelectedSegment:1];
         break;
   }
}

#pragma mark TableView Delegate/DataSource Methods

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   if(rowIndex >= [[_calendarController arrangedObjects] count])
      return nil;
   
   return [[_calendarController arrangedObjects] objectAtIndex:rowIndex];
}

#pragma mark GrowlApplicationBridgeDelegate Methods

- (void) growlIsReady {
   self.growlURLAvailable = [GrowlApplicationBridge isGrowlURLSchemeAvailable];
}

- (NSString *) applicationNameForGrowl {
	return @"GrowlCal";
}

- (NSDictionary *) registrationDictionaryForGrowl
{
   NSArray *allNotifications = [NSArray arrayWithObjects:@"UpcomingEventAlert",
                                                         @"EventAlert",
                                                         @"UpcomingEventEndAlert",
                                                         @"EventEndAlert",
                                                         @"UpcomingToDoAlert",
                                                         @"ToDoAlert", nil];
   NSDictionary *humanReadableNames = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Upcoming Event Alert", nil), @"UpcomingEventAlert", 
                                                                                 NSLocalizedString(@"Event Alert", nil), @"EventAlert",
                                                                                 NSLocalizedString(@"Upcoming Event End Alert", nil), @"UpcomingEventEndAlert",
                                                                                 NSLocalizedString(@"Event End Alert", nil), @"EventEndAlert",
                                                                                 NSLocalizedString(@"Upcoming To Do Alert", nil), @"UpcomingToDoAlert",
                                                                                 NSLocalizedString(@"To Do Alert", nil), @"ToDoAlert", nil];
   NSDictionary *localized = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Shows an alert for upcoming events", nil), @"UpcomingEventAlert", 
                                                                        NSLocalizedString(@"Shows an alert when an event begins", nil), @"EventAlert",
                                                                        NSLocalizedString(@"Shows an alert for the upcoming end of an event", nil), @"UpcomingEventEndAlert",
                                                                        NSLocalizedString(@"Shows an alert when an event begins", nil), @"EventEndAlert",
                                                                        NSLocalizedString(@"Shows an alert for upcoming ToDo deadlines", nil), @"UpcomingToDoAlert",
                                                                        NSLocalizedString(@"Shows an alert at ToDo deadlines", nil), @"ToDoAlert", nil];

   NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:@"GrowlCal", GROWL_APP_NAME,
                                                                      allNotifications, GROWL_NOTIFICATIONS_ALL,
                                                                      humanReadableNames, GROWL_NOTIFICATIONS_HUMAN_READABLE_NAMES,
                                                                      localized, GROWL_NOTIFICATIONS_DESCRIPTIONS, nil];
   
   return regDict;
}

- (void) growlNotificationWasClicked:(id)clickContext
{
   
}

- (BOOL) hasNetworkClientEntitlement
{
   return NO;
}


@end
