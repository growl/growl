//
//  AppDelegate.h
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlOnSwitch, HWGrowlPluginController;

typedef enum { 
	kShowIconInMenu = 0,
	kShowIconInDock = 1,
	kShowIconInBoth = 2,
	kDontShowIcon = 3
} HWGrowlIconState;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	
	IBOutlet NSPopUpButton *iconPopUp;
	IBOutlet GrowlOnSwitch *onLoginSwitch;
	
	HWGrowlIconState oldIconValue;
	BOOL oldOnLoginValue;
	
	HWGrowlPluginController *pluginController;
}

@property (nonatomic, retain) NSString *showDevices;
@property (nonatomic, retain) NSString *groupNetworkTitle;
@property (nonatomic, retain) NSString *quitTitle;
@property (nonatomic, retain) NSString *preferencesTitle;
@property (nonatomic, retain) NSString *openPreferencesTitle;
@property (nonatomic, retain) NSString *iconTitle;
@property (nonatomic, retain) NSString *startAtLoginTitle;

@property (nonatomic, retain) NSString *iconInMenu;
@property (nonatomic, retain) NSString *iconInDock;
@property (nonatomic, retain) NSString *iconInBoth;
@property (nonatomic, retain) NSString *noIcon;

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSPopUpButton *iconPopUp;
@property (nonatomic, retain) HWGrowlPluginController *pluginController;

@property (nonatomic, assign) IBOutlet NSToolbar *toolbar;
@property (nonatomic, assign) IBOutlet NSTabView *tabView;
@property (nonatomic, assign) IBOutlet NSView *containerView;
@property (nonatomic, retain) IBOutlet NSView *placeholderView;
@property (nonatomic, assign) IBOutlet NSView *currentView;

@end
