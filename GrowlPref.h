//
//  GrowlPref.h
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlPref : NSPreferencePane {
	NSDictionary			* cachedGrowlHelperAppDescription;
	NSMutableDictionary		* tickets;
	NSMutableArray			* applications;
	NSTimer					* pingTimer;
	
	//Properties of the app being configured
	NSString				* currentApplication;
	GrowlApplicationTicket	* appTicket;

	//Properties of the plugin being configured
	NSString				* currentPlugin;
	id						* displayPrefController;
	
	BOOL					growlIsRunning;
	BOOL					prefsHaveChanged;

	//"General" tab pane
	IBOutlet NSButton		* startGrowlAtLogin;
	IBOutlet NSButton		* startStopGrowl;
	IBOutlet NSTextField	* growlRunningStatus;
	IBOutlet NSPopUpButton	* allDisplayPlugins;
	
	//"Applications" tab pane
	IBOutlet NSTableView	* applicationNotifications;
	IBOutlet NSTableView	* growlApplications;
	NSMenu					* applicationDisplayPluginsMenu;
	
	//"Display Options" tab pane
	IBOutlet NSTableView	* displayPlugins;
	IBOutlet NSView			* displayPrefView;
	IBOutlet NSView			* displayDefaultPrefView;
	
	IBOutlet NSButton		* apply;
	IBOutlet NSButton		* revert;
}

- (void)reloadPreferences;
- (void)updateRunningStatus;
- (void)reloadAppTab;
- (void)reloadDisplayTab;
- (void)buildDisplayMenu;

#pragma mark "General" tab pane
- (IBAction)startStopGrowl:(id)sender;
- (IBAction)startGrowlAtLogin:(id)sender;

- (IBAction)selectDisplayPlugin:(id)sender;

#pragma mark "Applications" tab pane
//- (IBAction)selectApplication:(id)sender;
//- (IBAction)enableApplication:(id)sender;

//- (IBAction)useCustomDisplayPlugin:(id)sender;
//- (IBAction)selectApplicationDisplayPlugin:(id)sender;

#pragma mark "Display Options" tab pane
- (void)loadViewForDisplay:(NSString*)displayName;

#pragma mark Notification table view data source methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row;

#pragma mark -
- (IBAction)revert:(id)sender;
- (IBAction)apply:(id)sender;

- (void)setPrefsChanged:(BOOL)prefsChanged;

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)pingGrowl;
- (void)growlPonged: (NSNotification *) note;
- (void)pingTimedOut: (NSTimer *) timer;

- (void)appRegistered: (NSNotification *) note;

@end
