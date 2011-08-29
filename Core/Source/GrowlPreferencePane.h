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

@class GrowlApplicationTicket, TicketsArrayController, GrowlPluginController, GrowlPreferencesController, GrowlNotificationDatabase, GrowlPlugin, GrowlPositionPicker;

@interface GrowlPreferencePane : NSWindowController <NSNetServiceBrowserDelegate, NSWindowDelegate> {
	int                             pid;

	NSMutableArray                  *images;
	NSMutableArray					*tickets;
	NSArray							*plugins;

	NSPreferencePane				*pluginPrefPane;
	NSMutableArray					*loadedPrefPanes;

	//Properties of the plugin being configured
	NSDictionary					*currentPlugin;
	GrowlPlugin						*currentPluginController;

	BOOL                            canRemoveTicket;

	//cached controllers
	/*these are cached to avoid redundant calls to
	 *	[GrowlXController sharedController].
	 *though that method also caches its return value, we're dealing with
	 *	Bindings here, so we want to pick up all the speed boosts that we can.
	 */
	GrowlPluginController			*pluginController;
	GrowlPreferencesController		*preferencesController;
    GrowlNotificationDatabase     *historyController;

    IBOutlet NSToolbar              *toolbar;
    
	//"General" tab pane
	IBOutlet NSArrayController		*notificationsArrayController;
	IBOutlet GrowlPositionPicker	*globalPositionPicker;
    IBOutlet NSSegmentedControl     *startAtLoginSwitch;

	//"Applications" tab pane
	IBOutlet NSTableView			*growlApplications;
	IBOutlet NSTableColumn			*applicationNameAndIconColumn;
	IBOutlet NSTabView				*applicationsTab;
	IBOutlet NSTabView				*configurationTab;
	NSTableView						*activeTableView;
	IBOutlet NSMenu					*notificationPriorityMenu;
	IBOutlet TicketsArrayController	*ticketsArrayController;
	IBOutlet GrowlPositionPicker	*appPositionPicker;
	IBOutlet NSPopUpButton			*soundMenuButton;
	IBOutlet NSPopUpButton			*displayMenuButton;
	IBOutlet NSPopUpButton			*notificationDisplayMenuButton;
	NSIndexSet						*selectedNotificationIndexes;

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
	
	//About box tab pane
	IBOutlet NSTextField			*aboutVersionString;
	IBOutlet NSTextView				*aboutBoxTextView;
   
   //History tab pane
   IBOutlet NSSegmentedControl *historyOnOffSwitch;
   IBOutlet NSArrayController *historyArrayController;
   IBOutlet NSTableView       *historyTable;
   IBOutlet NSButton          *trimByCountCheck;
   IBOutlet NSButton          *trimByDateCheck;
    
    NSSound                    *demoSound;
}

- (NSString *) bundleVersion;

- (void) reloadPreferences:(NSString *)object;

#pragma mark Bindings accessors (not for programmatic use)

- (GrowlPluginController *) pluginController;
- (GrowlPreferencesController *) preferencesController;
- (GrowlNotificationDatabase *) historyController;

#pragma mark Toolbar support
-(void)setSelectedTab:(NSUInteger)tab;
-(IBAction)selectedTabChanged:(id)sender;

#pragma mark "General" tab pane
-(IBAction)startGrowlAtLogin:(id)sender;
-(IBAction)launchAdditionalDownloads:(id)sender;

#pragma mark "Applications" tab pane
- (BOOL) canRemoveTicket;
- (void) setCanRemoveTicket:(BOOL)flag;
- (IBAction) deleteTicket:(id)sender;
- (IBAction)playSound:(id)sender;
- (IBAction) showApplicationConfigurationTab:(id)sender;
- (IBAction) changeNameOfDisplayForApplication:(id)sender;
- (IBAction) changeNameOfDisplayForNotification:(id)sender;
- (NSIndexSet *) selectedNotificationIndexes;
- (void) setSelectedNotificationIndexes:(NSIndexSet *)newSelectedNotificationIndexes;

#pragma mark "Network" tab pane
-(void)updateAddresses;
-(void)startBrowsing;
-(void)stopBrowsing;
- (IBAction) removeSelectedForwardDestination:(id)sender;
- (IBAction)newManualForwader:(id)sender;
- (void) writeForwardDestinations;

- (NSMutableArray *) services;
- (void) setServices:(NSMutableArray *)theServices;
- (NSUInteger) countOfServices;
- (void) insertObject:(id)anObject inServicesAtIndex:(unsigned)index;
- (void) replaceObjectInServicesAtIndex:(unsigned)index withObject:(id)anObject;

#pragma mark "Display Options" tab pane
- (IBAction) showDisabledDisplays:(id)sender;
- (IBAction) endDisabledDisplays:(id)sender;
- (BOOL)hasDisabledDisplays;

- (IBAction) showPreview:(id)sender;
- (void) loadViewForDisplay:(NSString*)displayName;

- (void) appRegistered: (NSNotification *) note;
- (IBAction) openGrowlWebSiteToStyles:(id)sender;

#pragma mark HistoryTab
- (IBAction) toggleHistory:(id)sender;
-(IBAction)validateHistoryTrimSetting:(id)sender;
- (IBAction) deleteSelectedHistoryItems:(id)sender;
- (IBAction) clearAllHistory:(id)sender;

#pragma mark About Tab methods
- (void) setupAboutTab;
- (IBAction) openGrowlWebSite:(id)sender;
- (IBAction) openGrowlBugSubmissionPage:(id)sender;

#pragma mark Properties
@property (retain) NSSound *demoSound;
@property (retain) NSArray *displayPlugins;
@property (retain) NSMutableArray *services;
@property (retain) NSString *networkAddressString;

@end
