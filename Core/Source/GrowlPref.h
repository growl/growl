//
//  GrowlPref.h
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <PreferencePanes/PreferencePanes.h>

@protocol GrowlPlugin;

@interface GrowlPref : NSPreferencePane {
	NSMutableArray			*images;
	NSMutableDictionary		*tickets;
	NSMutableArray			*applications;
	NSTimer					*startStopTimer;
	
	NSPreferencePane		*pluginPrefPane;
	NSMutableArray			*loadedPrefPanes;
	
	//Properties of the app being configured
	NSString				*currentApplication;
	GrowlApplicationTicket	*appTicket;

	//Properties of the plugin being configured
	NSString				*currentPlugin;
	id <GrowlPlugin>		currentPluginController;

	BOOL					growlIsRunning;
	BOOL					prefsHaveChanged;

	NSURL					*versionCheckURL;
	NSURL					*downloadURL;

	IBOutlet NSTabView		*tabView;

	//"General" tab pane
	IBOutlet NSButton				*startGrowlAtLogin;
	IBOutlet NSButton				*startStopGrowl;
	IBOutlet NSTextField			*growlRunningStatus;
	IBOutlet NSProgressIndicator	*growlRunningProgress;
	IBOutlet NSPopUpButton			*allDisplayPlugins;
	IBOutlet NSTextField			*growlVersion;
	IBOutlet NSProgressIndicator	*growlVersionProgress;

	//"Applications" tab pane
	IBOutlet NSTableView	*applicationNotifications;
	IBOutlet NSTableView	*growlApplications;
	NSMenu					*applicationDisplayPluginsMenu;
	IBOutlet NSMenu			*notificationPriorityMenu;

	//"Display Options" tab pane
	IBOutlet NSTableView	*displayPlugins;
	IBOutlet NSView			*displayPrefView;
	IBOutlet NSView			*displayDefaultPrefView;
	IBOutlet NSTextField	*displayAuthor;
	IBOutlet NSTextField	*displayVersion;

	//"Network" tab pane
	IBOutlet NSButton			*startGrowlServer;
	IBOutlet NSButton			*allowRemoteRegistration;
	IBOutlet NSSecureTextField	*networkPassword;
	IBOutlet NSButton			*enableForward;
	IBOutlet NSTableView		*growlServiceList;

	NSMutableArray			*services;
	NSNetServiceBrowser		*browser;
	NSNetService			*serviceBeingResolved;
	int						currentServiceIndex;

	IBOutlet NSButton		*apply;
	IBOutlet NSButton		*revert;
	IBOutlet NSButton		*remove;
}

- (NSString *) bundleVersion;
- (IBAction) checkVersion:(id)sender;
- (void) checkVersionAtURL:(NSURL *)url displayText:(NSString *)message downloadURL:(NSURL *)goURL;
- (void) downloadSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void) reloadPreferences;
- (void) updateRunningStatus;
- (void) reloadAppTab;
- (void) reloadDisplayTab;
- (void) buildMenus;

- (BOOL) isGrowlRunning;
- (void) launchGrowl;
- (void) terminateGrowl;

#pragma mark "General" tab pane
- (IBAction) startStopGrowl:(id)sender;
- (IBAction) startGrowlAtLogin:(id)sender;

#pragma mark "Network" tab pane
- (IBAction) startGrowlServer:(id)sender;
- (IBAction) allowRemoteRegistration:(id)sender;
- (IBAction) setRemotePassword:(id)sender;
- (IBAction) setEnableForward:(id)sender;

- (IBAction) selectDisplayPlugin:(id)sender;
- (IBAction) deleteTicket:(id)sender;

#pragma mark "Display Options" tab pane
- (IBAction) showPreview:(id)sender;
- (void) loadViewForDisplay:(NSString*)displayName;

#pragma mark Notification table view data source methods
- (int) numberOfRowsInTableView:(NSTableView *)tableView;
- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row;
- (void) tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row;

#pragma mark -
- (IBAction) revert:(id)sender;
- (IBAction) apply:(id)sender;

- (void) setPrefsChanged:(BOOL)prefsChanged;
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void) checkGrowlRunning;
- (void) appRegistered: (NSNotification *) note;

@end
