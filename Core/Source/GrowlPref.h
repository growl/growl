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

@class GrowlApplicationTicket;

@interface GrowlPref : NSPreferencePane {
	NSMutableArray					*images;
	NSMutableDictionary				*tickets;
	NSMutableArray					*applications;
	NSMutableArray					*filteredApplications;
	NSArray							*plugins;
	NSTimer							*startStopTimer;

	NSPreferencePane				*pluginPrefPane;
	NSMutableArray					*loadedPrefPanes;

	//Properties of the app being configured
	NSString						*currentApplication;
	GrowlApplicationTicket			*appTicket;

	//Properties of the plugin being configured
	NSString						*currentPlugin;
	id <GrowlPlugin>				currentPluginController;

	BOOL							growlIsRunning;

	NSURL							*versionCheckURL;
	NSURL							*downloadURL;

	IBOutlet NSTabView				*tabView;

	//"General" tab pane
	BOOL							startGrowlAtLogin;
	BOOL							backgroundUpdateCheckEnabled;
	IBOutlet NSButton				*startStopGrowl;
	IBOutlet NSTextField			*growlRunningStatus;
	IBOutlet NSProgressIndicator	*growlRunningProgress;
	IBOutlet NSPopUpButton			*allDisplayPlugins;
	IBOutlet NSTextField			*growlVersion;
	IBOutlet NSProgressIndicator	*growlVersionProgress;

	//"Applications" tab pane
	IBOutlet NSTableView			*applicationNotifications;
	IBOutlet NSTableView			*growlApplications;
	NSMenu							*applicationDisplayPluginsMenu;
	NSTableView						*activeTableView;
	IBOutlet NSMenu					*notificationPriorityMenu;
	IBOutlet NSTextField			*searchField;
	IBOutlet NSButton				*remove;

	//"Display Options" tab pane
	IBOutlet NSTableView			*displayPlugins;
	IBOutlet NSView					*displayPrefView;
	IBOutlet NSView					*displayDefaultPrefView;
	IBOutlet NSTextField			*displayAuthor;
	IBOutlet NSTextField			*displayVersion;

	//"Network" tab pane
	IBOutlet NSSecureTextField		*networkPassword;
	IBOutlet NSTableView			*growlServiceList;
	BOOL							growlServerEnabled;
	BOOL							remoteRegistrationAllowed;
	BOOL							forwardingEnabled;

	NSMutableArray					*services;
	NSNetServiceBrowser				*browser;
	NSNetService					*serviceBeingResolved;
	int								currentServiceIndex;
}

+ (void)saveTicket:(GrowlApplicationTicket *)ticket;

- (NSString *) bundleVersion;
- (IBAction) checkVersion:(id)sender;
- (void) checkVersionAtURL:(NSURL *)url displayText:(NSString *)message downloadURL:(NSURL *)goURL;
- (void) downloadSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void) reloadPreferences;
- (void) updateRunningStatus;
- (void) reloadAppTab;
- (void) reloadDisplayTab;
- (void) buildMenus;
- (void) filterApplications;
- (IBAction) search:(id)sender;

#pragma mark "General" tab pane
- (IBAction) startStopGrowl:(id)sender;
- (BOOL) isStartGrowlAtLogin;
- (void) setStartGrowlAtLogin:(BOOL)flag;
- (BOOL) isBackgroundUpdateCheckEnabled;
- (void) setBackgroundUpdateCheckEnabled:(BOOL)flag;

#pragma mark "Network" tab pane
- (BOOL) isGrowlServerEnabled;
- (void) setGrowlServerEnabled:(BOOL)enabled;
- (BOOL) isRemoteRegistrationAllowed;
- (void) setRemoteRegistrationAllowed:(BOOL)flag;
- (IBAction) setRemotePassword:(id)sender;
- (BOOL) isForwardingEnabled;
- (void) setForwardingEnabled:(BOOL)enabled;

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
- (void) checkGrowlRunning;
- (void) appRegistered: (NSNotification *) note;

@end
