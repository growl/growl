//
//  GrowlPref.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import "GrowlPref.h"

#define HELPER_APP_BUNDLE_ID @"com.Growl.GrowlHelperApp"

@interface GrowlPref (PRIVATE)
- (NSDictionary *)growlHelperAppDescription;
@end


@implementation GrowlPref

- (void) mainViewDidLoad {
	//load prefs and set IBOutlets accordingly
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	[defs addSuiteNamed:@"loginwindow"];
	
	[self reloadPreferences];
}

#warning This should (somehow) automatically reload, not just on reopen
- (void) willSelect {
	[self reloadPreferences];
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
	
	#warning There has *got* to be a better way to do this!
	growlIsRunning = system("killall -s GrowlHelperApp") == 0;
		
	[self updateRunningStatus];

	if(tickets) [tickets release];
	tickets = [[GrowlApplicationTicket allSavedTickets] retain];
	
	[growlApplications removeAllItems];
	enumerator = [tickets keyEnumerator];
	[growlApplications addItemsWithTitles:[enumerator allObjects]];
	
	if(currentApplication)
		[growlApplications selectItemWithTitle:currentApplication];
	
	[self reloadAppTab];
	
	if ( [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutoLaunchedApplicationDictionary"] containsObject:[self growlHelperAppDescription]] ) 
		[startGrowlAtLogin setState:NSOnState];
	
	[self setPrefsChanged:NO];
}

- (void)updateRunningStatus {
	[startStopGrowl setTitle:growlIsRunning?@"Stop Growl":@"Start Growl"];
	[growlRunningStatus setStringValue:growlIsRunning?@"Growl is running.":@"Growl is stopped"];
}

- (void)reloadAppTab {
	currentApplication = [growlApplications titleOfSelectedItem];

	appTicket = [tickets objectForKey: currentApplication];
	
	[applicationEnabled setState: [appTicket ticketEnabled]];
	[applicationEnabled setTitle: [NSString stringWithFormat:@"Enable notifications for %@",currentApplication]];
	
	[applicationNotifications setEnabled:[appTicket ticketEnabled]];
	[applicationNotifications reloadData];
}

#pragma mark "General" tab pane
- (IBAction) startStopGrowl:(id) sender {
		
	NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
	
	if(!growlIsRunning) {
		growlIsRunning = [[NSWorkspace sharedWorkspace] launchApplication:helperPath];
	} else {
		#warning There has *got* to be a better way to do this
		system("killall GrowlHelperApp");
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
	
	[self setPrefsChanged:YES];
}

#pragma mark "Applications" tab pane
- (IBAction)selectApplication:(id)sender {
	if(![[sender titleOfSelectedItem] isEqualToString:currentApplication]) {
		[self reloadAppTab];
	}
}

- (IBAction)enableApplication:(id)sender {
	[appTicket setEnabled:[applicationEnabled state]];
	[applicationNotifications setEnabled:[applicationEnabled state]];
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
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlReloadPreferences" object:nil];
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

@end

