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
#define DISPLAY_PREF_FRAME NSMakeRect(16.0f, 58.0f, 354.0f, 289.0f)

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
	[browser            release];
	[services           release];
	[pluginPrefPane     release];
	[loadedPrefPanes    release];
	[tickets            release];
	[filteredTickets    release];
	[startStopTimer     release];
	[images             release];
	[versionCheckURL    release];
	[downloadURL        release];
	[plugins            release];
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
	tableColumn = [applicationNotifications tableColumnWithIdentifier:@"sticky"];
	NSButtonCell *cell = [tableColumn dataCell];
	[cell setAllowsMixedState:YES];
	[cell setImagePosition:NSImageOnly];
	// we have to establish this binding programmatically in order to use NSMixedState
	[tableColumn bind:@"value"
			 toObject:notificationsArrayController
		  withKeyPath:@"arrangedObjects.sticky"
			  options:nil];
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

	// create a deep mutable copy of the forward destinations
	NSArray *destinations = [[GrowlPreferences preferences] objectForKey:GrowlForwardDestinationsKey];
	NSEnumerator *destEnum = [destinations objectEnumerator];
	NSMutableArray *theServices = [[NSMutableArray alloc] initWithCapacity:[destinations count]];
	NSDictionary *destination;
	while ((destination = [destEnum nextObject])) {
		NSMutableDictionary *theService = [destination mutableCopy];
		[theServices addObject:theService];
		[theService release];
	}
	[self setServices:theServices];
	[theServices release];

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

	images = [[NSMutableArray alloc] initWithCapacity:[tickets count]];
	NSEnumerator *enumerator = [tickets objectEnumerator];
	GrowlApplicationTicket *ticket;

	while ((ticket = [enumerator nextObject])) {
		NSImage *icon = [[ticket icon] copy];
		[icon setScalesWhenResized:YES];
		[icon setSize:NSMakeSize(16.0f, 16.0f)];
		[images addObject:icon];
		[icon release];
	}
}

- (IBAction) search:(id)sender {
	[self filterTickets];
	[self reloadAppTab];
}

- (NSMutableArray *)tickets {
	return filteredTickets;
}

- (void) setTickets:(NSMutableArray *)theTickets {
	if (theTickets != filteredTickets) {
		[filteredTickets release];
		filteredTickets = [theTickets retain];
	}
}

- (void) filterTickets {
	NSString *searchString = [searchField stringValue];
	NSMutableArray *theTickets;
	if (!searchString || ![searchString length]) {
		theTickets = [tickets retain];
	} else {
		theTickets = [[NSMutableArray alloc] initWithCapacity:[tickets count]];
		NSEnumerator *ticketEnumerator = [tickets objectEnumerator];
		GrowlApplicationTicket *ticket;
		while ((ticket = [ticketEnumerator nextObject])) {
			if ([[ticket applicationName] rangeOfString:searchString options:NSAnchoredSearch|NSCaseInsensitiveSearch].location != NSNotFound) {
				[theTickets addObject:ticket];
			}
		}
	}

	[self setTickets:theTickets];
	[theTickets release];
}

- (void) reloadPreferences {
	[self setDisplayPlugins:[[GrowlPluginController controller] allDisplayPlugins]];
	[tickets release];
	tickets = [[[[GrowlApplicationTicket allSavedTickets] allValues] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
	[self filterTickets];
	[self cacheImages];

	[self loadViewForDisplay:nil];

	GrowlPreferences *preferences = [GrowlPreferences preferences];

	// If Growl is enabled, ensure the helper app is launched
	if ([[preferences objectForKey:GrowlEnabledKey] boolValue]) {
		[[GrowlPreferences preferences] launchGrowl];
	}
	
	[self reloadAppTab];
	[self reloadDisplayTab];
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
	int row = [growlApplications selectedRow];
	if ([filteredTickets count] && row > -1) {
		appTicket = [filteredTickets objectAtIndex:row];
	} else {
		appTicket = nil;
	}
	if ((activeTableView == growlApplications) && (row > -1)) {
		[remove setEnabled:YES]; 
	} else {
		[remove setEnabled:NO];
	}
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
	NSDictionary *entry;
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
	return [[GrowlPreferences preferences] startGrowlAtLogin];
}

- (void) setStartGrowlAtLogin:(BOOL)flag {
	[[GrowlPreferences preferences] setStartGrowlAtLogin:flag];
}

#pragma mark -

- (BOOL) isBackgroundUpdateCheckEnabled {
	return [[[GrowlPreferences preferences] objectForKey:GrowlUpdateCheckKey] boolValue];
}

- (void) setIsBackgroundUpdateCheckEnabled:(BOOL)flag {
	NSNumber *state = [[NSNumber alloc] initWithBool:flag];
	[[GrowlPreferences preferences] setObject:state forKey:GrowlUpdateCheckKey];
	[state release];
}

#pragma mark -

- (NSString *) defaultDisplayPluginName {
	return [[GrowlPreferences preferences] objectForKey:GrowlDisplayPluginKey];
}

- (void) setDefaultDisplayPluginName:(NSString *)name {
	[[GrowlPreferences preferences] setObject:name forKey:GrowlDisplayPluginKey];
}

#pragma mark -

- (void) deleteTicket:(id)sender {
	int row = [growlApplications selectedRow];
	GrowlApplicationTicket *ticket = [filteredTickets objectAtIndex:row];
	NSString *path = [ticket path];

	if ([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys: [ticket applicationName], @"TicketName", nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged
																	   object:@"GrowlTicketDeleted"
																	 userInfo:userInfo];
		[userInfo release];
		unsigned index;
		[self willChangeValueForKey:@"tickets"];
		if (filteredTickets == tickets) {
			index = row;
		} else {
			index = [tickets indexOfObject:ticket];
			[filteredTickets removeObjectAtIndex:row];
		}
		[tickets removeObjectAtIndex:index];
		[images removeObjectAtIndex:index];
		[growlApplications deselectAll:NULL];
		[self didChangeValueForKey:@"tickets"];
		[self reloadAppTab];
	}
}

#pragma mark "Network" tab pane

- (BOOL) isGrowlServerEnabled {
	return [[[GrowlPreferences preferences] objectForKey:GrowlStartServerKey] boolValue];
}

- (void) setGrowlServerEnabled:(BOOL)enabled {
	NSNumber *state = [[NSNumber alloc] initWithBool:enabled];
	[[GrowlPreferences preferences] setObject:state forKey:GrowlStartServerKey];
	[state release];
}

#pragma mark -

- (BOOL) isRemoteRegistrationAllowed {
	return [[[GrowlPreferences preferences] objectForKey:GrowlRemoteRegistrationKey] boolValue];
}

- (void) setRemoteRegistrationAllowed:(BOOL)flag {
	NSNumber *state = [[NSNumber alloc] initWithBool:flag];
	[[GrowlPreferences preferences] setObject:state forKey:GrowlRemoteRegistrationKey];
	[state release];
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
	return [[[GrowlPreferences preferences] objectForKey:GrowlEnableForwardKey] boolValue];
}

- (void) setForwardingEnabled:(BOOL)enabled {
	NSNumber *state = [[NSNumber alloc] initWithBool:enabled];
	[[GrowlPreferences preferences] setObject:state forKey:GrowlEnableForwardKey];
	[state release];
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

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(int)row {
	id identifier;

	if (tableView == growlApplications) {
		[GrowlPref saveTicket:[filteredTickets objectAtIndex:row]];
		[self reloadAppTab];
	} else if (tableView == applicationNotifications) {
		[GrowlPref saveTicket:appTicket];
	} else if (tableView == growlServiceList) {
		identifier = [column identifier];
		if ([identifier isEqualTo:@"use"]) {
			NSDictionary *entry = [services objectAtIndex:row];
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
					if ([serviceBeingResolved respondsToSelector:@selector(resolveWithTimeout:)]) {
						[serviceBeingResolved resolveWithTimeout:5.0];
					} else {
						// this selector is deprecated in 10.4
						[serviceBeingResolved resolve];
					}
				}
			}
			[self writeForwardDestinations];
		}
	}
}

- (NSMutableArray *) services {
	return services;
}

- (void) setServices:(NSMutableArray *)theServices {
	if (theServices != services) {
		[services release];
		services = [theServices retain];
	}
}

- (unsigned) countOfServices {
	return [services count];
}

- (id) objectInServicesAtIndex:(unsigned)index {
	return [services objectAtIndex:index];
}

- (void) insertObject:(id)anObject inServicesAtIndex:(unsigned)index {
	[services insertObject:anObject atIndex:index];
}

- (void) replaceObjectInServicesAtIndex:(unsigned)index withObject:(id)anObject {
	[services replaceObjectAtIndex:index withObject:anObject];
}

#pragma mark TableView delegate methods

- (void) tableViewSelectionDidChange:(NSNotification *)theNote {
	NSTableView *tableView = [theNote object];
	if (tableView == growlApplications) {
		[self reloadAppTab];
	} else if (tableView == displayPluginsTable) {
		[self reloadDisplayTab];
	} else if (tableView == applicationNotifications) {
		[self reloadAppTab];
	}
}

- (void) tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(int)row {
	NSString *identifier = [column identifier];
	if (tableView == growlApplications) {
		if ([identifier isEqualTo:@"application"]) {
			unsigned index = [tickets indexOfObject:[filteredTickets objectAtIndex:row]];
			[(ACImageAndTextCell *)cell setImage:[images objectAtIndex:index]];
		}
		/*
	} else if (tableView == applicationNotifications) {
		NSString *notif = [[appTicket allNotifications] objectAtIndex:row];
		if ([identifier isEqualTo:@"sticky"]) {
			int sticky = [appTicket stickyForNotification:notif];
			[cell setAllowsMixedState:YES];
			if (sticky > 0) {
				[cell setState:NSOnState];
			} else if (sticky == 0) {
				[cell setState:NSOffState];
			} else {
				[cell setState:NSMixedState];
			}
		}
		*/
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
	entry = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
		aNetService, @"netservice",
		name,        @"computer",
		use,         @"use",
		nil];
	[use release];
	[self willChangeValueForKey:@"services"];
	[services addObject:entry];
	[self didChangeValueForKey:@"services"];
	[entry release];

	if (!moreComing) {
		[self writeForwardDestinations];
	}
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	// This case is slightly more complicated. We need to find the object in the list and remove it.
	unsigned count = [services count];
	NSDictionary *currentEntry;
	NSString *name = [aNetService name];

	for (unsigned i = 0; i < count; ++i) {
		currentEntry = [services objectAtIndex:i];
		if ([[currentEntry objectForKey:@"computer"] isEqualToString:name]) {
			[self willChangeValueForKey:@"services"];
			[services removeObjectAtIndex:i];
			[self didChangeValueForKey:@"services"];
			break;
		}
	}

	if (serviceBeingResolved && [serviceBeingResolved isEqual:aNetService]) {
		[serviceBeingResolved stop];
		[serviceBeingResolved release];
		serviceBeingResolved = nil;
	}

	if (!moreComing) {
		[self writeForwardDestinations];
	}
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender {
	NSArray *addresses = [sender addresses];
	if ([addresses count] > 0U) {
		NSData *address = [addresses objectAtIndex:0U];
		NSMutableDictionary *entry = [services objectAtIndex:currentServiceIndex];
		[self willChangeValueForKey:@"services"];
		[entry setObject:address forKey:@"address"];
		[entry removeObjectForKey:@"netservice"];
		[self didChangeValueForKey:@"services"];
		[self writeForwardDestinations];
	}
}

#pragma mark -

+ (void) saveTicket:(GrowlApplicationTicket *)ticket {
	[ticket saveTicket];
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[ticket applicationName], @"TicketName", nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged
																   object:@"GrowlTicketChanged"
																 userInfo:userInfo];
	[userInfo release];
}

#pragma mark Detecting Growl

- (void) checkGrowlRunning {
	growlIsRunning = [[GrowlPreferences preferences] isGrowlRunning];
	[self updateRunningStatus];
}

#pragma mark -

// Refresh preferences when a new application registers with Growl
- (void) appRegistered: (NSNotification *) note {
	NSString *app = [note object];
	GrowlApplicationTicket *newTicket = [[GrowlApplicationTicket alloc] initTicketForApplication:app];

/*	if (![tickets objectForKey:app])
		[growlApplications addItemWithTitle:app];*/

	GrowlApplicationTicket *ticket;
	unsigned count = [tickets count];
	unsigned i;
	for (i=0U; i<count; ++i) {
		ticket = [tickets objectAtIndex:i];
		if ([[ticket applicationName] isEqualToString:app]) {
			[tickets replaceObjectAtIndex:i withObject:newTicket];
			break;
		}
	}
	if (i==count) {
		[tickets addObject:newTicket];
		NSMutableArray *newTickets = [[tickets sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy];
		[tickets release];
		tickets = newTickets;
	}
	[newTicket release];
	[self filterTickets];
	[self cacheImages];

	if ([[appTicket applicationName] isEqualToString:app]) {
		[self reloadAppTab];
	}
}

- (void) growlLaunched:(NSNotification *)note {
	growlIsRunning = YES;
	[self updateRunningStatus];
}

- (void) growlTerminated:(NSNotification *)note {
	growlIsRunning = NO;
	[self updateRunningStatus];
}

@end
