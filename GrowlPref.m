//
//  GrowlPref.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import "GrowlPref.h"
#import "GrowlDisplayProtocol.h"
#import "ACImageAndTextCell.h"
#import <ApplicationServices/ApplicationServices.h>

#define PING_TIMEOUT		3

@interface GrowlPref (GrowlPrefPrivate)
- (BOOL)_isGrowlRunning;
@end

@implementation GrowlPref

- (id) initWithBundle:(NSBundle *)bundle {
	if (self = [super initWithBundle:bundle]) {
		pluginPrefPane = nil;
		tickets = nil;
		currentApplication = nil;
		loadedPrefPanes = [[NSMutableArray alloc] init];
		startStopTimer = nil;
		NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(growlLaunched:) name:GROWL_IS_READY object:nil];
		[nc addObserver:self selector:@selector(growlTerminated:) name:GROWL_SHUTDOWN object:nil];
	}
	return self;
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[pluginPrefPane release];
	[loadedPrefPanes release];
	[tickets release];
	[currentApplication release];
	[startStopTimer release];
	[super dealloc];
}

- (void)awakeFromNib {
	NSTableColumn* tableColumn = [growlApplications tableColumnWithIdentifier: @"application"];
	ACImageAndTextCell* imageAndTextCell = [[[ACImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable: YES];
	[tableColumn setDataCell:imageAndTextCell];
	NSButtonCell *cell = [[applicationNotifications tableColumnWithIdentifier:@"sticky"] dataCell];
	[cell setAllowsMixedState:YES];
	[growlRunningProgress setDisplayedWhenStopped:NO];
}

- (void) mainViewDidLoad {
	/*[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(growlPonged:)
															name:GROWL_PONG 
														  object:nil];*/

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(appRegistered:)
															name:GROWL_APP_REGISTRATION_CONF
														  object:nil];
//	[self reloadPreferences];
//	[self pingGrowl];
}

- (void) willSelect {
	[self reloadPreferences];
	//[self pingGrowl];
	[self checkGrowlRunning];
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
	
	[startGrowlAtLogin setState:NSOffState];
	NSUserDefaults *defs = [[NSUserDefaults alloc] init];
	NSArray *autoLaunchArray = [[defs persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"];
	NSEnumerator *e = [autoLaunchArray objectEnumerator];
	NSDictionary *item;
	while (item = [e nextObject]) {
		if ([[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString:[[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"]]) {
			[startGrowlAtLogin setState:NSOnState];
			break;
		}
	}
	[defs release];

	[allDisplayPlugins removeAllItems];
	[allDisplayPlugins addItemsWithTitles:[[GrowlPluginController controller] allDisplayPlugins]];
	[allDisplayPlugins selectItemWithTitle:[[GrowlPreferences preferences] objectForKey:GrowlDisplayPluginKey]];
	[displayPlugins reloadData];
	
	[self buildMenus];
	
	[self reloadAppTab];
	[self reloadDisplayTab];
	[self setPrefsChanged:NO];
}

- (void)buildMenus
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
	
	if (notificationPriorityMenu)
		[notificationPriorityMenu release];
	notificationPriorityMenu = [[NSMenu alloc] initWithTitle:@"Priority"];
	[notificationPriorityMenu addItemWithTitle:@"Very Low" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Moderate" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Normal" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"High" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Emergency" action:nil keyEquivalent:@""];
}

- (void)updateRunningStatus {
	[startStopTimer invalidate];
	startStopTimer = nil;
	[startStopGrowl setEnabled:YES];
	[startStopGrowl setTitle:growlIsRunning?@"Stop Growl":@"Start Growl"];
	[growlRunningStatus setStringValue:growlIsRunning?@"Growl is running.":@"Growl is stopped"];
	[growlRunningProgress stopAnimation:self];
}

- (void)reloadAppTab {
	[currentApplication release]; currentApplication = nil;
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
	
	// Make sure growlIsRunning is correct
	if (growlIsRunning != [self _isGrowlRunning]) {
		// Nope - lets just flip it and update status
		growlIsRunning = !growlIsRunning;
		[self updateRunningStatus];
		return;
	}
	
	if(!growlIsRunning) {
		//growlIsRunning = [[NSWorkspace sharedWorkspace] launchApplication:helperPath];
		[startStopGrowl setEnabled:NO];
		[growlRunningStatus setStringValue:[NSString stringWithUTF8String:"Launching Growl…"]];
		[growlRunningProgress startAnimation:self];
		// We want to launch in background, so we have to resort to Carbon
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus status = FSPathMakeRef([helperPath fileSystemRepresentation], &appRef, NULL);
		if (status == noErr) {
			spec.appRef = &appRef;
			spec.numDocs = 0;
			spec.itemRefs = NULL;
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchNoParams | kLSLaunchAsync | kLSLaunchDontSwitch;
			spec.asyncRefCon = NULL;
			status = LSOpenFromRefSpec(&spec, NULL);
		}
		//growlIsRunning = (status == noErr);
	} else {
		[startStopGrowl setEnabled:NO];
		[growlRunningStatus setStringValue:[NSString stringWithUTF8String:"Terminating Growl…"]];
		[growlRunningProgress startAnimation:self];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN object:nil];
		//growlIsRunning = NO;
	}
	//[self updateRunningStatus];
	// After 5 seconds update status, in case growl didn't start/stop
	startStopTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self
													selector:@selector(startStopTimeout:)
													userInfo:nil repeats:NO];
}

- (void) startStopTimeout:(NSTimer *)timer {
	timer = nil;
	[self checkGrowlRunning];
}

- (IBAction) startGrowlAtLogin:(id) sender {
	NSUserDefaults *defs = [[NSUserDefaults alloc] init];
	NSString *appPath = [[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
	NSMutableDictionary *loginWindowPrefs = [[[defs persistentDomainForName:@"loginwindow"] mutableCopy] autorelease];
	NSArray *loginItems = [loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"];
	NSMutableArray *mutableLoginItems = [[loginItems mutableCopy] autorelease];
	NSEnumerator *e = [loginItems objectEnumerator];
	NSDictionary *item;
	while (item = [e nextObject]) {
		if ([[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString:appPath]) {
			[mutableLoginItems removeObject:item];
		}
	}
	
	if ( [startGrowlAtLogin state] == NSOnState ) {
		NSMutableDictionary *launchDict = [NSMutableDictionary dictionary];
		[launchDict setObject:[NSNumber numberWithBool:NO] forKey:@"Hide"];
		[launchDict setObject:appPath forKey:@"Path"];
		[mutableLoginItems addObject:launchDict];
	}
	
	[loginWindowPrefs setObject:[NSArray arrayWithArray:mutableLoginItems] 
						 forKey:@"AutoLaunchedApplicationDictionary"];
	[defs setPersistentDomain:[NSDictionary dictionaryWithDictionary:loginWindowPrefs] 
					  forName:@"loginwindow"];
	[defs synchronize];
	[defs release];
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
#define DISPLAY_PREF_FRAME NSMakeRect(165., 42., 354., 289.)
- (void)loadViewForDisplay:(NSString*)displayName
{
	NSView *newView = nil;
	NSPreferencePane *prefPane = nil, *oldPrefPane = nil;
	if (pluginPrefPane) {
		oldPrefPane = pluginPrefPane;
	}
	if (displayName != nil)
	{
		id <GrowlPlugin> plugin = [[GrowlPluginController controller]
														displayPluginNamed:displayName];
		// Old plugins won't support the new protocol. Check first
		if ([plugin respondsToSelector:@selector(preferencePane)]) {
			prefPane = [plugin preferencePane];
		}
		if (prefPane == pluginPrefPane) {
			// Don't bother swapping anything
			return;
		} else {
			pluginPrefPane = prefPane;
			[oldPrefPane willUnselect];
		}
		if (pluginPrefPane) {
			if ([loadedPrefPanes containsObject:pluginPrefPane]) {
				newView = [pluginPrefPane mainView];
			} else {
				newView = [pluginPrefPane loadMainView];
				[loadedPrefPanes addObject:pluginPrefPane];
			}
			[pluginPrefPane willSelect];
		}
	} else {
		pluginPrefPane = nil;
	}
	if (newView == nil) {
		newView = displayDefaultPrefView;
	}
	if (displayPrefView != newView) {
		// Make sure the new view is framed correctly
		[newView setFrame:DISPLAY_PREF_FRAME];
		[[displayPrefView superview] replaceSubview:displayPrefView with:newView];
		displayPrefView = newView;
		if (pluginPrefPane) {
			[pluginPrefPane didSelect];
			// Hook up key view chain
			[displayPlugins setNextKeyView:[pluginPrefPane firstKeyView]];
			[[pluginPrefPane lastKeyView] setNextKeyView:tabView];
			[[displayPlugins window] makeFirstResponder:[pluginPrefPane initialKeyView]];
		} else {
			[displayPlugins setNextKeyView:tabView];
		}
		if (oldPrefPane) {
			[oldPrefPane didUnselect];
		}
	}
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
		if ([[column identifier] isEqualTo:@"enable"])
			return [NSNumber numberWithBool:[appTicket isNotificationEnabled:note]];
        if ([[column identifier] isEqualTo:@"notification"])
			return note;
		if ([[column identifier] isEqualTo:@"sticky"])
			return [NSNumber numberWithInt:[appTicket stickyForNotification:note]];
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
		if ([[column identifier] isEqualTo:@"enable"]) {
			if([value boolValue]) {
				[appTicket setNotificationEnabled:note];
			} else {
				[appTicket setNotificationDisabled:note];
			}
			[self setPrefsChanged:YES];
			return;
		}
		if ([[column identifier] isEqualTo:@"priority"]) {
			[appTicket setPriority:([value intValue]-2) forNotification:note];
			[self setPrefsChanged:YES];
			return;
		}
		if ([[column identifier] isEqualTo:@"sticky"]) {
            [appTicket setSticky:[value intValue] forNotification:note];
			[self setPrefsChanged:YES];
			return;
		}
	}
	if (tableView == displayPlugins)
		return;
}

#pragma mark Application Tab TableView delegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)theNote {
	if ([theNote object] == growlApplications)
		return (void)[self reloadAppTab];
	if ([theNote object] == displayPlugins)
		return (void)[self reloadDisplayTab];
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(int)row {
	if (tableView == growlApplications) {
		if ([[column identifier] isEqualTo:@"display"]) {
			[cell setMenu:[applicationDisplayPluginsMenu copy]];
			if (![[tickets objectForKey: [applications objectAtIndex:row]] usesCustomDisplay])
				[cell selectItemAtIndex:0]; // Default
			else
				[cell selectItemWithTitle:[[[tickets objectForKey: [applications objectAtIndex:row]] displayPlugin] name]];
			return;
		}
		if ([[column identifier] isEqualTo:@"application"]) {
			NSImage* icon = [[tickets objectForKey: [applications objectAtIndex:row]] icon];
			[icon setScalesWhenResized:YES];
			[icon setSize:NSMakeSize(16,16)];
			[(ACImageAndTextCell*)cell setImage:icon];
			return;
		}
		return;
	}
	if (tableView == applicationNotifications) {
		if ([[column identifier] isEqualTo:@"priority"]) {
			[cell setMenu:[notificationPriorityMenu copy]];
			int priority = [appTicket priorityForNotification:[[appTicket allNotifications] objectAtIndex:row]];
			[cell selectItemAtIndex:priority+2];
			return;
		}
		return;
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

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if(returnCode == NSAlertDefaultReturn)
		[self apply:nil];
	[self replyToShouldUnselect:returnCode == NSAlertDefaultReturn || returnCode == NSAlertAlternateReturn];
}

#pragma mark Detecting Growl

/*- (void)pingGrowl {
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
}*/

- (void)checkGrowlRunning {
	growlIsRunning = [self _isGrowlRunning];
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

- (void)growlLaunched:(NSNotification *)note {
	growlIsRunning = YES;
	[self updateRunningStatus];
}

- (void)growlTerminated:(NSNotification *)note {
	growlIsRunning = NO;
	[self updateRunningStatus];
}

#pragma mark -
#pragma mark Private
- (BOOL)_isGrowlRunning {
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = {kNoProcess, kNoProcess};
	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		if ([[infoDict objectForKey:@"CFBundleIdentifier"] isEqualToString:@"com.Growl.GrowlHelperApp"]) {
			isRunning = YES;
			[infoDict release];
			break;
		}
		[infoDict release];
	}
	
	return isRunning;
}

@end

