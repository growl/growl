//
//  GrowlPref.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPref.h"
#import "GrowlDisplayProtocol.h"
#import "GrowlApplicationNotification.h"
#import "ACImageAndTextCell.h"
#import "NSGrowlAdditions.h"
#import <ApplicationServices/ApplicationServices.h>
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>

#define PING_TIMEOUT		3

static const char *keychainServiceName = "Growl";
static const char *keychainAccountName = "Growl";

@interface GrowlPref (GrowlPrefPrivate)
- (BOOL) _isGrowlRunning;
- (void) _launchGrowl;
- (void) _terminateGrowl;
@end

@implementation GrowlPref

- (id) initWithBundle:(NSBundle *)bundle {
	if ( (self = [super initWithBundle:bundle] ) ) {
		pluginPrefPane = nil;
		tickets = nil;
		currentApplication = nil;
		startStopTimer = nil;
		loadedPrefPanes = [[NSMutableArray alloc] init];
		
		NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(growlLaunched:)   name:GROWL_IS_READY object:nil];
		[nc addObserver:self selector:@selector(growlTerminated:) name:GROWL_SHUTDOWN object:nil];
	}
	
	return self;
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[browser release];
	[services release];
	[pluginPrefPane release];
	[loadedPrefPanes release];
	[tickets release];
	[currentApplication release];
	[startStopTimer release];
	[images release];
	[super dealloc];
}

#pragma mark -

- (NSString *) bundleVersion {
	return [[[self bundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (IBAction) checkVersion:(id)sender {
	[growlVersionProgress startAnimation:self];

	static NSURL *versionCheckURL = nil;
	if(!versionCheckURL) versionCheckURL = [NSURL URLWithString:@"http://growl.info/version.xml"];
	static NSURL *downloadURL = nil;
	if(!downloadURL) downloadURL = [NSURL URLWithString:@"http://growl.info/"];

	[self checkVersionAtURL:versionCheckURL
				displayText:NSLocalizedStringFromTableInBundle(@"A newer version of Growl is available online. Would you like to download it now?", nil, [self bundle], @"")
				downloadURL:downloadURL];

	[growlVersionProgress stopAnimation:self];
}

- (void) checkVersionAtURL:(NSURL *)url displayText:(NSString *)message downloadURL:(NSURL *)goURL {
	NSBundle *bundle = [self bundle];
	NSDictionary *infoDict = [bundle infoDictionary];
	NSString *currVersionNumber = [infoDict objectForKey:@"CFBundleVersion"];
	NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL:url];
	NSString *latestVersionNumber = [productVersionDict objectForKey:
		[infoDict objectForKey:@"CFBundleExecutable"] ];
	
	/*
	NSLog([[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleExecutable"] );
	NSLog(currVersionNumber);
	NSLog(latestVersionNumber);
	*/

	// do nothing--be quiet if there is no active connection or if the
	// version number could not be downloaded
	if ( (latestVersionNumber != nil) && (![latestVersionNumber isEqualToString: currVersionNumber]) ) {
		NSBeginAlertSheet(NSLocalizedStringFromTableInBundle(@"Update Available", nil, bundle, @""),
						  NSLocalizedStringFromTableInBundle(@"OK", nil, bundle, @""), 
						  NSLocalizedStringFromTableInBundle(@"Cancel", nil, bundle, @""),
						  /*otherButton*/ nil,
						  /*window*/ nil, /*modalDelegate*/ self,
						  /*didEndSelector*/ NULL,
						  /*didDismissSelector*/ @selector(downloadSelector:returnCode:contextInfo:),
						  /*contextInfo*/ goURL,
						  message);
	}
}

- (void) downloadSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(NSURL *)contextInfo {
	if ( returnCode == NSAlertDefaultReturn ) { 
		[[NSWorkspace sharedWorkspace] openURL:contextInfo];
	}
}

- (void) awakeFromNib {
	NSTableColumn *tableColumn = [growlApplications tableColumnWithIdentifier: @"application"];
	ACImageAndTextCell *imageAndTextCell = [[[ACImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable: YES];
	[tableColumn setDataCell:imageAndTextCell];
	NSButtonCell *cell = [[applicationNotifications tableColumnWithIdentifier:@"sticky"] dataCell];
	[cell setAllowsMixedState:YES];

	[applicationNotifications deselectAll:NULL];
	[growlApplications deselectAll:NULL];
	[remove setEnabled:NO];

	[growlRunningProgress setDisplayedWhenStopped:NO];
	[growlVersion setStringValue:[self bundleVersion]];

	char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword( NULL,
											 strlen( keychainServiceName ), keychainServiceName,
											 strlen( keychainAccountName ), keychainAccountName,
											 &passwordLength, (void **)&password, NULL );

	if ( status == noErr ) {
		NSString *passwordString = [[NSString alloc] initWithUTF8String:password length:passwordLength];
		[networkPassword setStringValue:passwordString];
		[passwordString release];
		SecKeychainItemFreeContent( NULL, password );
	} else if ( status != errSecItemNotFound ) {
		NSLog( @"Failed to retrieve password from keychain. Error: %d", status );
		[networkPassword setStringValue:@""];
	}	

	browser = [[NSNetServiceBrowser alloc] init];
	services = [[NSMutableArray alloc] initWithArray:[[GrowlPreferences preferences] objectForKey:GrowlForwardDestinationsKey]];
	[browser setDelegate:self];
	[browser searchForServicesOfType:@"_growl._tcp." inDomain:@""];
}

- (void) mainViewDidLoad {
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(appRegistered:)
															name:GROWL_APP_REGISTRATION_CONF
														  object:nil];
}

//subclassed from NSPreferencePane; called before the pane is displayed.
- (void) willSelect {
	[self reloadPreferences];
	[self checkGrowlRunning];

	[tabView setDelegate:self];
}

- (NSPreferencePaneUnselectReply)shouldUnselect {
	NSPreferencePaneUnselectReply returnResponse = NSUnselectNow;
	
	if (prefsHaveChanged) {
		NSBundle *bundle = [self bundle];
		NSBeginAlertSheet( NSLocalizedStringFromTableInBundle(@"Apply Changes?", nil, bundle, @""),
						   NSLocalizedStringFromTableInBundle(@"Apply Changes", nil, bundle, @""),
						   NSLocalizedStringFromTableInBundle(@"Discard Changes", nil, bundle, @""),
						   NSLocalizedStringFromTableInBundle(@"Cancel", nil, bundle, @""),
						   [[self mainView] window], self, @selector(sheetDidEnd:returnCode:contextInfo:),
						   NULL, NULL,
						   NSLocalizedStringFromTableInBundle(@"You have made changes, but have not applied them. Would you like to apply them, discard them, or cancel?", nil, bundle, @""));
		returnResponse = NSUnselectLater;
	}
	return returnResponse;
}

// copy images to avoid resizing the original image stored in the ticket
- (void) cacheImages {

	if ( images ) {
		[images release];
	}
	
	images = [[NSMutableArray alloc] initWithCapacity:[applications count]];
	NSEnumerator *enumerator = [applications objectEnumerator];
	id key;
	
	while ( (key = [enumerator nextObject]) ) {
		NSImage *icon = [[NSImage alloc] initWithData:[[[tickets objectForKey:key] icon] TIFFRepresentation]];
		[icon setScalesWhenResized:YES];
		[icon setSize:NSMakeSize(16.0f, 16.0f)];
		[images addObject:icon];
		[icon release];
	}
}

- (void) reloadPreferences {
	if (tickets) {
		[tickets release];
	}
	tickets = [[GrowlApplicationTicket allSavedTickets] mutableCopy];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];

	[self cacheImages];

	[self loadViewForDisplay:nil];

	[growlApplications reloadData];

	GrowlPreferences *preferences = [GrowlPreferences preferences];
	[allDisplayPlugins removeAllItems];
	[allDisplayPlugins addItemsWithTitles:[[GrowlPluginController controller] allDisplayPlugins]];
	[allDisplayPlugins selectItemWithTitle:[preferences objectForKey:GrowlDisplayPluginKey]];
	[displayPlugins reloadData];

	if ( [[preferences objectForKey:GrowlStartServerKey] boolValue] ) {
		[startGrowlServer setState:NSOnState];
		[allowRemoteRegistration setEnabled:YES];
	} else {
		[startGrowlServer setState:NSOffState];
		[allowRemoteRegistration setEnabled:NO];
	}
	if ( [[preferences objectForKey:GrowlRemoteRegistrationKey] boolValue] ) {
		[allowRemoteRegistration setState:NSOnState];
	} else {
		[allowRemoteRegistration setState:NSOffState];
	}

	if ( [preferences startGrowlAtLogin] ) {
		[startGrowlAtLogin setState:NSOnState];
	} else {
		[startGrowlAtLogin setState:NSOffState];
	}

	if ( [[preferences objectForKey:GrowlEnableForwardKey] boolValue] ) {
		[enableForward setState:NSOnState];
		[growlServiceList setEnabled:YES];
	} else {
		[enableForward setState:NSOffState];
		[growlServiceList setEnabled:NO];
	}

	//If there is not a growl enabled key yet, set it to YES and launch Growl
	if ( ![preferences objectForKey:GrowlEnabledKey] ) {
		[preferences setObject:[NSNumber numberWithBool:YES]
						forKey:GrowlEnabledKey];

		[self _launchGrowl];
	}

	[self buildMenus];
	
	[self reloadAppTab];
	[self reloadDisplayTab];
	[self setPrefsChanged:NO];
}

- (void) buildMenus {
	// Building Menu for the drop down one time.  It's cached from here on out.  If we want to add new display types
	// we'll have to call this method after the controller knows about it.
	NSEnumerator * enumerator;
	
	if (applicationDisplayPluginsMenu) {
		[applicationDisplayPluginsMenu release];
	}

	applicationDisplayPluginsMenu = [[NSMenu alloc] initWithTitle:@"DisplayPlugins"];
	enumerator = [[[GrowlPluginController controller] allDisplayPlugins] objectEnumerator];
	id title;
	[applicationDisplayPluginsMenu addItemWithTitle:@"Default" action:nil keyEquivalent:@""];
	[applicationDisplayPluginsMenu addItem:[NSMenuItem separatorItem]];
	
	while ( (title = [enumerator nextObject] ) ) {
		[applicationDisplayPluginsMenu addItemWithTitle:title action:nil keyEquivalent:@""];
	}
	
	[[[growlApplications tableColumnWithIdentifier:@"display"] dataCell] setMenu:applicationDisplayPluginsMenu];

	if (notificationPriorityMenu) {
		[notificationPriorityMenu release];
	}
	
	notificationPriorityMenu = [[NSMenu alloc] initWithTitle:@"Priority"];
	[notificationPriorityMenu addItemWithTitle:@"Default" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItem:[NSMenuItem separatorItem]];
	[notificationPriorityMenu addItemWithTitle:@"Very Low" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Moderate" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Normal" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"High" action:nil keyEquivalent:@""];
	[notificationPriorityMenu addItemWithTitle:@"Emergency" action:nil keyEquivalent:@""];
	[[[applicationNotifications tableColumnWithIdentifier:@"priority"] dataCell] setMenu:notificationPriorityMenu];
}

- (void) updateRunningStatus {
	[startStopTimer invalidate];
	startStopTimer = nil;
	[startStopGrowl setEnabled:YES];
	NSBundle *bundle = [self bundle];
	[startStopGrowl setTitle:
		growlIsRunning ? NSLocalizedStringFromTableInBundle(@"Stop Growl",nil,bundle,@"")
					   : NSLocalizedStringFromTableInBundle(@"Start Growl",nil,bundle,@"")];
	[growlRunningStatus setStringValue:
		growlIsRunning ? NSLocalizedStringFromTableInBundle(@"Growl is running.",nil,bundle,@"")
					   : NSLocalizedStringFromTableInBundle(@"Growl is stopped.",nil,bundle,@"")];
	[growlRunningProgress stopAnimation:self];
}

- (void) reloadAppTab {
	[currentApplication release];
	currentApplication = nil;
//	currentApplication = [[growlApplications titleOfSelectedItem] retain];
	unsigned numApplications = [applications count];
	int row = [growlApplications selectedRow];
	if ( numApplications ) {
		if (row > -1)
			currentApplication = [[applications objectAtIndex:row] retain];
	} 

	[remove setEnabled:NO];
	appTicket = [tickets objectForKey: currentApplication];
	
//	[applicationEnabled setState: [appTicket ticketEnabled]];
//	[applicationEnabled setTitle: [NSString stringWithFormat:@"Enable notifications for %@",currentApplication]];

	[[[applicationNotifications tableColumnWithIdentifier:@"enable"] dataCell] setEnabled:[appTicket ticketEnabled]];

	[applicationNotifications reloadData];
	
	[growlApplications reloadData];
}

- (void) reloadDisplayTab {
	if (currentPlugin) {
		[currentPlugin release];
	}
	
	NSArray *plugins = [[GrowlPluginController controller] allDisplayPlugins];
	unsigned numPlugins = [plugins count];
	
	if (([displayPlugins selectedRow] < 0) && (numPlugins > 0U)) {
		[displayPlugins selectRow:0 byExtendingSelection:NO];
	}

	if (numPlugins > 0U) {
		currentPlugin = [[plugins objectAtIndex:[displayPlugins selectedRow]] retain];
	}
	
	[self loadViewForDisplay:currentPlugin];
	NSDictionary *info = [[[GrowlPluginController controller] displayPluginNamed:currentPlugin] pluginInfo];
	[displayAuthor setStringValue:[info objectForKey:@"Author"]];
	[displayVersion setStringValue:[info objectForKey:@"Version"]];
}

- (void) writeForwardDestinations {
	NSMutableArray *destinations = [NSMutableArray arrayWithCapacity:[services count]];
	NSEnumerator *enumerator = [services objectEnumerator];
	NSMutableDictionary *entry;
	while ( (entry = [enumerator nextObject]) ) {
		if ( ![entry objectForKey:@"netservice"] ) {
			[destinations addObject:entry];
		}
	}
	[[GrowlPreferences preferences] setObject:destinations forKey:GrowlForwardDestinationsKey];
}

#pragma mark "General" tab pane

- (IBAction) startStopGrowl:(id) sender {
	// Make sure growlIsRunning is correct
	if (growlIsRunning != [self _isGrowlRunning]) {
		// Nope - lets just flip it and update status
		growlIsRunning = !growlIsRunning;
		[self updateRunningStatus];
		return;
	}

	// Our desired state is a toggle of the current state;
	BOOL desiredGrowlState = !growlIsRunning;
	
	// Store the desired running-state of the helper app for use by GHA.
	[[GrowlPreferences preferences] setObject:[NSNumber numberWithBool:desiredGrowlState]
									   forKey:GrowlEnabledKey];

	if (desiredGrowlState) {
		[self _launchGrowl];

	} else {		
		[self _terminateGrowl];
	}
}

- (void) _launchGrowl {
	NSString *helperPath = [[[self bundle] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];

	// Don't allow the button to be clicked while we update
	[startStopGrowl setEnabled:NO];
	[growlRunningProgress startAnimation:self];

	// Update our status visible to the user
	[growlRunningStatus setStringValue:NSLocalizedStringFromTableInBundle(@"Launching Growl...",nil,[self bundle],@"")];

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

	// After 4 seconds force a status update, in case growl didn't start/stop
	[self performSelector:@selector(checkGrowlRunning)
			   withObject:nil
			   afterDelay:4.0];	
}

- (void) _terminateGrowl {
	// Don't allow the button to be clicked while we update
	[startStopGrowl setEnabled:NO];
	[growlRunningProgress startAnimation:self];

	// Update our status visible to the user
	[growlRunningStatus setStringValue:NSLocalizedStringFromTableInBundle(@"Terminating Growl...",nil,[self bundle],@"")];

	// Ask the Growl Helper App to shutdown via the DNC
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN object:nil];

	// After 4 seconds force a status update, in case growl didn't start/stop
	[self performSelector:@selector(checkGrowlRunning)
			   withObject:nil
			   afterDelay:4.0];	
}

- (IBAction) startGrowlAtLogin:(id) sender {
	[[GrowlPreferences preferences] setStartGrowlAtLogin:([startGrowlAtLogin state] == NSOnState)];
}

- (IBAction) selectDisplayPlugin:(id)sender {
	[[GrowlPreferences preferences] setObject:[sender titleOfSelectedItem] forKey:GrowlDisplayPluginKey];
}

- (IBAction)deleteTicket:(id)sender {
	int row = [growlApplications selectedRow];
	id key = [applications objectAtIndex:row];
	NSString *path = [[tickets objectForKey:key] path];
	
	if ( [[NSFileManager defaultManager] removeFileAtPath:path handler:nil] ) {
		[tickets removeObjectForKey:key];
		[images removeObjectAtIndex:row];
		[applications removeObjectAtIndex:row];
		[growlApplications deselectAll:NULL];
		[self reloadAppTab];
	}
}

#pragma mark "Network" tab pane

- (IBAction) startGrowlServer:(id)sender {
	BOOL enabled = ([sender state] == NSOnState);
	[[GrowlPreferences preferences] setObject:[NSNumber numberWithBool:enabled] forKey:GrowlStartServerKey];
	[allowRemoteRegistration setEnabled:enabled];
}

- (IBAction) allowRemoteRegistration:(id)sender {
	NSNumber *state = [NSNumber numberWithBool:([sender state] == NSOnState)];
	[[GrowlPreferences preferences] setObject:state forKey:GrowlRemoteRegistrationKey];
}

- (IBAction) setRemotePassword:(id)sender {
	const char *password = [[sender stringValue] UTF8String];
	unsigned length = strlen( password );
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword( NULL,
											 strlen( keychainServiceName ), keychainServiceName,
											 strlen( keychainAccountName ), keychainAccountName,
											 NULL, NULL, &itemRef );
	if ( status == errSecItemNotFound ) {
		// add new item
		status = SecKeychainAddGenericPassword( NULL,
												strlen( keychainServiceName ), keychainServiceName,
												strlen( keychainAccountName ), keychainAccountName,
												length, password, NULL );
		if ( status ) {
			NSLog( @"Failed to add password to keychain." );
		}
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
		{ kSecAccountItemAttr, strlen( keychainAccountName ), (char *)keychainAccountName },
		{ kSecServiceItemAttr, strlen( keychainServiceName ), (char *)keychainServiceName }
		};
		const SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
		status = SecKeychainItemModifyAttributesAndData( itemRef,		// the item reference
														 &attributes,	// no change to attributes
														 length,		// length of password
														 password		// pointer to password data
														 );
		if ( itemRef ) {
			CFRelease( itemRef );
		}
		if ( status ) {
			NSLog( @"Failed to change password in keychain." );
		}
	}
}

- (IBAction) setEnableForward:(id)sender {
	BOOL enabled = [sender state] == NSOnState;
	[growlServiceList setEnabled:enabled];
	[[GrowlPreferences preferences] setObject:[NSNumber numberWithBool:enabled] forKey:GrowlEnableForwardKey];
}

#pragma mark "Display Options" tab pane
//This is the frame of the preference view that we should get back.
#define DISPLAY_PREF_FRAME NSMakeRect(165.0f, 42.0f, 354.0f, 289.0f)
- (void)loadViewForDisplay:(NSString*)displayName {
	NSView *newView = nil;
	NSPreferencePane *prefPane = nil, *oldPrefPane = nil;
	
	if (pluginPrefPane) {
		oldPrefPane = pluginPrefPane;
	}
	
	if (displayName != nil) {
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
			[pluginPrefPane release];
			pluginPrefPane = [prefPane retain];
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
		[pluginPrefPane release]; pluginPrefPane = nil;
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
			//[[displayPlugins window] makeFirstResponder:[pluginPrefPane initialKeyView]];
		} else {
			[displayPlugins setNextKeyView:tabView];
		}
		
		if (oldPrefPane) {
			[oldPrefPane didUnselect];
		}
	}
}

#pragma mark Notification, Application and Service table view data source methods

- (int) numberOfRowsInTableView:(NSTableView *)tableView {
	int returnValue = 0;

	if (tableView == growlApplications) {
		returnValue = [applications count];
	} else if (tableView == applicationNotifications) {
		returnValue = [[appTicket allNotifications] count];
	} else if (tableView == displayPlugins) {
		returnValue = [[[GrowlPluginController controller] allDisplayPlugins] count];
	} else if (tableView == growlServiceList) {
		returnValue = [services count];
	}
	
	return returnValue;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row {
	id returnObject = nil;
	id identifier;
	
	if (tableView == growlApplications) 	{
		identifier = [column identifier];
		if ([identifier isEqualTo:@"enable"]) {
			returnObject = [NSNumber numberWithBool:[[tickets objectForKey: [applications objectAtIndex:row]] ticketEnabled]];
		} else if ([identifier isEqualTo:@"application"]) {
			returnObject = [applications objectAtIndex:row];
		} 
	} else if (tableView == applicationNotifications) {
		NSString * note = [[appTicket allNotifications] objectAtIndex:row];
		identifier = [column identifier];
		
		if ([identifier isEqualTo:@"enable"]) {
			returnObject = [NSNumber numberWithBool:[appTicket isNotificationEnabled:note]];
        } else if ([identifier isEqualTo:@"notification"]) {
			returnObject = note;
		} else if ([identifier isEqualTo:@"sticky"]) {
			returnObject = [NSNumber numberWithInt:[appTicket stickyForNotification:note]];
		}
	} else if (tableView == displayPlugins) {
		// only one column, but for the sake of cleanliness
		identifier = [column identifier];
		if ([identifier isEqualTo:@"plugins"]) {
			returnObject = [[[GrowlPluginController controller] allDisplayPlugins] objectAtIndex:row];
		}
	} else if (tableView == growlServiceList) {
		identifier = [column identifier];
		returnObject = [[services objectAtIndex:row] objectForKey:identifier];
	}

	return returnObject;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row {
	id identifier;
	
	if (tableView == growlApplications) {
		NSString * application = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] objectAtIndex:row];
		identifier = [column identifier];
		
		if ([identifier isEqualTo:@"enable"]) {
			[[tickets objectForKey:application] setEnabled:[value boolValue]];
			[self setPrefsChanged:YES];
		} else if ([identifier isEqualTo:@"display"])	{
			int index = [value intValue];
			
			if (index == 0) {
				if ([[tickets objectForKey:application] usesCustomDisplay]) {
					[[tickets objectForKey:application] setUsesCustomDisplay:NO];
					[self setPrefsChanged:YES];
				}
			} else {
				NSString *pluginName = [[applicationDisplayPluginsMenu itemAtIndex:index] title];
				
				if (![pluginName isEqualTo:[[[tickets objectForKey:application] displayPlugin] name]] ||
						![[tickets objectForKey:application] usesCustomDisplay]) {
					[[tickets objectForKey:application] setUsesCustomDisplay:YES];
					[[tickets objectForKey:application] setDisplayPluginNamed:pluginName];
					[self setPrefsChanged:YES];
				}
			}
		}
		[self reloadAppTab];
	} else if (tableView == applicationNotifications) {
		NSString * note = [[appTicket allNotifications] objectAtIndex:row];
		identifier = [column identifier];
		
		if ([identifier isEqualTo:@"enable"]) {
			if ([value boolValue]) {
				[appTicket setNotificationEnabled:note];
			} else {
				[appTicket setNotificationDisabled:note];
			}
			[self setPrefsChanged:YES];
		} else if ([identifier isEqualTo:@"priority"]) {
			int index = [value intValue];
			
			if (index == 0) {
				if ([appTicket priorityForNotification:note] != GP_unset) {
					[appTicket resetPriorityForNotification:note];
					[self setPrefsChanged:YES];
				}
			} else if ([appTicket priorityForNotification:note] != (index-4)) {
				[appTicket setPriority:(index-4) forNotification:note];
				[self setPrefsChanged:YES];
			}
		} else if ([identifier isEqualTo:@"sticky"]) {
            [appTicket setSticky:[value intValue] forNotification:note];
			[self setPrefsChanged:YES];
		}
	} else if (tableView == growlServiceList) {
		identifier = [column identifier];
		if ([identifier isEqualTo:@"use"]) {
			NSMutableDictionary *entry = [services objectAtIndex:row];
			if ([value boolValue]) {
				NSNetService *serviceToResolve = [entry objectForKey:@"netservice"];
				if ( serviceToResolve ) {
					// Make sure to cancel any previous resolves.
					if (serviceBeingResolved) {
						[serviceBeingResolved stop];
						[serviceBeingResolved release];
						serviceBeingResolved = nil;
					}

					currentServiceIndex = row;
					serviceBeingResolved = serviceToResolve;
					[serviceBeingResolved retain];
					[serviceBeingResolved setDelegate:self];
					[serviceBeingResolved resolve];
				}
			}

			[entry setObject:value forKey:identifier];
			[self writeForwardDestinations];
		}
	}
	
}

#pragma mark TableView delegate methods

- (void) tableViewSelectionDidChange:(NSNotification *)theNote {
	if ([theNote object] == growlApplications) {
		[self reloadAppTab];
		if ([[theNote object] selectedRow] > -1) {
			[remove setEnabled:YES]; 
		} else {
			[remove setEnabled:NO];
		}
		[applicationNotifications reloadData];
	} else if ([theNote object] == displayPlugins) {
		[self reloadDisplayTab];
		[remove setEnabled:NO];
	} else if ([theNote object] == applicationNotifications) {
		[self reloadAppTab];
		//[remove setEnabled:NO];
	}
}

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(int)row {
	
	if (tableView == growlApplications) {
		if ([[column identifier] isEqualTo:@"display"]) {
			if (![[tickets objectForKey: [applications objectAtIndex:row]] usesCustomDisplay]) {
				[cell selectItemAtIndex:0]; // Default
			} else {
				[cell selectItemWithTitle:[[[tickets objectForKey: [applications objectAtIndex:row]] displayPlugin] name]];
			}
		} else if ([[column identifier] isEqualTo:@"application"]) {
			[(ACImageAndTextCell *)cell setImage:[images objectAtIndex:row]];
		}
	} else if (tableView == applicationNotifications) {
		if ([[column identifier] isEqualTo:@"priority"]) {
			id notif = [[appTicket allNotifications] objectAtIndex:row];
			int priority = [appTicket priorityForNotification:notif];
			if (priority != GP_unset) {
				[cell selectItemAtIndex:priority+4];
			} else {
				[cell selectItemAtIndex:0];
			}
		}
	}
}

-(void) tableViewDidClickInBody:(NSTableView*)tableView {
	if ((tableView == growlApplications) && ([tableView selectedRow] > -1)) {
		[remove setEnabled:YES];
	} else {
		[remove setEnabled:NO];
	}
}

#pragma mark NSNetServiceBrowser Delegate Methods

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	// check if a computer with this name has already been added
	NSString *name = [aNetService name];
	NSEnumerator *enumerator = [services objectEnumerator];
	NSMutableDictionary *entry;
	while ( (entry = [enumerator nextObject]) ) {
		if ( [[entry objectForKey:@"computer"] isEqualToString:name] ) {
			return;
		}
	}

	// add a new entry at the end
	entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		aNetService, @"netservice",
		name, @"computer",
		[NSNumber numberWithBool:FALSE], @"use",
		nil];
	[services addObject:entry];
	[entry release];

	if (!moreComing) {
		[growlServiceList reloadData];
		[self writeForwardDestinations];
	}
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	// This case is slightly more complicated. We need to find the object in the list and remove it.
	unsigned count = [services count];
	NSDictionary *currentEntry;

	for( unsigned i = 0; i < count; ++i ) {
		currentEntry = [services objectAtIndex:i];
		if ([[currentEntry objectForKey:@"netservice"] isEqual:aNetService]) {
			[services removeObjectAtIndex:i];
			break;
		}
	}

	if (serviceBeingResolved && [serviceBeingResolved isEqual:aNetService]) {
		[serviceBeingResolved stop];
		[serviceBeingResolved release];
		serviceBeingResolved = nil;
	}

	if (!moreComing) {
		[growlServiceList reloadData];        
		[self writeForwardDestinations];
	}
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender {
	NSArray *addresses = [sender addresses];
    if ([addresses count] > 0U) {
		NSData *address = [addresses objectAtIndex:0U];
		NSMutableDictionary *entry = [services objectAtIndex:currentServiceIndex];
		[entry setObject:address forKey:@"address"];
		[entry removeObjectForKey:@"netservice"];
		[self writeForwardDestinations];
	}
}

#pragma mark Growl Tab View Delegate Methods
- (void) tabView:(NSTabView*)tab willSelectTabViewItem:(NSTabViewItem*)tabViewItem {
	//NSLog(@"%s %@\n", __FUNCTION__, [tabViewItem label]);
	if ([[tabViewItem identifier] isEqual:@"2"]) {
		[[tab window] makeFirstResponder: growlApplications];
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
	if (returnCode == NSAlertDefaultReturn)
		[self apply:nil];
	[self replyToShouldUnselect:returnCode == NSAlertDefaultReturn || returnCode == NSAlertAlternateReturn];
}

#pragma mark Detecting Growl

- (void)checkGrowlRunning {
	growlIsRunning = [self _isGrowlRunning];
	[self updateRunningStatus];
}

#pragma mark -

// Refresh preferences when a new application registers with Growl
- (void)appRegistered: (NSNotification *) note {
	NSString *app = [note object];
	GrowlApplicationTicket * ticket = [[[GrowlApplicationTicket alloc] initTicketForApplication:app] autorelease];

/*	if (![tickets objectForKey:app])
		[growlApplications addItemWithTitle:app];*/
	
	[tickets setObject:ticket forKey:app];
	[applications release];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
	[self cacheImages];
	[growlApplications reloadData];
	
	if ([currentApplication isEqualToString:app]) {
		[self reloadPreferences];
	}
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

