//
//  GrowlPref.h
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <PreferencePanes/PreferencePanes.h>

@protocol GrowlPlugin;

@class GrowlApplicationTicket, TicketsArrayController;

@interface GrowlPref : NSPreferencePane {
	NSMutableArray					*images;
	NSMutableArray					*tickets;
	NSArray							*plugins;
	NSTimer							*startStopTimer;

	NSPreferencePane				*pluginPrefPane;
	NSMutableArray					*loadedPrefPanes;

	//Properties of the plugin being configured
	NSString						*currentPlugin;
	id <GrowlPlugin>				currentPluginController;

	BOOL							canRemoveTicket;
	BOOL							growlIsRunning;

	NSURL							*versionCheckURL;
	NSURL							*downloadURL;

	//"General" tab pane
	IBOutlet NSButton				*startStopGrowl;
	IBOutlet NSTextField			*growlRunningStatus;
	IBOutlet NSProgressIndicator	*growlRunningProgress;
	IBOutlet NSProgressIndicator	*growlVersionProgress;
	IBOutlet NSArrayController		*notificationsArrayController;
	IBOutlet NSButton				*menuExtraEnabled;
	
	// Logging
	IBOutlet NSMatrix				*logFileType;
	IBOutlet NSPopUpButton			*customMenuButton;	
	NSMutableArray					*customHistArray;

	//"Applications" tab pane
	IBOutlet NSTableView			*applicationNotifications;
	IBOutlet NSTableView			*growlApplications;
	NSTableView						*activeTableView;
	IBOutlet NSMenu					*notificationPriorityMenu;
	IBOutlet TicketsArrayController	*ticketsArrayController;

	//"Display Options" tab pane
	IBOutlet NSTableView			*displayPluginsTable;
	IBOutlet NSView					*displayPrefView;
	IBOutlet NSView					*displayDefaultPrefView;
	IBOutlet NSTextField			*displayAuthor;
	IBOutlet NSTextField			*displayVersion;
	IBOutlet NSButton				*previewButton;
	IBOutlet NSArrayController		*displayPluginsArrayController;

	//"Network" tab pane
	NSMutableArray					*services;
	NSNetServiceBrowser				*browser;
	NSNetService					*serviceBeingResolved;
	int								currentServiceIndex;
}

- (NSString *) bundleVersion;
- (IBAction) checkVersion:(id)sender;
- (void) checkVersionAtURL:(NSURL *)url displayText:(NSString *)message downloadURL:(NSURL *)goURL;
- (void) downloadSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void) reloadPreferences;
- (void) updateRunningStatus;

#pragma mark "Applications" tab pane
- (BOOL) canRemoveTicket;
- (void) setCanRemoveTicket:(BOOL)flag;
- (IBAction) deleteTicket:(id)sender;

#pragma mark "General" tab pane
- (IBAction) startStopGrowl:(id)sender;
- (BOOL) isStartGrowlAtLogin;
- (void) setStartGrowlAtLogin:(BOOL)flag;
- (BOOL) isBackgroundUpdateCheckEnabled;
- (void) setIsBackgroundUpdateCheckEnabled:(BOOL)flag;
- (NSString *) defaultDisplayPluginName;
- (void) setDefaultDisplayPluginName:(NSString *)name;
- (BOOL) loggingEnabled;
- (void) setLoggingEnabled:(BOOL)flag;

- (IBAction) menuExtraStateChange:(id)sender;
- (IBAction) logTypeChanged:(id)sender;
- (IBAction) openConsoleApp:(id)sender;
- (IBAction) customFileChosen:(id)sender;
- (void) updateLogPopupMenu;

#pragma mark "Network" tab pane
- (BOOL) isGrowlServerEnabled;
- (void) setGrowlServerEnabled:(BOOL)enabled;
- (BOOL) isRemoteRegistrationAllowed;
- (void) setRemoteRegistrationAllowed:(BOOL)flag;
- (BOOL) isForwardingEnabled;
- (void) setForwardingEnabled:(BOOL)enabled;
- (NSString *) remotePassword;
- (void) setRemotePassword:(NSString *)value;
- (int) UDPPort;
- (void) setUDPPort:(int)value;

- (IBAction) resolveService:(id)sender;
- (void) writeForwardDestinations;

- (NSMutableArray *) services;
- (void) setServices:(NSMutableArray *)theServices;
- (unsigned) countOfServices;
- (void) insertObject:(id)anObject inServicesAtIndex:(unsigned)index;
- (void) replaceObjectInServicesAtIndex:(unsigned)index withObject:(id)anObject;

#pragma mark "Display Options" tab pane
- (IBAction) showPreview:(id)sender;
- (void) loadViewForDisplay:(NSString*)displayName;

- (NSArray *) displayPlugins;
- (void) setDisplayPlugins:(NSArray *)thePlugins;

#pragma mark -
- (void) checkGrowlRunning;
- (void) appRegistered: (NSNotification *) note;

extern OSStatus CoreMenuExtraAddMenuExtra (CFURLRef inMenuExtra, SInt32 position, UInt32 reserved, UInt8 *inData, UInt32 inSize, UInt32 *outExtra);
// either inExtra or inBundleID can be 0 or nil, but not both
extern OSStatus CoreMenuExtraRemoveMenuExtra (UInt32 inExtra, CFStringRef inBundleID);
extern OSStatus CoreMenuExtraGetMenuExtra (CFStringRef inBundleID, UInt32 *outExtra);

@end
