//
//  GrowlPref.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import "GrowlPref.h"
#import "GrowlDisplayProtocol.h"

@interface GrowlPref (PRIVATE)
- (NSDictionary *)growlHelperAppDescription;
@end

#define PING_TIMEOUT		3

@implementation GrowlPref

- (void) mainViewDidLoad {
	//load prefs and set IBOutlets accordingly
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	[defs addSuiteNamed:@"loginwindow"];
	
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(growlPonged:)
															name:GROWL_PONG 
														  object:nil];

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(appRegistered:)
															name:GROWL_APP_REGISTRATION_CONF
														  object:nil];
//	[self reloadPreferences];
//	[self pingGrowl];
}

- (void) willSelect {
	[self reloadPreferences];
	[self pingGrowl];
}

- (NSPreferencePaneUnselectReply)shouldUnselect {
	if(prefsHaveChanged) {
		NSBeginAlertSheet(@"Apply Changes?",@"Apply Changes",@"Discard Changes",@"Cancel",
								[[self mainView] window],self,@selector(sheetDidEnd:returnCode:contextInfo:),
								NULL,NULL,@"You have made changes, but have not applied them. Would you like to apply them, discard them, or cancel?");
		return NSUnselectLater;
	} else {
		return NSUnselectNow;
	}
}

- (void)reloadPreferences {
	if(tickets) [tickets release];
	tickets = [[GrowlApplicationTicket allSavedTickets] mutableCopy];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];

	[self loadViewForDisplay:nil];
	
	[growlApplications reloadData];
	if(currentApplication)
		[growlApplications selectRow:[applications indexOfObject:currentApplication] byExtendingSelection:NO];
	
	if ( [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLaunchedApplicationDictionary"] containsObject:[self growlHelperAppDescription]] ) 
		[startGrowlAtLogin setState:NSOnState];

	[allDisplayPlugins removeAllItems];
	[allDisplayPlugins addItemsWithTitles:[[GrowlPluginController controller] allDisplayPlugins]];
	[allDisplayPlugins selectItemWithTitle:[[GrowlPreferences preferences] objectForKey:GrowlDisplayPluginKey]];
	[displayPlugins reloadData];
	
	[self buildDisplayMenu];
	
	[self reloadAppTab];
	[self reloadDisplayTab];
	[self setPrefsChanged:NO];
}

- (void)buildDisplayMenu
{
	// Building Menu for the drop down one time.  It's cached from here on out.  If we want to add new display types
	// we'll have to call this method after the controller knows about it.
	NSEnumerator * enumerator;
	
	if (applicationDisplayPluginsMenu)
		[applicationDisplayPluginsMenu release];
	
	applicationDisplayPluginsMenu = [[NSMenu alloc] initWithTitle:@"DisplayPlugins"];
	enumerator = [[[GrowlPluginController controller] allDisplayPlugins] objectEnumerator];
	id title;
	[applicationDisplayPluginsMenu addItemWithTitle:@"Default" action:nil keyEquivalent:@""];
	[applicationDisplayPluginsMenu addItem:[NSMenuItem separatorItem]];
	while (title = [enumerator nextObject]) {
		[applicationDisplayPluginsMenu addItemWithTitle:title action:nil keyEquivalent:@""];
	}
}

- (void)updateRunningStatus {
	[startStopGrowl setEnabled:YES];
	[startStopGrowl setTitle:growlIsRunning?@"Stop Growl":@"Start Growl"];
	[growlRunningStatus setStringValue:growlIsRunning?@"Growl is running.":@"Growl is stopped"];
}

- (void)reloadAppTab {
	if(currentApplication) [currentApplication release];
//	currentApplication = [[growlApplications titleOfSelectedItem] retain];
	if (([growlApplications selectedRow] < 0) && ([[GrowlApplicationTicket allSavedTickets] count] > 0))
		[growlApplications selectRow:0 byExtendingSelection:NO];
	if ([[GrowlApplicationTicket allSavedTickets] count] > 0)
		currentApplication = [[applications objectAtIndex:[growlApplications selectedRow]] retain];
	appTicket = [tickets objectForKey: currentApplication];
	
//	[applicationEnabled setState: [appTicket ticketEnabled]];
//	[applicationEnabled setTitle: [NSString stringWithFormat:@"Enable notifications for %@",currentApplication]];
	
	[[[applicationNotifications tableColumnWithIdentifier:@"enable"] dataCell] setEnabled:[appTicket ticketEnabled]];
	[applicationNotifications reloadData];
	
	[growlApplications reloadData];
}

- (void)reloadDisplayTab {
	if (currentPlugin) [currentPlugin release];
	
	if (([displayPlugins selectedRow] < 0) && ([[[GrowlPluginController controller] allDisplayPlugins] count] > 0))
		[displayPlugins selectRow:0 byExtendingSelection:NO];
	
	if ([[[GrowlPluginController controller] allDisplayPlugins] count] > 0)
		currentPlugin = [[[[GrowlPluginController controller] allDisplayPlugins] objectAtIndex:[displayPlugins selectedRow]] retain];
	[self loadViewForDisplay:currentPlugin];
	NSDictionary * info = [[[GrowlPluginController controller] displayPluginNamed:currentPlugin] pluginInfo];
	[displayAuthor setStringValue:[info objectForKey:@"Author"]];
	[displayVersion setStringValue:[info objectForKey:@"Version"]];
}

#pragma mark "General" tab pane

- (IBAction) startStopGrowl:(id) sender {
		
	NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
	
	if(!growlIsRunning) {
		growlIsRunning = [[NSWorkspace sharedWorkspace] launchApplication:helperPath];
	} else {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN object:nil];
		growlIsRunning = NO;
	}
	[self updateRunningStatus];
}

- (IBAction) startGrowlAtLogin:(id) sender {
	NSUserDefaults *defs = [[[NSUserDefaults alloc] init] autorelease];
	[defs addSuiteNamed:@"loginwindow"];
	NSMutableDictionary *loginWindowPrefs = [[[defs persistentDomainForName:@"loginwindow"] mutableCopy] autorelease];
	NSMutableArray *loginItems = [[[loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy] autorelease]; //it lies, its an array
	NSDictionary *GHAdesc = [self growlHelperAppDescription];
	
	if ( [startGrowlAtLogin state] == NSOnState ) {
		[loginItems addObject:GHAdesc];
	} else {
		[loginItems removeObject:GHAdesc];
	}
	
	[loginWindowPrefs setObject:[NSArray arrayWithArray:loginItems] 
						 forKey:@"AutoLaunchedApplicationDictionary"];
	[defs setPersistentDomain:[NSDictionary dictionaryWithDictionary:loginWindowPrefs] 
					  forName:@"loginwindow"];
	[defs synchronize];	
}

- (IBAction)selectDisplayPlugin:(id)sender {
	[[GrowlPreferences preferences] setObject:[sender titleOfSelectedItem] forKey:GrowlDisplayPluginKey];
}

#pragma mark "Applications" tab pane
/*- (IBAction)enableApplication:(id)sender {
//	[appTicket setEnabled:[applicationEnabled state]];
	[self setPrefsChanged:YES];
	[self reloadAppTab];
}

- (IBAction)useCustomDisplayPlugin:(id)sender {
	[appTicket setUsesCustomDisplay:[sender state]];
	[applicationDisplayPlugins setEnabled:[sender state]];
	[self setPrefsChanged:YES];
}*/

/*- (IBAction)selectApplicationDisplayPlugin:(id)sender {
//	NSLog(@"titleOfSelectedItem %@", [sender titleOfSelectedItem]);
	[appTicket setDisplayPluginNamed:[sender titleOfSelectedItem]];
	[self setPrefsChanged:YES];
}*/

#pragma mark "Display Options" tab pane
//This is the frame of the preference view that we should get back.
#define DISPLAY_PREF_FRAME NSMakeRect(165., 20., 354., 289.)
- (void)loadViewForDisplay:(NSString*)displayName
{
	NSView *newView = nil;
	if (displayName != nil)
	{
		id <GrowlPlugin> plugin = [[GrowlPluginController controller]
														displayPluginNamed:displayName];
		newView = [plugin displayPrefView];
	}
	if (newView == nil) {
		newView = displayDefaultPrefView;
	}
	// Make sure the new view is framed correctly
	[newView setFrame:DISPLAY_PREF_FRAME];
	// Don't release displayPrefView - the replaceSubvview:with: does that already
	[[displayPrefView superview] replaceSubview:displayPrefView with:newView];
	displayPrefView = [newView retain];
}

#pragma mark Notification and Application table view data source methods

- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == growlApplications)
		return [[GrowlApplicationTicket allSavedTickets] count];
	if (tableView == applicationNotifications)
		return [[appTicket allNotifications] count];
	if (tableView == displayPlugins)
		return [[[GrowlPluginController controller] allDisplayPlugins] count];
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row {
	if (tableView == growlApplications) 	{
		if ([[column identifier] isEqualTo:@"enable"])
			return [NSNumber numberWithBool:[[tickets objectForKey: [applications objectAtIndex:row]] ticketEnabled]];
		if ([[column identifier] isEqualTo:@"application"])
			return [applications objectAtIndex:row];
		if ([[column identifier] isEqualTo:@"display"]) { } // Do nothing.  It's taken care of in a delegate method.
	}
	if (tableView == applicationNotifications) {
		NSString * note = [[appTicket allNotifications] objectAtIndex:row];
		if([[column identifier] isEqualTo:@"enable"]) {
			return [NSNumber numberWithBool:[appTicket isNotificationEnabled:note]];
		} else {
			return note;
		}
	}
	if (tableView == displayPlugins) {
		// only one column, but for the sake of cleanliness
		if ([[column identifier] isEqualTo:@"plugins"])
			return [[[GrowlPluginController controller] allDisplayPlugins] objectAtIndex:row];
	}
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row {
	if (tableView == growlApplications) {
		NSString * application = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:row];
		if ([[column identifier] isEqualTo:@"enable"]) {
			[[tickets objectForKey:application] setEnabled:[value boolValue]];
			[self setPrefsChanged:YES];
		}
		if ([[column identifier] isEqualTo:@"display"])	{
			if ([value intValue] == 0) {
				if ([[tickets objectForKey:application] usesCustomDisplay]) {
					[[tickets objectForKey:application] setUsesCustomDisplay:NO];
					[self setPrefsChanged:YES];
				}
			} else {
				if (![[[applicationDisplayPluginsMenu itemAtIndex:[value intValue]] title] isEqualTo:[[[tickets objectForKey:application] displayPlugin] name]] ||
					![[tickets objectForKey:application] usesCustomDisplay]) {
					[[tickets objectForKey:application] setUsesCustomDisplay:YES];
					[[tickets objectForKey:application] setDisplayPluginNamed:[[applicationDisplayPluginsMenu itemAtIndex:[value intValue]] title]];
					[self setPrefsChanged:YES];
				}
			}
		}
		[self reloadAppTab];
		return;
	}
	if (tableView == applicationNotifications) {
		NSString * note = [[appTicket allNotifications] objectAtIndex:row];
		if([value boolValue]) {
			[appTicket setNotificationEnabled:note];
		} else {
			[appTicket setNotificationDisabled:note];
		}
		[self setPrefsChanged:YES];
		return;
	}
	if (tableView == displayPlugins)
		return;
}

#pragma mark Application TableView delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)theNote {
	if ([theNote object] == growlApplications)
		return (void)[self reloadAppTab];
	if ([theNote object] == displayPlugins)
		return (void)[self reloadDisplayTab];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(int)row {
	if ((tableView == growlApplications) && [[column identifier] isEqualTo:@"display"]) {
		[cell setMenu:[applicationDisplayPluginsMenu copy]];
		if (![[tickets objectForKey: [applications objectAtIndex:row]] usesCustomDisplay])
			[cell selectItemAtIndex:0]; // Default
		else
			[cell selectItemWithTitle:[[[tickets objectForKey: [applications objectAtIndex:row]] displayPlugin] name]];
	}
}

#pragma mark -

- (IBAction)revert:(id)sender {
	[self reloadPreferences];
	[self setPrefsChanged:NO];
}

- (IBAction)apply:(id)sender {
	[[[tickets objectEnumerator] allObjects] makeObjectsPerformSelector:@selector(saveTicket)];
	[self setPrefsChanged:NO];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged object:nil];
}

- (void)setPrefsChanged:(BOOL)prefsChanged {
	prefsHaveChanged = prefsChanged;
	[apply setEnabled:prefsHaveChanged];
	[revert setEnabled:prefsHaveChanged];
}

- (void)dealloc {
	if(cachedGrowlHelperAppDescription)
		[cachedGrowlHelperAppDescription release];
	if(tickets) [tickets release];
	if(currentApplication) [currentApplication release];
}

- (NSDictionary *)growlHelperAppDescription {
	if(!cachedGrowlHelperAppDescription) {
		NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
		
		cachedGrowlHelperAppDescription = [[NSDictionary alloc] initWithObjectsAndKeys:
			helperPath, [NSString stringWithString:@"Path"],
			[NSNumber numberWithBool:NO], [NSString stringWithString:@"Hide"],
			nil];
	}
	return cachedGrowlHelperAppDescription;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if(returnCode == NSAlertDefaultReturn)
		[self apply:nil];
	[self replyToShouldUnselect:returnCode == NSAlertDefaultReturn || returnCode == NSAlertAlternateReturn];
}

#pragma mark Detecting Growl

- (void)pingGrowl {
	[startStopGrowl setEnabled:NO];
	[growlRunningStatus setStringValue:@"Looking for growl..."];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_PING object:nil];
	pingTimer = [NSTimer scheduledTimerWithTimeInterval:PING_TIMEOUT target:self selector:@selector(pingTimedOut:) userInfo:nil repeats:NO];
}

- (void)growlPonged:(NSNotification *) note {
	growlIsRunning = YES;
	if(pingTimer) {
		[pingTimer invalidate];
		pingTimer = nil;
	}
	[self updateRunningStatus];
}

- (void)pingTimedOut: (NSTimer *) timer {
	growlIsRunning = NO;
	pingTimer = nil;
	[self updateRunningStatus];
}

#pragma mark -

// Refresh preferences when a new application registers with Growl
- (void)appRegistered: (NSNotification *) note {
	NSString * app = [note object];
	GrowlApplicationTicket * ticket = [[[GrowlApplicationTicket alloc] initTicketForApplication:app] autorelease];

/*	if(![tickets objectForKey:app])
		[growlApplications addItemWithTitle:app];*/
	
	[tickets setObject:ticket forKey:app];
	[applications release];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
	[growlApplications reloadData];
	
	if([currentApplication isEqualToString:app])
		[self reloadPreferences];	
}

@end

