//
//  GrowlPreferencePane.h
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <PreferencePanes/PreferencePanes.h>
#import "GrowlAbstractDatabase.h"

@class GrowlApplicationTicket, TicketsArrayController, GrowlPluginController, GrowlTicketController, GrowlPreferencesController, GrowlNotificationDatabase, GrowlPlugin, GrowlPositionPicker;

@interface GrowlPreferencePane : NSWindowController <NSNetServiceBrowserDelegate, NSWindowDelegate> {
	int                             pid;

	NSArray							*plugins;

	NSPreferencePane				*pluginPrefPane;
	NSMutableArray					*loadedPrefPanes;

	//Properties of the plugin being configured
	NSDictionary					*currentPlugin;
	GrowlPlugin						*currentPluginController;

	//cached controllers
	/*these are cached to avoid redundant calls to
	 *	[GrowlXController sharedController].
	 *though that method also caches its return value, we're dealing with
	 *	Bindings here, so we want to pick up all the speed boosts that we can.
	 */
   GrowlTicketController         *ticketController;
	GrowlPluginController			*pluginController;
	GrowlPreferencesController		*preferencesController;
    GrowlNotificationDatabase     *historyController;

   //Prefs list support
    IBOutlet NSToolbar              *toolbar;
   NSMutableDictionary              *prefViewControllers;
   
	//"Display Options" tab pane
	IBOutlet NSTableView			*displayPluginsTable;
	IBOutlet NSView					*displayPrefView;
	IBOutlet NSView					*displayDefaultPrefView;
	IBOutlet NSTextField			*displayAuthor;
	IBOutlet NSTextField			*displayVersion;
	IBOutlet NSButton				*previewButton;
	IBOutlet NSArrayController		*displayPluginsArrayController;
	
	IBOutlet NSWindow				*disabledDisplaysSheet;
	IBOutlet NSTextView				*disabledDisplaysList;

	//"Network" tab pane
	NSMutableArray					*services;
	NSNetServiceBrowser				*browser;
	int								currentServiceIndex;
    IBOutlet NSTableColumn          *serviceNameColumn;
	IBOutlet NSTableColumn			*servicePasswordColumn;
	IBOutlet NSTableView			*networkTableView;
   NSString                   *networkAddressString;
	
   //History tab pane
   IBOutlet NSSegmentedControl *historyOnOffSwitch;
   IBOutlet NSArrayController *historyArrayController;
   IBOutlet NSTableView       *historyTable;
   IBOutlet NSButton          *trimByCountCheck;
   IBOutlet NSButton          *trimByDateCheck;
}

- (NSString *) bundleVersion;

- (void) reloadPreferences:(NSString *)object;

#pragma mark Bindings accessors (not for programmatic use)

- (GrowlTicketController *) ticketController;
- (GrowlPluginController *) pluginController;
- (GrowlPreferencesController *) preferencesController;
- (GrowlNotificationDatabase *) historyController;

#pragma mark Toolbar support
-(void)setSelectedTab:(NSUInteger)tab;
-(IBAction)selectedTabChanged:(id)sender;

-(void) populateDisplaysPopUpButton:(NSPopUpButton *)popUp nameOfSelectedDisplay:(NSString *)nameOfSelectedDisplay includeDefaultMenuItem:(BOOL)includeDefault;
-(IBAction) showPreview:(id)sender;

#pragma mark "Network" tab pane
-(void)updateAddresses;
-(void)startBrowsing;
-(void)stopBrowsing;
- (IBAction) removeSelectedForwardDestination:(id)sender;
- (IBAction)newManualForwader:(id)sender;
- (void) writeForwardDestinations;

#pragma mark "Display Options" tab pane
- (IBAction) showDisabledDisplays:(id)sender;
- (IBAction) endDisabledDisplays:(id)sender;
- (BOOL)hasDisabledDisplays;

- (IBAction) showPreview:(id)sender;
- (void) loadViewForDisplay:(NSString*)displayName;

#pragma mark HistoryTab
- (IBAction) toggleHistory:(id)sender;
-(IBAction)validateHistoryTrimSetting:(id)sender;
- (IBAction) deleteSelectedHistoryItems:(id)sender;
- (IBAction) clearAllHistory:(id)sender;


#pragma mark Properties
@property (retain) NSSound *demoSound;
@property (retain) NSArray *displayPlugins;
@property (retain) NSMutableArray *services;
@property (retain) NSString *networkAddressString;

@end
