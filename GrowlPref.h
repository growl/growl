//
//  GrowlPref.h
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlPref : NSPreferencePane {
	NSDictionary			* cachedGrowlHelperAppDescription;
	
	NSDictionary			* tickets;
	
	//Properties of the app being configured
	NSString				* currentApplication;
	GrowlApplicationTicket	* appTicket;
	
	BOOL					growlIsRunning;
	BOOL					prefsHaveChanged;

	//"General" tab pane
	IBOutlet NSButton		* startGrowlAtLogin;
	IBOutlet NSButton		* startStopGrowl;
	IBOutlet NSTextField	* growlRunningStatus;
	
	//"Applications" tab pane
	IBOutlet NSPopUpButton	* growlApplications;
	IBOutlet NSButton		* applicationEnabled;
	IBOutlet NSTableView	* applicationNotifications;
	
	//Revert/Apply
	IBOutlet NSButton		* apply;
	IBOutlet NSButton		* revert;
}

- (void)reloadPreferences;
- (void)updateRunningStatus;
- (void)reloadAppTab;

//"General" tab pane
- (IBAction)startStopGrowl:(id)sender;
- (IBAction)startGrowlAtLogin:(id)sender;

//"Applications" tab pane
- (IBAction)selectApplication:(id)sender;
- (IBAction)enableApplication:(id)sender;

//Notification table view data source methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row;

- (IBAction)revert:(id)sender;
- (IBAction)apply:(id)sender;

- (void)setPrefsChanged:(BOOL)prefsChanged;

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
