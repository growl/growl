//
//  AppDelegate.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlOnSwitch, HWGrowlPluginController;

typedef enum : NSInteger {
	kShowIconInMenu = 0,
	kShowIconInDock = 1,
	kShowIconInBoth = 2,
	kDontShowIcon = 3
} HWGrowlIconState;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSToolbarDelegate, NSTableViewDelegate, NSWindowDelegate> {
	NSWindow *_window;
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	
	IBOutlet NSPopUpButton *iconPopUp;
	IBOutlet GrowlOnSwitch *onLoginSwitch;
	
	HWGrowlIconState oldIconValue;
	BOOL oldOnLoginValue;
	
	HWGrowlPluginController *pluginController;
		
	NSToolbar *toolbar;
	NSToolbarItem *generalItem;
	NSToolbarItem *modulesItem;
	NSTabView *tabView;
	NSTableView *tableView;
	NSTableColumn *moduleColumn;
	NSView *containerView;
	NSTextField *noPrefsLabel;
	NSView *placeholderView;
	NSView *currentView;
	
	NSString *showDevices;
	NSString *quitTitle;
	NSString *preferencesTitle;
	NSString *openPreferencesTitle;
	NSString *iconTitle;
	NSString *startAtLoginTitle;
	NSString *noPluginPrefsTitle;
	NSString *moduleLabel;
	
	NSString *iconInMenu;
	NSString *iconInDock;
	NSString *iconInBoth;
	NSString *noIcon;
   
   ProcessSerialNumber previousPSN;
}

@property (nonatomic, retain) IBOutlet NSString *showDevices;
@property (nonatomic, retain) IBOutlet NSString *quitTitle;
@property (nonatomic, retain) IBOutlet NSString *preferencesTitle;
@property (nonatomic, retain) IBOutlet NSString *openPreferencesTitle;
@property (nonatomic, retain) IBOutlet NSString *iconTitle;
@property (nonatomic, retain) IBOutlet NSString *startAtLoginTitle;
@property (nonatomic, retain) IBOutlet NSString *noPluginPrefsTitle;
@property (nonatomic, retain) IBOutlet NSString *moduleLabel;

@property (nonatomic, retain) NSString *iconInMenu;
@property (nonatomic, retain) NSString *iconInDock;
@property (nonatomic, retain) NSString *iconInBoth;
@property (nonatomic, retain) NSString *noIcon;

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSPopUpButton *iconPopUp;
@property (nonatomic, retain) HWGrowlPluginController *pluginController;

@property (nonatomic, assign) IBOutlet NSToolbar *toolbar;
@property (nonatomic, assign) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, assign) IBOutlet NSToolbarItem *modulesItem;
@property (nonatomic, assign) IBOutlet NSTabView *tabView;
@property (nonatomic, assign) IBOutlet NSTableColumn *moduleColumn;
@property (nonatomic, assign) IBOutlet NSTableView *tableView;
@property (nonatomic, assign) IBOutlet NSView *containerView;
@property (nonatomic, assign) IBOutlet NSTextField *noPrefsLabel;
@property (nonatomic, retain) IBOutlet NSView *placeholderView;
@property (nonatomic, assign) IBOutlet NSView *currentView;

@end
