//
//  GrowlCalAppDelegate.h
//  GrowlCal
//
//  Created by Daniel Siemer on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

enum _IconPosition {
   IconInMenu = 0,
   IconInDock = 1,
   IconInBoth = 2,
   IconInNone = 3,
}; 
typedef NSUInteger IconPosition;

@class GrowlCalCalendarController;

@interface GrowlCalAppDelegate : NSObject <NSApplicationDelegate, GrowlApplicationBridgeDelegate>

@property (assign) IBOutlet NSWindow *preferencesWindow;
@property (assign) IBOutlet NSMenu *menu;
@property (assign) IBOutlet NSArrayController *calendarArrayController;
@property (assign) IBOutlet NSSegmentedControl *startAtLoginControl;
@property (strong) NSStatusItem *statusItem; 
@property (strong) GrowlCalCalendarController *calendarController;

@property (nonatomic) IconPosition position;
@property (nonatomic) BOOL growlURLAvailable;

- (void)setStartAtLogin:(BOOL)startAtLogin;
- (void)updateMenuState;
- (IBAction)openPreferences:(id)sender;
- (IBAction)openGrowlPreferences:(id)sender;
- (IBAction)setStartAtLoginAction:(id)sender;

@end
