//
//  GrowlPref.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPref.h"
#import "GrowlPreferences.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlApplicationNotification.h"
#import "GrowlApplicationTicket.h"
#import "GrowlDisplayProtocol.h"
#import "GrowlPluginController.h"
#import "GrowlVersionUtilities.h"
#import "ACImageAndTextCell.h"
#import "NSGrowlAdditions.h"
#import <ApplicationServices/ApplicationServices.h>
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>

#define PING_TIMEOUT		3

#define keychainServiceName "Growl"
#define keychainAccountName "Growl"

//This is the frame of the preference view that we should get back.
#define DISPLAY_PREF_FRAME NSMakeRect(165.0f, 42.0f, 354.0f, 289.0f)

@implementation GrowlPref

- (id) initWithBundle:(NSBundle *)bundle {
	if ((self = [super initWithBundle:bundle])) {
		loadedPrefPanes    = [[NSMutableArray alloc] init];
		
		NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(growlLaunched:)   name:GROWL_IS_READY object:nil];
		[nc addObserver:self selector:@selector(growlTerminated:) name:GROWL_SHUTDOWN object:nil];

		NSDictionary *defaultDefaults = [[NSDictionary alloc] initWithContentsOfFile:
			[bundle pathForResource:@"GrowlDefaults"
							 ofType:@"plist"]];
		[[GrowlPreferences preferences] registerDefaults:defaultDefaults];
		[defaultDefaults release];
	}

	return self;
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[browser              release];
	[services             release];
	[pluginPrefPane       release];
	[loadedPrefPanes      release];
	[tickets              release];
	[currentApplication   release];
	[startStopTimer       release];
	[images               release];
	[versionCheckURL      release];
	[downloadURL          release];
	[applications         release];
	[filteredApplications release];
	[plugins              release];
	[super dealloc];
}

#pragma mark -

- (NSString *) bundleVersion {
	return [[[self bundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

- (IBAction) checkVersion:(id)sender {
	[growlVersionProgress startAnimation:self];

	if (!versionCheckURL) {
		versionCheckURL = [[NSURL alloc] initWithString:@"http://growl.info/version.xml"];
	}
	if (!downloadURL) {
		downloadURL = [[NSURL alloc] initWithString:@"http://growl.info/"];
	}

	[self checkVersionAtURL:versionCheckURL
				displayText:NSLocalizedStringFromTableInBundle(@"A newer version of Growl is available online. Would you like to download it now?", nil, [self bundle], @"")
				downloadURL:downloadURL];

	[growlVersionProgress stopAnimation:self];
}

- (void) checkVersionAtURL:(NSURL *)url displayText:(NSString *)message downloadURL:(NSURL *)goURL {
	NSBundle *bundle = [self bundle];
	NSDictionary *infoDict = [bundle infoDictionary];
	NSString *currVersionNumber = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];
	NSDictionary *productVersionDict = [[NSDictionary alloc] initWithContentsOfURL:url];
	NSString *latestVersionNumber = [productVersionDict objectForKey:
		[infoDict objectForKey:(NSString *)kCFBundleExecutableKey]];

	/*
	NSLog([[[NSBundle bundleForClass:[GrowlPref class]] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] );
	NSLog(currVersionNumber);
	NSLog(latestVersionNumber);
	*/

	// do nothing--be quiet if there is no active connection or if the
	// version number could not be downloaded
	if (latestVersionNumber && (compareVersionStringsTranslating1_0To0_5(latestVersionNumber, currVersionNumber) > 0)) {
		NSBeginAlertSheet(/*title*/ NSLocalizedStringFromTableInBundle(@"Update Available", nil, bundle, @""),
						  /*defaultButton*/ nil, // use default localized button title ("OK" in English)
						  /*alternateButton*/ NSLocalizedStringFromTableInBundle(@"Cancel", nil, bundle, @""),
						  /*otherButton*/ nil,
						  /*docWindow*/ nil,
						  /*modalDelegate*/ self,
						  /*didEndSelector*/ NULL,
						  /*didDismissSelector*/ @selector(downloadSelector:returnCode:contextInfo:),
						  /*contextInfo*/ goURL,
						  /*msg*/ message);
	}

	[productVersionDict release];
}

- (void) downloadSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertDefaultReturn) {
		[[NSWorkspace sharedWorkspace] openURL:contextInfo];
	}
}

- (void) awakeFromNib {
	NSTableColumn *tableColumn = [growlApplications tableColumnWithIdentifier:@"application"];
	ACImageAndTextCell *imageAndTextCell = [[ACImageAndTextCell alloc] init];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
	[imageAndTextCell release];
	NSButtonCell *cell = [[applicationNotifications tableColumnWithIdentifier:@"sticky"] dataCell];
	[cell setAllowsMixedState:YES];
	[cell setImagePosition:NSImageOnly];
	cell = [[applicationNotifications tableColumnWithIdentifier:@"enable"] dataCell];
	[cell setImagePosition:NSImageOnly];
	cell = [[growlApplications tableColumnWithIdentifier:@"enable"] dataCell];
	[cell setImagePosition:NSImageOnly];
	cell = [[applicationNotifications tableColumnWithIdentifier:@"priority"] dataCell];
	[cell setMenu:notificationPriorityMenu];

	[applicationNotifications deselectAll:NULL];
	[growlApplications deselectAll:NULL];
	[remove setEnabled:NO];

	[growlVersion setStringValue:[self bundleVersion]];

	char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword( NULL,
											 strlen( keychainServiceName ), keychainServiceName,
											 strlen( keychainAccountName ), keychainAccountName,
											 &passwordLength, (void **)&password, NULL );

	if (status == noErr) {
		NSString *passwordString = [[NSString alloc] initWithUTF8String:password length:passwordLength];
		[networkPassword setStringValue:passwordString];
		[passwordString release];
		SecKeychainItemFreeContent( NULL, password );
	} else if (status != errSecItemNotFound) {
		NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
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
}

// copy images to avoid resizing the original image stored in the ticket
- (void) cacheImages {

	if (images) {
		[images release];
	}

	images = [[NSMutableArray alloc] initWithCapacity:[applications count]];
	NSEnumerator *enumerator = [applications objectEnumerator];
	id key;

	while ((key = [enumerator nextObject])) {
		NSImage *icon = [[[tickets objectForKey:key] icon] copy];
		[icon setScalesWhenResized:YES];
		[icon setSize:NSMakeSize(16.0f, 16.0f)];
		[images addObject:icon];
		[icon release];
	}
}

- (IBAction) search:(id)sender {
	[self filterApplications];
	[growlApplications reloadData];
	[self reloadAppTab];
}

- (void) filterApplications {
	NSString *searchString = [searchField stringValue];
	[filteredApplications release];
	if (!searchString || ![searchString length]) {
		filteredApplications = [applications retain];
	} else {
		filteredApplications = [[NSMutableArray alloc] initWithCapacity:[applications count]];
		NSEnumerator *applicationsEnumerator = [applications objectEnumerator];
		NSString *name;
		while ((name = [applicationsEnumerator nextObject])) {
			if ([name rangeOfString:searchString options:NSAnchoredSearch|NSCaseInsensitiveSearch].location != NSNotFound) {
				[filteredApplications addObject:name];
			}
		}
	}
}

- (void) reloadPreferences {
	[tickets release];
	tickets = [[GrowlApplicationTicket allSavedTickets] mutableCopy];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
	[self filterApplications];

	[self cacheImages];

	[self loadViewForDisplay:nil];

	[growlApplications reloadData];

	[self setDisplayPlugins:[[GrowlPluginController controller] allDisplayPlugins]];

	GrowlPreferences *preferences = [GrowlPreferences preferences];
	[allDisplayPlugins removeAllItems];
	[allDisplayPlugins addItemsWithTitles:plugins];
	[allDisplayPlugins selectItemWithTitle:[preferences objectForKey:GrowlDisplayPluginKey]];

	startGrowlAtLogin = [preferences startGrowlAtLogin];
	backgroundUpdateCheckEnabled = [[preferences objectForKey:GrowlUpdateCheckKey] boolValue];
	growlServerEnabled = [[preferences objectForKey:GrowlStartServerKey] boolValue];
	remoteRegistrationAllowed = [[preferences objectForKey:GrowlRemoteRegistrationKey] boolValue];
	forwardingEnabled = [[preferences objectForKey:GrowlEnableForwardKey] boolValue];

	[self setStartGrowlAtLogin:startGrowlAtLogin];
	[self setBackgroundUpdateCheckEnabled:backgroundUpdateCheckEnabled];

	[self setGrowlServerEnabled:growlServerEnabled];
	[self setRemoteRegistrationAllowed:remoteRegistrationAllowed];
	[self setForwardingEnabled:forwardingEnabled];

	// If Growl is enabled, ensure the helper app is launched
	if ([[preferences objectForKey:GrowlEnabledKey] boolValue]) {
		[[GrowlPreferences preferences] launchGrowl];
	}

	[self buildMenus];
	
	[self reloadAppTab];
	[self reloadDisplayTab];
}

- (void) buildMenus {
	// Building Menu for the drop down one time.  It's cached from here on out.  If we want to add new display types
	// we'll have to call this method after the controller knows about it.
	NSEnumerator *enumerator;
	
	[applicationDisplayPluginsMenu release];
	applicationDisplayPluginsMenu = [[NSMenu alloc] initWithTitle:@"DisplayPlugins"];
	enumerator = [plugins objectEnumerator];
	id title;
	[applicationDisplayPluginsMenu addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Default",nil,[self bundle],@"") action:nil keyEquivalent:@""];
	[applicationDisplayPluginsMenu addItem:[NSMenuItem separatorItem]];
	
	while ((title = [enumerator nextObject])) {
		[applicationDisplayPluginsMenu addItemWithTitle:title action:nil keyEquivalent:@""];
	}

	[[[growlApplications tableColumnWithIdentifier:@"display"] dataCell] setMenu:applicationDisplayPluginsMenu];
	[[[applicationNotifications tableColumnWithIdentifier:@"display"] dataCell] setMenu:applicationDisplayPluginsMenu];
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
	unsigned numApplications = [filteredApplications count];
	int row = [growlApplications selectedRow];
	if (numApplications) {
		if (row > -1)
			currentApplication = [[filteredApplications objectAtIndex:row] retain];
	}
	if ((activeTableView == growlApplications) && ([growlApplications selectedRow] > -1)) {
		[remove setEnabled:YES]; 
	} else {
		[remove setEnabled:NO];
	}
	appTicket = [tickets objectForKey:currentApplication];

//	[applicationEnabled setState:[appTicket ticketEnabled]];
//	[applicationEnabled setTitle:[NSString stringWithFormat:@"Enable notifications for %@",currentApplication]];

	[[[applicationNotifications tableColumnWithIdentifier:@"enable"] dataCell] setEnabled:[appTicket ticketEnabled]];

	[applicationNotifications reloadData];

	[growlApplications reloadData];
}

- (void) reloadDisplayTab {
	if (currentPlugin) {
		[currentPlugin release];
	}

	unsigned numPlugins = [plugins count];

	if (([displayPluginsTable selectedRow] < 0) && (numPlugins > 0U)) {
		[displayPluginsTable selectRow:0 byExtendingSelection:NO];
	}

	if (numPlugins > 0U) {
		currentPlugin = [[plugins objectAtIndex:[displayPluginsTable selectedRow]] retain];
	}

	GrowlPluginController *growlPluginController = [GrowlPluginController controller];
	currentPluginController = [growlPluginController displayPluginNamed:currentPlugin];
	[self loadViewForDisplay:currentPlugin];
	NSDictionary *info = [growlPluginController infoDictionaryForPluginNamed:currentPlugin];
	[displayAuthor setStringValue:[info objectForKey:@"GrowlPluginAuthor"]];
	[displayVersion setStringValue:[info objectForKey:(NSString *)kCFBundleVersionKey]];
}

- (void) writeForwardDestinations {
	NSMutableArray *destinations = [[NSMutableArray alloc] initWithCapacity:[services count]];
	NSEnumerator *enumerator = [services objectEnumerator];
	NSMutableDictionary *entry;
	while ((entry = [enumerator nextObject])) {
		if (![entry objectForKey:@"netservice"]) {
			[destinations addObject:entry];
		}
	}
	[[GrowlPreferences preferences] setObject:destinations forKey:GrowlForwardDestinationsKey];
	[destinations release];
}

#pragma mark -
#pragma mark Growl running state

- (void) launchGrowl {
	// Don't allow the button to be clicked while we update
	[startStopGrowl setEnabled:NO];
	[growlRunningProgress startAnimation:self];
	
	// Update our status visible to the user
	[growlRunningStatus setStringValue:NSLocalizedStringFromTableInBundle(@"Launching Growl...",nil,[self bundle],@"")];
	
	[[GrowlPreferences preferences] setGrowlRunning:YES];
	
	// After 4 seconds force a status update, in case Growl didn't start/stop
	[self performSelector:@selector(checkGrowlRunning)
			   withObject:nil
			   afterDelay:4.0];	
}

- (void) terminateGrowl {
	// Don't allow the button to be clicked while we update
	[startStopGrowl setEnabled:NO];
	[growlRunningProgress startAnimation:self];
	
	// Update our status visible to the user
	[growlRunningStatus setStringValue:NSLocalizedStringFromTableInBundle(@"Terminating Growl...",nil,[self bundle],@"")];
	
	// Ask the Growl Helper App to shutdown
	[[GrowlPreferences preferences] setGrowlRunning:NO];
	
	// After 4 seconds force a status update, in case growl didn't start/stop
	[self performSelector:@selector(checkGrowlRunning)
			   withObject:nil
			   afterDelay:4.0];	
}

#pragma mark "General" tab pane

- (IBAction) startStopGrowl:(id) sender {
	// Make sure growlIsRunning is correct
	if (growlIsRunning != [[GrowlPreferences preferences] isGrowlRunning]) {
		// Nope - lets just flip it and update status
		growlIsRunning = !growlIsRunning;
		[self updateRunningStatus];
		return;
	}

	// Our desired state is a toggle of the current state;
	if (growlIsRunning) {
		[self terminateGrowl];
	} else {
		[self launchGrowl];
	}
}

#pragma mark -

- (BOOL) isStartGrowlAtLogin {
	return startGrowlAtLogin;
}

- (void) setStartGrowlAtLogin:(BOOL)flag {
	if (flag != startGrowlAtLogin) {
		startGrowlAtLogin = flag;
		[[GrowlPreferences preferences] setStartGrowlAtLogin:flag];
	}
}

#pragma mark -

- (BOOL) isBackgroundUpdateCheckEnabled {
	return backgroundUpdateCheckEnabled;
}

- (void) setBackgroundUpdateCheckEnabled:(BOOL)flag {
	if (flag != backgroundUpdateCheckEnabled) {
		backgroundUpdateCheckEnabled = flag;
		NSNumber *state = [[NSNumber alloc] initWithBool:flag];
		[[GrowlPreferences preferences] setObject:state forKey:GrowlUpdateCheckKey];
		[state release];
	}
}

#pragma mark -

- (IBAction) selectDisplayPlugin:(id)sender {
	[[GrowlPreferences preferences] setObject:[sender titleOfSelectedItem] forKey:GrowlDisplayPluginKey];
}

- (IBAction) deleteTicket:(id)sender {
	int row = [growlApplications selectedRow];
	id key = [filteredApplications objectAtIndex:row];
	NSString *path = [[tickets objectForKey:key] path];

	if ([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys: key, @"TicketName", nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged
																	   object:@"GrowlTicketDeleted"
																	 userInfo:userInfo];
		[userInfo release];
		[tickets removeObjectForKey:key];
		unsigned index;
		if (filteredApplications == applications) {
			index = row;
		} else {
			index = [applications indexOfObject:key];
			[filteredApplications removeObjectAtIndex:row];
		}
		[applications removeObjectAtIndex:index];
		[images removeObjectAtIndex:index];
		[growlApplications deselectAll:NULL];
		[self reloadAppTab];
	}
}

#pragma mark "Network" tab pane

- (BOOL) isGrowlServerEnabled {
	return growlServerEnabled;
}

- (void) setGrowlServerEnabled:(BOOL)enabled {
	if (enabled != growlServerEnabled) {
		growlServerEnabled = enabled;
		NSNumber *state = [[NSNumber alloc] initWithBool:enabled];
		[[GrowlPreferences preferences] setObject:state forKey:GrowlStartServerKey];
		[state release];
	}
}

#pragma mark -

- (BOOL) isRemoteRegistrationAllowed {
	return remoteRegistrationAllowed;
}

- (void) setRemoteRegistrationAllowed:(BOOL)flag {
	if (flag != remoteRegistrationAllowed) {
		remoteRegistrationAllowed = flag;
		NSNumber *state = [[NSNumber alloc] initWithBool:flag];
		[[GrowlPreferences preferences] setObject:state forKey:GrowlRemoteRegistrationKey];
		[state release];
	}
}

#pragma mark -

- (IBAction) setRemotePassword:(id)sender {
	const char *password = [[sender stringValue] UTF8String];
	unsigned length = strlen( password );
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword( NULL,
											 strlen( keychainServiceName ), keychainServiceName,
											 strlen( keychainAccountName ), keychainAccountName,
											 NULL, NULL, &itemRef );
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword( NULL,
												strlen( keychainServiceName ), keychainServiceName,
												strlen( keychainAccountName ), keychainAccountName,
												length, password, NULL );
		if (status) {
			NSLog(@"Failed to add password to keychain.");
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
		if (itemRef) {
			CFRelease(itemRef);
		}
		if (status) {
			NSLog(@"Failed to change password in keychain.");
		}
	}
}

#pragma mark -

- (BOOL) isForwardingEnabled {
	return forwardingEnabled;
}

- (void) setForwardingEnabled:(BOOL)enabled {
	if (enabled != forwardingEnabled) {
		forwardingEnabled = enabled;
		NSNumber *state = [[NSNumber alloc] initWithBool:enabled];
		[[GrowlPreferences preferences] setObject:state forKey:GrowlEnableForwardKey];
		[state release];
	}
}

#pragma mark "Display Options" tab pane

- (NSArray *) displayPlugins {
	return plugins;
}

- (void) setDisplayPlugins:(NSArray *)thePlugins {
	[plugins release];
	plugins = [thePlugins retain];
}

#pragma mark -

- (IBAction) showPreview:(id) sender {
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreview object:currentPlugin];
}

- (void)loadViewForDisplay:(NSString*)displayName {
	NSView *newView = nil;
	NSPreferencePane *prefPane = nil, *oldPrefPane = nil;

	if (pluginPrefPane) {
		oldPrefPane = pluginPrefPane;
	}

	if (displayName) {
		// Old plugins won't support the new protocol. Check first
		if ([currentPluginController respondsToSelector:@selector(preferencePane)]) {
			prefPane = [currentPluginController preferencePane];
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
		[pluginPrefPane release];
		pluginPrefPane = nil;
	}
	if (!newView) {
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
			[displayPluginsTable setNextKeyView:[pluginPrefPane firstKeyView]];
			[[pluginPrefPane lastKeyView] setNextKeyView:previewButton];
			//[[displayPluginsTable window] makeFirstResponder:[pluginPrefPane initialKeyView]];
		} else {
			[displayPluginsTable setNextKeyView:tabView];
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
		returnValue = [filteredApplications count];
	} else if (tableView == applicationNotifications) {
		returnValue = [[appTicket allNotifications] count];
	} else if (tableView == growlServiceList) {
		returnValue = [services count];
	}
	
	return returnValue;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)row {
	id returnObject = nil;
	id identifier;
	
	if (tableView == growlApplications) {
		identifier = [column identifier];
		if ([identifier isEqualTo:@"enable"]) {
			returnObject = [NSNumber numberWithBool:[[tickets objectForKey: [filteredApplications objectAtIndex:row]] ticketEnabled]];
		} else if ([identifier isEqualTo:@"application"]) {
			returnObject = [filteredApplications objectAtIndex:row];
		} 
	} else if (tableView == applicationNotifications) {
		NSString *note = [[appTicket allNotifications] objectAtIndex:row];
		identifier = [column identifier];

		if ([identifier isEqualTo:@"enable"]) {
			returnObject = [NSNumber numberWithBool:[appTicket isNotificationEnabled:note]];
		} else if ([identifier isEqualTo:@"notification"]) {
			returnObject = note;
		} else if ([identifier isEqualTo:@"sticky"]) {
			returnObject = [NSNumber numberWithInt:[appTicket stickyForNotification:note]];
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
		NSString *application = [filteredApplications objectAtIndex:row];
		GrowlApplicationTicket *ticket = [tickets objectForKey:application];
		identifier = [column identifier];

		if ([identifier isEqualTo:@"enable"]) {
			[ticket setEnabled:[value boolValue]];
			[GrowlPref saveTicket:ticket];
		} else if ([identifier isEqualTo:@"display"])	{
			int index = [value intValue];
			if (index == 0) {
				if ([ticket displayPlugin]) {
					[ticket setDisplayPluginNamed:nil];
					[GrowlPref saveTicket:ticket];
				}
			} else {
				NSString *pluginName = [[applicationDisplayPluginsMenu itemAtIndex:index] title];
				if (![pluginName isEqualTo:[[tickets objectForKey:application] displayPluginName]]) {
					[ticket setDisplayPluginNamed:pluginName];
					[GrowlPref saveTicket:ticket];
				}
			}
		}
		[self reloadAppTab];
	} else if (tableView == applicationNotifications) {
		NSString *note = [[appTicket allNotifications] objectAtIndex:row];
		identifier = [column identifier];

		if ([identifier isEqualTo:@"enable"]) {
			if ([value boolValue]) {
				[appTicket setNotificationEnabled:note];
			} else {
				[appTicket setNotificationDisabled:note];
			}
			[GrowlPref saveTicket:appTicket];
		} else if ([identifier isEqualTo:@"display"]) {
			int index = [value intValue];
			if (index == 0) {
				if ([appTicket displayPluginForNotification:note]) {
					[appTicket setDisplayPluginNamed:nil forNotification:note];
					[GrowlPref saveTicket:appTicket];
				}
			} else {
				NSString *pluginName = [[applicationDisplayPluginsMenu itemAtIndex:index] title];
				if (![pluginName isEqualTo:[appTicket displayPluginNameForNotification:note]]) {
					[appTicket setDisplayPluginNamed:pluginName forNotification:note];
					[GrowlPref saveTicket:appTicket];
				}
			}
		} else if ([identifier isEqualTo:@"priority"]) {
			int index = [value intValue];
			
			if (index == 0) {
				if ([appTicket priorityForNotification:note] != GP_unset) {
					[appTicket resetPriorityForNotification:note];
					[GrowlPref saveTicket:appTicket];
				}
			} else if ([appTicket priorityForNotification:note] != (index-4)) {
				[appTicket setPriority:(index-4) forNotification:note];
				[GrowlPref saveTicket:appTicket];
			}
		} else if ([identifier isEqualTo:@"sticky"]) {
			[appTicket setSticky:[value intValue] forNotification:note];
			[GrowlPref saveTicket:appTicket];
		}
	} else if (tableView == growlServiceList) {
		identifier = [column identifier];
		if ([identifier isEqualTo:@"use"]) {
			NSMutableDictionary *entry = [[services objectAtIndex:row] mutableCopy];
			if ([value boolValue]) {
				NSNetService *serviceToResolve = [entry objectForKey:@"netservice"];
				if (serviceToResolve) {
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
			[services replaceObjectAtIndex:row withObject:entry];
			[entry release];
			[self writeForwardDestinations];
		}
	}
}

#pragma mark TableView delegate methods

- (void) tableViewSelectionDidChange:(NSNotification *)theNote {
	NSTableView *tableView = [theNote object];
	if (tableView == growlApplications) {
		[self reloadAppTab];
		[applicationNotifications reloadData];
	} else if (tableView == displayPluginsTable) {
		[self reloadDisplayTab];
		//[remove setEnabled:NO];
	} else if (tableView == applicationNotifications) {
		[self reloadAppTab];
		//[remove setEnabled:NO];
	}
}

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(int)row {
	NSString *identifier = [column identifier];
	if (tableView == growlApplications) {
		if ([identifier isEqualTo:@"display"]) {
			NSString *displayPluginName = [[tickets objectForKey:[filteredApplications objectAtIndex:row]] displayPluginName];
			if (!displayPluginName) {
				[cell selectItemAtIndex:0]; // Default
			} else {
				[cell selectItemWithTitle:displayPluginName];
			}
		} else if ([identifier isEqualTo:@"application"]) {
			unsigned index = [applications indexOfObject:[filteredApplications objectAtIndex:row]];
			[(ACImageAndTextCell *)cell setImage:[images objectAtIndex:index]];
		}
	} else if (tableView == applicationNotifications) {
		id notif = [[appTicket allNotifications] objectAtIndex:row];
		if ([identifier isEqualTo:@"priority"]) {
			int priority = [appTicket priorityForNotification:notif];
			if (priority != GP_unset) {
				[cell selectItemAtIndex:priority+4];
			} else {
				[cell selectItemAtIndex:0];
			}
		} else if ([identifier isEqualTo:@"display"]) {
			NSString *displayPluginName = [appTicket displayPluginNameForNotification:notif];
			if (!displayPluginName) {
				[cell selectItemAtIndex:0]; // Default
			} else {
				[cell selectItemWithTitle:displayPluginName];
			}
		}
	}
}

- (void) tableViewDidClickInBody:(NSTableView *)tableView {
	activeTableView = tableView;
	if ((activeTableView == growlApplications) && ([growlApplications selectedRow] > -1)) {
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
	while ((entry = [enumerator nextObject])) {
		if ([[entry objectForKey:@"computer"] isEqualToString:name]) {
			return;
		}
	}

	// add a new entry at the end
	NSNumber *use = [[NSNumber alloc] initWithBool:NO];
	entry = [[NSDictionary alloc] initWithObjectsAndKeys:
		aNetService, @"netservice",
		name,        @"computer",
		use,         @"use",
		nil];
	[use release];
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

	for (unsigned i = 0; i < count; ++i) {
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
		NSMutableDictionary *entry = [[services objectAtIndex:currentServiceIndex] mutableCopy];
		[entry setObject:address forKey:@"address"];
		[entry removeObjectForKey:@"netservice"];
		[services replaceObjectAtIndex:currentServiceIndex withObject:entry];
		[entry release];
		
		[self writeForwardDestinations];
	}
}

#pragma mark -

+ (void)saveTicket:(GrowlApplicationTicket *)ticket {
	[ticket saveTicket];
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[ticket applicationName], @"TicketName", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged
																   object:@"GrowlTicketChanged"
																 userInfo:userInfo];
	[userInfo release];
}

#pragma mark Detecting Growl

- (void)checkGrowlRunning {
	growlIsRunning = [[GrowlPreferences preferences] isGrowlRunning];
	[self updateRunningStatus];
}

#pragma mark -

// Refresh preferences when a new application registers with Growl
- (void)appRegistered: (NSNotification *) note {
	NSString *app = [note object];
	GrowlApplicationTicket *ticket = [[GrowlApplicationTicket alloc] initTicketForApplication:app];

/*	if (![tickets objectForKey:app])
		[growlApplications addItemWithTitle:app];*/

	[tickets setObject:ticket forKey:app];
	[ticket release];
	[applications release];
	applications = [[[tickets allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
	[self filterApplications];
	[self cacheImages];
	[growlApplications reloadData];

	if ([currentApplication isEqualToString:app]) {
		[self reloadAppTab];
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

@end
