//
//  GrowlPref.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import "GrowlPref.h"

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
	[self reloadPreferences];
	[self pingGrowl];
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
	NSEnumerator * enumerator;
	
	if(tickets) [tickets release];
	tickets = [[GrowlApplicationTicket allSavedTickets] mutableCopy];
	
	[growlApplications removeAllItems];
	enumerator = [tickets keyEnumerator];
	[growlApplications addItemsWithTitles:[enumerator allObjects]];
	
	if(currentApplication)
		[growlApplications selectItemWithTitle:currentApplication];
	
	if ( [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLaunchedApplicationDictionary"] containsObject:[self growlHelperAppDescription]] ) 
		[startGrowlAtLogin setState:NSOnState];
	
	[allDisplayPlugins removeAllItems];
	[allDisplayPlugins addItemsWithTitles:[[GrowlPluginController controller] allDisplayPlugins]];
	[allDisplayPlugins selectItemWithTitle:[[GrowlPreferences preferences] objectForKey:GrowlDisplayPluginKey]];	
	
	[applicationDisplayPlugins removeAllItems];
	[applicationDisplayPlugins addItemsWithTitles:[[GrowlPluginController controller] allDisplayPlugins]];
	
	[self reloadAppTab];
	[self setPrefsChanged:NO];
}

- (void)updateRunningStatus {
	[startStopGrowl setEnabled:YES];
	[startStopGrowl setTitle:growlIsRunning?@"Stop Growl":@"Start Growl"];
	[growlRunningStatus setStringValue:growlIsRunning?@"Growl is running.":@"Growl is stopped"];
}

- (void)reloadAppTab {
	if(currentApplication) [currentApplication release];
	currentApplication = [[growlApplications titleOfSelectedItem] retain];

	appTicket = [tickets objectForKey: currentApplication];
	
	[applicationEnabled setState: [appTicket ticketEnabled]];
	[applicationEnabled setTitle: [NSString stringWithFormat:@"Enable notifications for %@",currentApplication]];
	
	[[[applicationNotifications tableColumnWithIdentifier:@"enable"] dataCell] setEnabled:[appTicket ticketEnabled]];
	[applicationNotifications reloadData];
	
	[applicationUseCustomDisplayPlugin setState:[appTicket usesCustomDisplay]];
	
	[applicationDisplayPlugins setEnabled:[appTicket usesCustomDisplay]];
	if(![appTicket displayPlugin])
		[appTicket setDisplayPluginNamed:[applicationDisplayPlugins titleOfSelectedItem]];
	else
		[applicationDisplayPlugins selectItemWithTitle:[[appTicket displayPlugin] name]];
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
- (IBAction)selectApplication:(id)sender {
	if(![[sender titleOfSelectedItem] isEqualToString:currentApplication]) {
		[self reloadAppTab];
	}
}

- (IBAction)enableApplication:(id)sender {
	[appTicket setEnabled:[applicationEnabled state]];
	[self setPrefsChanged:YES];
	[self reloadAppTab];
}

- (IBAction)useCustomDisplayPlugin:(id)sender {
	[appTicket setUsesCustomDisplay:[sender state]];
	[applicationDisplayPlugins setEnabled:[sender state]];
	[self setPrefsChanged:YES];
}

- (IBAction)selectApplicationDisplayPlugin:(id)sender {
	[appTicket setDisplayPluginNamed:[sender titleOfSelectedItem]];
	[self setPrefsChanged:YES];
}

#pragma mark Notification table view data source methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[appTicket allNotifications] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row {
	NSString * note = [[appTicket allNotifications] objectAtIndex:row];
	if([[column identifier] isEqualTo:@"enable"]) {
		return [NSNumber numberWithBool:[appTicket isNotificationEnabled:note]];
	} else {
		return note;
	}
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row {
	NSString * note = [[appTicket allNotifications] objectAtIndex:row];
	if([value boolValue]) {
		[appTicket setNotificationEnabled:note];
	} else {
		[appTicket setNotificationDisabled:note];
	}
	[self setPrefsChanged:YES];
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

//Refresh preferences when a new application registers with Growl
- (void)appRegistered: (NSNotification *) note {
	NSString * app = [note object];
	GrowlApplicationTicket * ticket = [[[GrowlApplicationTicket alloc] initTicketForApplication:app] autorelease];

	if(![tickets objectForKey:app])
		[growlApplications addItemWithTitle:app];
	
	[tickets setObject:ticket forKey:app];
	
	if([currentApplication isEqualToString:app])
		[self reloadPreferences];	
}

@end

