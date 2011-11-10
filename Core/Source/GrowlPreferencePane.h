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

@class GrowlPluginController, GrowlPreferencesController, GrowlNotificationDatabase, GrowlPrefsViewController;

@interface GrowlPreferencePane : NSWindowController <NSNetServiceBrowserDelegate, NSWindowDelegate> {
	//cached controllers
	/*these are cached to avoid redundant calls to
	 *	[GrowlXController sharedController].
	 *though that method also caches its return value, we're dealing with
	 *	Bindings here, so we want to pick up all the speed boosts that we can.
	 */
	GrowlPluginController			*pluginController;
	GrowlPreferencesController		*preferencesController;
    GrowlNotificationDatabase     *historyController;

   //Prefs list support
    IBOutlet NSToolbar              *toolbar;
   NSMutableDictionary              *prefViewControllers;
   GrowlPrefsViewController         *currentViewController;
	
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

- (GrowlPluginController *) pluginController;
- (GrowlPreferencesController *) preferencesController;
- (GrowlNotificationDatabase *) historyController;

#pragma mark Toolbar support
-(void)setSelectedTab:(NSUInteger)tab;
-(IBAction)selectedTabChanged:(id)sender;

-(void) populateDisplaysPopUpButton:(NSPopUpButton *)popUp nameOfSelectedDisplay:(NSString *)nameOfSelectedDisplay includeDefaultMenuItem:(BOOL)includeDefault;

#pragma mark HistoryTab
- (IBAction) toggleHistory:(id)sender;
-(IBAction)validateHistoryTrimSetting:(id)sender;
- (IBAction) deleteSelectedHistoryItems:(id)sender;
- (IBAction) clearAllHistory:(id)sender;


#pragma mark Properties
@property (retain) NSMutableArray *services;
@property (retain) NSString *networkAddressString;
@property (retain) GrowlPrefsViewController *currentViewController;

@end
