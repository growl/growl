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

@interface GrowlPref (GrowlPrefPrivate)
- (BOOL) _isGrowlRunning;
@end

@implementation GrowlPref

- (id) initWithBundle:(NSBundle *)bundle {
	if ( self = [super initWithBundle:bundle] ) {
		pluginPrefPane	= nil;
		tickets			= nil;
		currentApplication = nil;
		loadedPrefPanes = [[NSMutableArray alloc] init];
		startStopTimer = nil;
		NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		
		NSString *uniqueName = [NSString stringWithFormat:@"GrowlPreferencesAdministrativeConnection-%@", NSUserName()];
		growlProxy = [[NSConnection rootProxyForConnectionWithRegisteredName:uniqueName host:nil] retain];
		NSLog( @"got %@ for growl", growlProxy );
		
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
	
	pluginPrefPane = nil;
	loadedPrefPanes = nil;
	tickets = nil;
	currentApplication = nil;
	startStopTimer = nil;
	
	[super dealloc];
}

- (void) awakeFromNib {
	NSTableColumn* tableColumn = [growlApplications tableColumnWithIdentifier: @"application"];
	ACImageAndTextCell* imageAndTextCell = [[[ACImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable: YES];
	[tableColumn setDataCell:imageAndTextCell];
	
	NSButtonCell *cell = [[applicationNotifications tableColumnWithIdentifier:@"sticky"] dataCell];
	[cell setAllowsMixedState:YES];
	[growlRunningProgress setDisplayedWhenStopped:NO];
}

#pragma mark -

- (void) mainViewDidLoad {

	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(appRegistered:)
															name:GROWL_APP_REGISTRATION_CONF
														  object:nil];
}

- (void) willSelect {
	[self reloadPreferences];
	[self checkGrowlRunning];
}

- (NSPreferencePaneUnselectReply) shouldUnselect {
	if( prefsHaveChanged ) {
		NSBeginAlertSheet( @"Apply Changes?",
						   @"Apply Changes",
						   @"Discard Changes",
						   @"Cancel",
						   [[self mainView] window],
						   self,
						   @selector(sheetDidEnd:returnCode:contextInfo:),
						   NULL,
						   NULL,
						   @"You have made changes, but have not applied them. Would you like to apply them, discard them, or cancel?");
		return NSUnselectLater;
	} else {
		return NSUnselectNow;
	}
}

- (void) reloadPreferences {
	if ( tickets ) [tickets release];
	
	tickets = [[GrowlApplicationTicket allSavedTickets] mutableCopy];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];

	[self loadViewForDisplay:nil];
	[growlApplications reloadData];
	
	if ( currentApplication ) {
		[growlApplications selectRow:[applications indexOfObject:currentApplication] 
				byExtendingSelection:NO];
	}
	
	[startGrowlAtLogin setState:NSOffState];
	NSUserDefaults *defs = [[NSUserDefaults alloc] init];
	NSArray *autoLaunchArray = [[defs persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"];
	NSEnumerator *e = [autoLaunchArray objectEnumerator];
	NSDictionary *item;
	
	while ( item = [e nextObject] ) {
		if ( [[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString:[[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"]] ) {
			[startGrowlAtLogin setState:NSOnState];
			break;
		}
	}
	[defs release];

	[allDisplayPlugins removeAllItems];
	[allDisplayPlugins addItemsWithTitles:[growlProxy allDisplayPlugins]];
	[allDisplayPlugins selectItemWithTitle:[growlProxy objectForKey:GrowlDisplayPluginKey]];
	[displayPlugins reloadData];
	
	[self buildMenus];
	
	[self reloadAppTab];
	[self reloadDisplayTab];
	[self setPrefsChanged:NO];
}

- (void) buildMenus {
	// Building Menu for the drop down one time.  It's cached from here on out.  If we want to add new display types
	// we'll have to call this method after the controller knows about it.
	NSEnumerator *enumerator = [[growlProxy allDisplayPlugins] objectEnumerator];
	id title = nil;
	
	if ( applicationDisplayPluginsMenu ) [applicationDisplayPluginsMenu release];
	
	applicationDisplayPluginsMenu = [[NSMenu alloc] initWithTitle:@"DisplayPlugins"];
	[applicationDisplayPluginsMenu addItemWithTitle:@"Default" action:nil keyEquivalent:@""];
	[applicationDisplayPluginsMenu addItem:[NSMenuItem separatorItem]];
	
	while ( title = [enumerator nextObject] ) {
		[applicationDisplayPluginsMenu addItemWithTitle:title action:nil keyEquivalent:@""];
	}
	
	if ( notificationPriorityMenu ) [notificationPriorityMenu release];
	
	notificationPriorityMenu = [[NSMenu alloc] initWithTitle:@"Priority"];
	[notificationPriorityMenu addItemWithTitle:@"Very Low" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Moderate" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Normal" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"High" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Emergency" action:nil keyEquivalent:@""];
}

- (void) updateRunningStatus {
	[startStopTimer invalidate];
	startStopTimer = nil;
	[startStopGrowl setEnabled:YES];
	[startStopGrowl setTitle:growlIsRunning ? @"Stop Growl" : @"Start Growl"];
	[growlRunningStatus setStringValue:growlIsRunning ? @"Growl is running." : @"Growl is stopped"];
	[growlRunningProgress stopAnimation:self];
}

- (void) reloadAppTab {
	[currentApplication release]; currentApplication = nil;

	if ( ( [growlApplications selectedRow] < 0 ) 
		 && ( [[GrowlApplicationTicket allSavedTickets] count] > 0 ) ) {
		[growlApplications selectRow:0 byExtendingSelection:NO];
	}
	
	if ( [[GrowlApplicationTicket allSavedTickets] count] > 0 ) {
		currentApplication = [[applications objectAtIndex:[growlApplications selectedRow]] retain];
	}
	
	appTicket = [tickets objectForKey: currentApplication];
		
	[[[applicationNotifications tableColumnWithIdentifier:@"enable"] dataCell] setEnabled:[appTicket ticketEnabled]];
	[applicationNotifications reloadData];
	
	[growlApplications reloadData];
}

- (void) reloadDisplayTab {
	if ( currentPlugin ) [currentPlugin release];
	
	if ( ( [displayPlugins selectedRow] < 0 ) 
		 && ( [[growlProxy allDisplayPlugins] count] > 0 ) ) {
		[displayPlugins selectRow:0 byExtendingSelection:NO];
	}
	
	if ( [[growlProxy allDisplayPlugins] count] > 0 ) {
		currentPlugin = [[[growlProxy allDisplayPlugins] objectAtIndex:[displayPlugins selectedRow]] retain];
	}
	
	[self loadViewForDisplay:currentPlugin];
	
	NSDictionary * info = [growlProxy infoForPluginNamed:currentPlugin];
	if ( info ) {
		[displayAuthor setStringValue:[info objectForKey:@"Author"]];
		[displayVersion setStringValue:[info objectForKey:@"Version"]];
	}
}

#pragma mark "General" tab pane

- (IBAction) startStopGrowl:(id) sender {
	NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
	
	// Make sure growlIsRunning is correct
	if ( growlIsRunning != [self _isGrowlRunning] ) {
		// Nope - lets just flip it and update status
		growlIsRunning = !growlIsRunning;
		[self updateRunningStatus];
		return;
	}
	
	if ( ! growlIsRunning ) {
		//growlIsRunning = [[NSWorkspace sharedWorkspace] launchApplication:helperPath];
		[startStopGrowl setEnabled:NO];
		[growlRunningStatus setStringValue:[NSString stringWithUTF8String:"Launching Growl…"]];
		[growlRunningProgress startAnimation:self];
		
		// We want to launch in background, so we have to resort to Carbon
		// We don't really, but we want it to work in 10.2 as well
		LSLaunchFSRefSpec spec;
		FSRef appRef;
		OSStatus status = FSPathMakeRef( [helperPath fileSystemRepresentation], &appRef, NULL );
		
		if ( status == noErr ) {
			spec.appRef = &appRef;
			spec.numDocs = 0;
			spec.itemRefs = NULL;
			spec.passThruParams = NULL;
			spec.launchFlags = kLSLaunchNoParams | kLSLaunchAsync | kLSLaunchDontSwitch;
			spec.asyncRefCon = NULL;
			status = LSOpenFromRefSpec(&spec, NULL);
		}
		
	} else {
		[startStopGrowl setEnabled:NO];
		[growlRunningStatus setStringValue:[NSString stringWithUTF8String:"Terminating Growl…"]];
		[growlRunningProgress startAnimation:self];
		[growlProxy shutdown];
		[growlProxy release];
		growlProxy = nil;
	}

	startStopTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 
													  target:self
													selector:@selector( startStopTimeout: )
													userInfo:nil 
													 repeats:NO];
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
	
	while ( item = [e nextObject] ) {
		if ( [[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString:appPath] ) {
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
	[growlProxy setObject:[sender titleOfSelectedItem] forKey:GrowlDisplayPluginKey];
}

#pragma mark "Display Options" tab pane
//This is the frame of the preference view that we should get back.
#define DISPLAY_PREF_FRAME NSMakeRect(165., 42., 354., 289.)
- (void) loadViewForDisplay:(NSString*)displayName {
	NSView *newView = nil;
	NSPreferencePane *prefPane = nil, *oldPrefPane = nil;
	
	if ( pluginPrefPane ) {
		oldPrefPane = pluginPrefPane;
	}
	
	if ( displayName != nil ) {
		prefPane = [[[GrowlPluginController controller] displayPluginNamed:displayName] preferencePane];
		
		if ( prefPane && (prefPane != pluginPrefPane) ) {
			pluginPrefPane = prefPane;
			[oldPrefPane willUnselect];
		
			if ( [loadedPrefPanes containsObject:pluginPrefPane] ) {
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
	
	if ( newView == nil ) {
		newView = displayDefaultPrefView;
	}
	
	if ( displayPrefView != newView ) {
		// Make sure the new view is framed correctly
		[newView setFrame:DISPLAY_PREF_FRAME];
		[[displayPrefView superview] replaceSubview:displayPrefView with:newView];
		displayPrefView = newView;
		if ( pluginPrefPane ) {
			[pluginPrefPane didSelect];
			// Hook up key view chain
			[displayPlugins setNextKeyView:[pluginPrefPane firstKeyView]];
			[[pluginPrefPane lastKeyView] setNextKeyView:tabView];
			[[displayPlugins window] makeFirstResponder:[pluginPrefPane initialKeyView]];
		} else {
			[displayPlugins setNextKeyView:tabView];
		}
		if ( oldPrefPane ) {
			[oldPrefPane didUnselect];
		}
	}
}

#pragma mark Notification and Application table view data source methods

- (int) numberOfRowsInTableView:(NSTableView *)tableView {
	int retVal = 0;

	if ( tableView == growlApplications ) {
		retVal = [[GrowlApplicationTicket allSavedTickets] count];
	} else if ( tableView == applicationNotifications ) {
		retVal = [[appTicket allNotifications] count];
	} else if ( tableView == displayPlugins ) {
		retVal = [[growlProxy allDisplayPlugins] count];
	}
	
	return retVal;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row {
	id retVal = nil;
	
	if ( tableView == growlApplications ) 	{
		
		if ( [[column identifier] isEqualTo:@"enable"] ) {
			retVal = [NSNumber numberWithBool:[[tickets objectForKey: [applications objectAtIndex:row]] ticketEnabled]];
		} else if ( [[column identifier] isEqualTo:@"application"] ) {
			retVal = [applications objectAtIndex:row];
		} 
	
	} else if ( tableView == applicationNotifications ) {
		NSString * note = [[appTicket allNotifications] objectAtIndex:row];
		
		if ( [[column identifier] isEqualTo:@"enable"] ) {
			retVal = [NSNumber numberWithBool:[appTicket isNotificationEnabled:note]];
        } else if ( [[column identifier] isEqualTo:@"notification"] ) {
			retVal = note;
		} else if ( [[column identifier] isEqualTo:@"sticky"] ) {
			retVal = [NSNumber numberWithInt:[appTicket stickyForNotification:note]];
		}
	} else if ( tableView == displayPlugins ) {
		retVal = [[growlProxy allDisplayPlugins] objectAtIndex:row];
	}
	
	return retVal;
}

- (void) tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row {

	if ( tableView == growlApplications ) {
		NSString *application = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:row];
		if ( [[column identifier] isEqualTo:@"enable"] ) {
			[[tickets objectForKey:application] setEnabled:[value boolValue]];
			[self setPrefsChanged:YES];
		}
		
		if ( [[column identifier] isEqualTo:@"display"] )	{
			if ( [value intValue] == 0 ) {
				if ( [[tickets objectForKey:application] usesCustomDisplay] ) {
					[[tickets objectForKey:application] setUsesCustomDisplay:NO];
					[self setPrefsChanged:YES];
				}
			} else {
				if ( ! [[[applicationDisplayPluginsMenu itemAtIndex:[value intValue]] title] isEqualTo:[[[tickets objectForKey:application] displayPlugin] name]] ||
					 ! [[tickets objectForKey:application] usesCustomDisplay] ) {
					[[tickets objectForKey:application] setUsesCustomDisplay:YES];
					[[tickets objectForKey:application] setDisplayPluginNamed:[[applicationDisplayPluginsMenu itemAtIndex:[value intValue]] title]];
					[self setPrefsChanged:YES];
				}
			}
		}
		
		[self reloadAppTab];
		return;
	} else if ( tableView == applicationNotifications ) {
		NSString * note = [[appTicket allNotifications] objectAtIndex:row];
		
		if ( [[column identifier] isEqualTo:@"enable"] ) {
			if( [value boolValue] ) {
				[appTicket setNotificationEnabled:note];
			} else {
				[appTicket setNotificationDisabled:note];
			}
			
			[self setPrefsChanged:YES];
			return;
		}
		
		if ( [[column identifier] isEqualTo:@"priority"] ) {
			[appTicket setPriority:([value intValue]-2) forNotification:note];
			[self setPrefsChanged:YES];
			return;
		}
		
		if ( [[column identifier] isEqualTo:@"sticky"] ) {
            [appTicket setSticky:[value intValue] forNotification:note];
			[self setPrefsChanged:YES];
			return;
		}
	} else if ( tableView == displayPlugins )
		return;
}

#pragma mark Application Tab TableView delegate methods
- (void) tableViewSelectionDidChange:(NSNotification *)theNote {
	
	if ( [theNote object] == growlApplications ) {
		[self reloadAppTab];
	} else if ( [theNote object] == displayPlugins ) {
		[self reloadDisplayTab];
	}
}

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(int)row {
	
	if ( tableView == growlApplications ) {
		
		if ( [[column identifier] isEqualTo:@"display"] ) {
			[cell setMenu:applicationDisplayPluginsMenu];
			if ( ! [[tickets objectForKey: [applications objectAtIndex:row]] usesCustomDisplay] )
				[cell selectItemAtIndex:0]; // Default
			else
				[cell selectItemWithTitle:[[[tickets objectForKey: [applications objectAtIndex:row]] displayPlugin] name]];
		} else if ( [[column identifier] isEqualTo:@"application"] ) {
			NSImage* icon = [[tickets objectForKey: [applications objectAtIndex:row]] icon];
			[icon setScalesWhenResized:YES];
			[icon setSize:NSMakeSize(16,16)];
			[(ACImageAndTextCell*)cell setImage:icon];
		}
		
	} else if ( tableView == applicationNotifications ) {
		
		if ( [[column identifier] isEqualTo:@"priority"] ) {
			[cell setMenu:[notificationPriorityMenu copy]];
			int priority = [appTicket priorityForNotification:[[appTicket allNotifications] objectAtIndex:row]];
			[cell selectItemAtIndex:priority+2];
		}
	}
	
}

#pragma mark -

- (IBAction) revert:(id)sender {
	[self reloadPreferences];
	[self setPrefsChanged:NO];
}

- (IBAction) apply:(id)sender {
	[[[tickets objectEnumerator] allObjects] makeObjectsPerformSelector:@selector(saveTicket)];
	[self setPrefsChanged:NO];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged object:nil];
}

- (void) setPrefsChanged:(BOOL)prefsChanged {
	prefsHaveChanged = prefsChanged;
	
	[apply setEnabled:prefsHaveChanged];
	[revert setEnabled:prefsHaveChanged];
}

- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if ( returnCode == NSAlertDefaultReturn ) [self apply:nil];
	
	[self replyToShouldUnselect:returnCode == NSAlertDefaultReturn || returnCode == NSAlertAlternateReturn];
}

#pragma mark Detecting Growl

- (void) checkGrowlRunning {
	growlIsRunning = [self _isGrowlRunning];
	[self updateRunningStatus];
}

#pragma mark -

// Refresh preferences when a new application registers with Growl
- (void) appRegistered: (NSNotification *) note {
	NSString * app = [note object];
	GrowlApplicationTicket * ticket = [[[GrowlApplicationTicket alloc] initTicketForApplication:app] autorelease];
	
	[tickets setObject:ticket forKey:app];
	[applications release];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
	[growlApplications reloadData];
	
	if ( [currentApplication isEqualToString:app] ) [self reloadPreferences];
}

- (void) growlLaunched:(NSNotification *)note {
	growlIsRunning = YES;
	[self updateRunningStatus];
	
	NSString *uniqueName = [NSString stringWithFormat:@"GrowlPreferencesAdministrativeConnection-%@", NSUserName()];
	growlProxy = [[NSConnection rootProxyForConnectionWithRegisteredName:uniqueName host:nil] retain];
}

- (void) growlTerminated:(NSNotification *)note {
	growlIsRunning = NO;
	[self updateRunningStatus];
}

#pragma mark -
#pragma mark Private
- (BOOL) _isGrowlRunning {
	
	return (growlProxy != nil);
}

@end

