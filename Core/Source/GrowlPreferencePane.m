//
//  GrowlPreferencePane.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPreferencePane.h"
#import "GrowlPreferencesController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlTicketController.h"
#import "GrowlApplicationTicket.h"
#import "GrowlDisplayProtocol.h"
#import "GrowlPluginController.h"
#import "GrowlVersionUtilities.h"
#import "GrowlBrowserEntry.h"
#import "NSStringAdditions.h"
#import "TicketsArrayController.h"
#import <ApplicationServices/ApplicationServices.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define PING_TIMEOUT		3

//This is the frame of the preference view that we should get back.
#define DISPLAY_PREF_FRAME NSMakeRect(16.0f, 58.0f, 354.0f, 289.0f)

@interface NSNetService(TigerCompatibility)

- (void) resolveWithTimeout:(NSTimeInterval)timeout;

@end

@implementation GrowlPreferencePane

- (id) initWithBundle:(NSBundle *)bundle {
	//	Check that we're running Panther
	//	if a user with a previous OS version tries to launch us - switch out the pane.

	NSApp = [NSApplication sharedApplication];
	if (![NSApp respondsToSelector:@selector(replyToOpenOrPrint:)]) {
		NSString *msg = @"Mac OS X 10.3 \"Panther\" or greater is required.";

		if (NSRunInformationalAlertPanel(@"Growl requires Panther...", msg, @"Quit", @"Get Panther...", nil) == NSAlertAlternateReturn) {
			NSURL *pantherURL = [[NSURL alloc] initWithString:@"http://www.apple.com/macosx/"];
			[[NSWorkspace sharedWorkspace] openURL:pantherURL];
			[pantherURL release];
		}
		[NSApp terminate:nil];
	}

	if ((self = [super initWithBundle:bundle])) {
		pid = [[NSProcessInfo processInfo] processIdentifier];
		loadedPrefPanes = [[NSMutableArray alloc] init];
		preferencesController = [GrowlPreferencesController sharedController];

		NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(growlLaunched:)   name:GROWL_IS_READY object:nil];
		[nc addObserver:self selector:@selector(growlTerminated:) name:GROWL_SHUTDOWN object:nil];
		[nc addObserver:self selector:@selector(reloadPrefs:)     name:GrowlPreferencesChanged object:nil];

		NSDictionary *defaultDefaults = [[NSDictionary alloc] initWithContentsOfFile:
			[bundle pathForResource:@"GrowlDefaults"
							 ofType:@"plist"]];
		[preferencesController registerDefaults:defaultDefaults];
		[defaultDefaults release];
	}

	return self;
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[browser         release];
	[services        release];
	[pluginPrefPane  release];
	[loadedPrefPanes release];
	[tickets         release];
	[plugins         release];
	[currentPlugin   release];
	CFRelease(customHistArray);
	CFRelease(versionCheckURL);
	CFRelease(growlWebSiteURL);
	CFRelease(growlForumURL);
	CFRelease(growlTracURL);
	CFRelease(images);
	[super dealloc];
}

- (void) awakeFromNib {
	// TODO: this does not work
	//NSSecureTextFieldCell *secureTextCell = [[NSSecureTextFieldCell alloc] init];
	//[servicePasswordColumn setDataCell:secureTextCell];
	//[secureTextCell release];

	[ticketsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];
	[displayPluginsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];

	[self setCanRemoveTicket:NO];

	browser = [[NSNetServiceBrowser alloc] init];

	// create a deep mutable copy of the forward destinations
	NSArray *destinations = [preferencesController objectForKey:GrowlForwardDestinationsKey];
	NSEnumerator *destEnum = [destinations objectEnumerator];
	NSMutableArray *theServices = [[NSMutableArray alloc] initWithCapacity:[destinations count]];
	NSDictionary *destination;
	while ((destination = [destEnum nextObject])) {
		GrowlBrowserEntry *entry = [[GrowlBrowserEntry alloc] initWithDictionary:destination];
		[entry setOwner:self];
		[theServices addObject:entry];
		[entry release];
	}
	[self setServices:theServices];
	[theServices release];

	[browser setDelegate:self];
	[browser searchForServicesOfType:@"_growl._tcp." inDomain:@""];

	[self setupAboutTab];

	if ([preferencesController isGrowlMenuEnabled] && ![GrowlPreferencePane isGrowlMenuRunning])
		[preferencesController enableGrowlMenu];

	growlWebSiteURL = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("http://growl.info"), NULL);
	growlForumURL   = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("http://forums.cocoaforge.com/viewforum.php?f=6"), NULL);
	growlTracURL    = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("http://trac.growl.info/trac"), NULL);
	NSString *growlWebSiteURLString = (NSString *)CFURLGetString(growlWebSiteURL);
	NSString *growlForumURLString   = (NSString *)CFURLGetString(growlForumURL);
	NSString *growlTracURLString    = (NSString *)CFURLGetString(growlTracURL);

	[growlWebSite setAttributedTitle:         [growlWebSiteURLString       hyperlink]];
	[growlWebSite setAttributedAlternateTitle:[growlWebSiteURLString activeHyperlink]];
	[[growlWebSite cell] setHighlightsBy:NSContentsCellMask];
	[growlForum   setAttributedTitle:         [growlForumURLString         hyperlink]];
	[growlForum   setAttributedAlternateTitle:[growlForumURLString   activeHyperlink]];
	[[growlForum   cell] setHighlightsBy:NSContentsCellMask];
	[growlTrac    setAttributedTitle:         [growlTracURLString          hyperlink]];
	[growlTrac    setAttributedAlternateTitle:[growlTracURLString    activeHyperlink]];
	[[growlTrac    cell] setHighlightsBy:NSContentsCellMask];

	customHistArray = CFArrayCreateMutable(kCFAllocatorDefault, 3, &kCFTypeArrayCallBacks);
	id value = [preferencesController objectForKey:GrowlCustomHistKey1];
	if (value) {
		CFArrayAppendValue(customHistArray, value);
		value = [preferencesController objectForKey:GrowlCustomHistKey2];
		if (value) {
			CFArrayAppendValue(customHistArray, value);
			value = [preferencesController objectForKey:GrowlCustomHistKey3];
			if (value)
				CFArrayAppendValue(customHistArray, value);
		}
	}
	[self updateLogPopupMenu];
	int typePref = [preferencesController integerForKey:GrowlLogTypeKey];
	[logFileType selectCellAtRow:typePref column:0];

	[growlApplications setDoubleAction:@selector(tableViewDoubleClick:)];
	[growlApplications setTarget:self];
}

- (void) mainViewDidLoad {
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self
														selector:@selector(appRegistered:)
															name:GROWL_APP_REGISTRATION_CONF
														  object:nil];
}

#pragma mark -

/*!
 * @brief Returns the bundle version of the Growl.prefPane bundle.
 */
- (NSString *) bundleVersion {
	return (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey);
}

/*!
 * @brief Checks if a newer version of Growl is available at the Growl download site.
 *
 * The version.xml file is a property list which contains version numbers and
 * download URLs for several components.
 */
- (IBAction) checkVersion:(id)sender {
#pragma unused(sender)
	[growlVersionProgress startAnimation:self];

	if (!versionCheckURL)
		versionCheckURL = CFURLCreateWithString(kCFAllocatorDefault, CFSTR("http://growl.info/version.xml"), NULL);

	NSBundle *bundle = [self bundle];
	NSDictionary *infoDict = [bundle infoDictionary];
	NSString *currVersionNumber = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];
	NSDictionary *productVersionDict = [[NSDictionary alloc] initWithContentsOfURL:(NSURL *)versionCheckURL];
	NSString *executableName = [infoDict objectForKey:(NSString *)kCFBundleExecutableKey];
	NSString *latestVersionNumber = [productVersionDict objectForKey:executableName];

	NSURL *downloadURL = [[NSURL alloc] initWithString:
		[productVersionDict objectForKey:[executableName stringByAppendingString:@"DownloadURL"]]];
	/*
	 NSLog([[[NSBundle bundleWithIdentifier:@"com.growl.prefpanel"] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] );
	 NSLog(currVersionNumber);
	 NSLog(latestVersionNumber);
	 */

	// do nothing--be quiet if there is no active connection or if the
	// version number could not be downloaded
	if (latestVersionNumber && (compareVersionStringsTranslating1_0To0_5(latestVersionNumber, currVersionNumber) > 0))
		NSBeginAlertSheet(/*title*/ NSLocalizedStringFromTableInBundle(@"Update Available", nil, bundle, @""),
						  /*defaultButton*/ nil, // use default localized button title ("OK" in English)
						  /*alternateButton*/ NSLocalizedStringFromTableInBundle(@"Cancel", nil, bundle, @""),
						  /*otherButton*/ nil,
						  /*docWindow*/ nil,
						  /*modalDelegate*/ self,
						  /*didEndSelector*/ NULL,
						  /*didDismissSelector*/ @selector(downloadSelector:returnCode:contextInfo:),
						  /*contextInfo*/ downloadURL,
						  /*msg*/ NSLocalizedStringFromTableInBundle(@"A newer version of Growl is available online. Would you like to download it now?", nil, [self bundle], @""));
	else
		[downloadURL release];

	[productVersionDict release];

	[growlVersionProgress stopAnimation:self];
}

- (void) downloadSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
#pragma unused(sheet)
	NSURL *downloadURL = (NSURL *)contextInfo;
	if (returnCode == NSAlertDefaultReturn)
		[[NSWorkspace sharedWorkspace] openURL:downloadURL];
	[downloadURL release];
}

/*!
 * @brief Returns if GrowlMenu is currently running.
 */
+ (BOOL) isGrowlMenuRunning {
	return [[GrowlPreferencesController sharedController] isRunning:@"com.Growl.MenuExtra"];
}

//subclassed from NSPreferencePane; called before the pane is displayed.
- (void) willSelect {
	NSString *lastVersion = [preferencesController objectForKey:LastKnownVersionKey];
	NSString *currentVersion = [self bundleVersion];
	if (!(lastVersion && [lastVersion isEqualToString:currentVersion])) {
		if ([preferencesController isGrowlRunning]) {
			[preferencesController setGrowlRunning:NO noMatterWhat:NO];
			[preferencesController setGrowlRunning:YES noMatterWhat:YES];
		}
		[preferencesController setObject:currentVersion forKey:LastKnownVersionKey];
	}
	[self checkGrowlRunning];
}

- (void) didSelect {
	[self reloadPreferences:nil];
}

/*!
 * @brief copy images to avoid resizing the original images stored in the tickets.
 */
- (void) cacheImages {
	if (images)
		CFArrayRemoveAllValues(images);
	else
		images = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

	NSEnumerator *enumerator = [tickets objectEnumerator];
	GrowlApplicationTicket *ticket;
	while ((ticket = [enumerator nextObject])) {
		NSImage *icon = [[ticket icon] copy];
		[icon setScalesWhenResized:YES];
		[icon setSize:NSMakeSize(32.0f, 32.0f)];
		CFArrayAppendValue(images, icon);
		[icon release];
	}
}

- (NSMutableArray *) tickets {
	return tickets;
}

- (void) setTickets:(NSArray *)theTickets {
	if (theTickets != tickets) {
		if (tickets)
			[tickets setArray:theTickets];
		else
			tickets = [theTickets mutableCopy];
	}
}

- (void) removeFromTicketsAtIndex:(int)indexToRemove {
	NSMutableArray *ticketsCopy = [tickets mutableCopy];
	[ticketsCopy removeObjectAtIndex:indexToRemove];

	//	We're not using the setTickets accessor here.
	//	If we did, the controller would know we had switched out the entire array.
	//	And UI quirks would happen. (selection jumps back to 0)

	[tickets release];
	tickets = ticketsCopy;
}

- (void) insertInTickets:(GrowlApplicationTicket *)newTicket {
	NSMutableArray *ticketsCopy = [tickets mutableCopy];
	[ticketsCopy addObject:newTicket];
	[self setTickets:ticketsCopy];
	[ticketsCopy release];
}

- (void) reloadDisplayPluginView {
	NSArray *selectedPlugins = [displayPluginsArrayController selectedObjects];
	unsigned numPlugins = [plugins count];
	[currentPlugin release];
	if (numPlugins > 0U && selectedPlugins && [selectedPlugins count] > 0U)
		currentPlugin = [[selectedPlugins objectAtIndex:0U] retain];
	else
		currentPlugin = nil;

	GrowlPluginController *growlPluginController = [GrowlPluginController sharedController];
	currentPluginController = [growlPluginController displayPluginInstanceWithName:currentPlugin];
	[self loadViewForDisplay:currentPlugin];
	NSDictionary *info = [[growlPluginController displayPluginBundleWithName:currentPlugin] infoDictionary];
	[displayAuthor setStringValue:[info objectForKey:@"GrowlPluginAuthor"]];
	[displayVersion setStringValue:[info objectForKey:(NSString *)kCFBundleVersionKey]];
}

/*!
 * @brief Called when a distributed GrowlPreferencesChanged notification is received.
 */
- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSNumber *pidValue = [[notification userInfo] objectForKey:@"pid"];
	if (!pidValue || [pidValue intValue] != pid)
		[self reloadPreferences:[notification object]];
}

/*!
 * @brief Reloads the preferences and updates the GUI accordingly.
 */
- (void) reloadPreferences:(NSString *)object {
//	NSLog(@"%s\n", __func__);
	GrowlTicketController *ticketController = [GrowlTicketController sharedController];
	[ticketController loadAllSavedTickets];
	[self setDisplayPlugins:[[GrowlPluginController sharedController] displayPlugins]];
	if (!object || [object isEqualToString:@"GrowlTicketChanged"])
		[self setTickets:[[ticketController allSavedTickets] allValues]];
	[preferencesController setSquelchMode:[preferencesController squelchMode]];
	[preferencesController setGrowlMenuEnabled:[preferencesController isGrowlMenuEnabled]];
	[self cacheImages];

	// If Growl is enabled, ensure the helper app is launched
	if ([preferencesController boolForKey:GrowlEnabledKey])
		[preferencesController launchGrowl:NO];

	if ([plugins count] > 0U) {
		NSString *defaultPlugin = [preferencesController objectForKey:GrowlDisplayPluginKey];
		unsigned defaultIndex = [[displayPluginsArrayController arrangedObjects] indexOfObject:defaultPlugin];
		if (defaultIndex == NSNotFound)
			defaultIndex = 0U;
		[displayPluginsArrayController setSelectionIndex:defaultIndex];
		[self reloadDisplayPluginView];
	} else {
		[self loadViewForDisplay:nil];
	}
}

- (BOOL) growlIsRunning {
	return growlIsRunning;
}

- (void) setGrowlIsRunning:(BOOL)flag {
	growlIsRunning = flag;
}

- (void) updateRunningStatus {
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

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
#pragma unused(change, context)
	if ([keyPath isEqualToString:@"selection"]) {
		if ((object == ticketsArrayController))
			[self setCanRemoveTicket:(activeTableView == growlApplications) && [ticketsArrayController canRemove]];
		else if (object == displayPluginsArrayController)
			[self reloadDisplayPluginView];
	}
}

- (void) writeForwardDestinations {
	NSMutableArray *destinations = [[NSMutableArray alloc] initWithCapacity:[services count]];
	NSEnumerator *enumerator = [services objectEnumerator];
	GrowlBrowserEntry *entry;
	while ((entry = [enumerator nextObject]))
		if (![entry netService])
			[destinations addObject:[entry properties]];
	[preferencesController setObject:destinations forKey:GrowlForwardDestinationsKey];
	[destinations release];
}

#pragma mark -
#pragma mark Bindings accessors (not for programmatic use)

- (GrowlPluginController *) pluginController {
	if (!pluginController)
		pluginController = [GrowlPluginController sharedController];

	return pluginController;
}
- (GrowlPreferencesController *) preferencesController {
	if (!preferencesController)
		preferencesController = [GrowlPreferencesController sharedController];

	return preferencesController;
}

#pragma mark Growl running state

/*!
 * @brief Launches GrowlHelperApp.
 */
- (void) launchGrowl {
	// Don't allow the button to be clicked while we update
	[startStopGrowl setEnabled:NO];
	[growlRunningProgress startAnimation:self];

	// Update our status visible to the user
	[growlRunningStatus setStringValue:NSLocalizedStringFromTableInBundle(@"Launching Growl...",nil,[self bundle],@"")];

	[preferencesController setGrowlRunning:YES noMatterWhat:NO];

	// After 4 seconds force a status update, in case Growl didn't start/stop
	[self performSelector:@selector(checkGrowlRunning)
			   withObject:nil
			   afterDelay:4.0];
}

/*!
 * @brief Terminates running GrowlHelperApp instances.
 */
- (void) terminateGrowl {
	// Don't allow the button to be clicked while we update
	[startStopGrowl setEnabled:NO];
	[growlRunningProgress startAnimation:self];

	// Update our status visible to the user
	[growlRunningStatus setStringValue:NSLocalizedStringFromTableInBundle(@"Terminating Growl...",nil,[self bundle],@"")];

	// Ask the Growl Helper App to shutdown
	[preferencesController setGrowlRunning:NO noMatterWhat:NO];

	// After 4 seconds force a status update, in case growl didn't start/stop
	[self performSelector:@selector(checkGrowlRunning)
			   withObject:nil
			   afterDelay:4.0];
}

#pragma mark "General" tab pane

- (IBAction) startStopGrowl:(id) sender {
#pragma unused(sender)
	// Make sure growlIsRunning is correct
	if (growlIsRunning != [preferencesController isGrowlRunning]) {
		// Nope - lets just flip it and update status
		[self setGrowlIsRunning:!growlIsRunning];
		[self updateRunningStatus];
		return;
	}

	// Our desired state is a toggle of the current state;
	if (growlIsRunning)
		[self terminateGrowl];
	else
		[self launchGrowl];
}

- (IBAction) logTypeChanged:(id)sender {
	int typePref = [sender selectedRow];
	BOOL hasSelection = (typePref != 0);
	int numberOfItems = [customMenuButton numberOfItems];
	if (hasSelection && (numberOfItems == 1))
		[self customFileChosen:customMenuButton];
	[preferencesController setInteger:typePref forKey:GrowlLogTypeKey];
	[customMenuButton setEnabled:(hasSelection && (numberOfItems > 1))];
}

/*!
 * @brief Opens Console.app.
 */
- (IBAction) openConsoleApp:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.apple.Console"
														 options:NSWorkspaceLaunchAsync
								  additionalEventParamDescriptor:nil
												launchIdentifier:nil];
}

- (IBAction) customFileChosen:(id)sender {
	int selected = [sender indexOfSelectedItem];
	if ((selected == [sender numberOfItems] - 1) || (selected == -1)) {
		NSSavePanel *sp = [NSSavePanel savePanel];
		[sp setRequiredFileType:@"log"];
		[sp setCanSelectHiddenExtension:YES];

		int runResult = [sp runModalForDirectory:nil file:@""];
		NSString *saveFilename = [sp filename];
		if (runResult == NSFileHandlingPanelOKButton) {
			unsigned saveFilenameIndex = NSNotFound;
			unsigned                 i = CFArrayGetCount(customHistArray);
			if (i) {
				while (--i) {
					if ([(id)CFArrayGetValueAtIndex(customHistArray, i) isEqual:saveFilename]) {
						saveFilenameIndex = i;
						break;
					}
				}
			}
			if (saveFilenameIndex == NSNotFound) {
				if (CFArrayGetCount(customHistArray) == 3U)
					CFArrayRemoveValueAtIndex(customHistArray, 2);
			} else
				CFArrayRemoveValueAtIndex(customHistArray, saveFilenameIndex);
			CFArrayInsertValueAtIndex(customHistArray, 0, saveFilename);
		}
	} else {
		CFStringRef temp = CFRetain(CFArrayGetValueAtIndex(customHistArray, selected));
		CFArrayRemoveValueAtIndex(customHistArray, selected);
		CFArrayInsertValueAtIndex(customHistArray, 0, temp);
		CFRelease(temp);
	}

	unsigned numHistItems = CFArrayGetCount(customHistArray);
	if (numHistItems) {
		id s = (id)CFArrayGetValueAtIndex(customHistArray, 0);
		[preferencesController setObject:s forKey:GrowlCustomHistKey1];

		if ((numHistItems > 1U) && (s = (id)CFArrayGetValueAtIndex(customHistArray, 1)))
			[preferencesController setObject:s forKey:GrowlCustomHistKey2];

		if ((numHistItems > 2U) && (s = (id)CFArrayGetValueAtIndex(customHistArray, 2)))
			[preferencesController setObject:s forKey:GrowlCustomHistKey3];

		//[[logFileType cellAtRow:1 column:0] setEnabled:YES];
		[logFileType selectCellAtRow:1 column:0];
	}

	[self updateLogPopupMenu];
}

- (void) updateLogPopupMenu {
	[customMenuButton removeAllItems];

	int numHistItems = CFArrayGetCount(customHistArray);
	for (int i = 0U; i < numHistItems; i++) {
		NSArray *pathComponentry = [[(NSString *)CFArrayGetValueAtIndex(customHistArray, i) stringByAbbreviatingWithTildeInPath] pathComponents];
		unsigned numPathComponents = [pathComponentry count];
		if (numPathComponents > 2U) {
			unichar ellipsis = 0x2026;
			NSMutableString *arg = [[NSMutableString alloc] initWithCharacters:&ellipsis length:1U];
			[arg appendString:@"/"];
			[arg appendString:[pathComponentry objectAtIndex:(numPathComponents - 2U)]];
			[arg appendString:@"/"];
			[arg appendString:[pathComponentry objectAtIndex:(numPathComponents - 1U)]];
			[customMenuButton insertItemWithTitle:arg atIndex:i];
			[arg release];
		} else
			[customMenuButton insertItemWithTitle:[(NSString *)CFArrayGetValueAtIndex(customHistArray, i) stringByAbbreviatingWithTildeInPath] atIndex:i];
	}
	// No separator if there's no file list yet
	if (numHistItems > 0)
		[[customMenuButton menu] addItem:[NSMenuItem separatorItem]];
	[customMenuButton addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Browse menu item title", /*tableName*/ nil, [self bundle], /*comment*/ nil)];
	//select first item, if any
	[customMenuButton selectItemAtIndex:numHistItems ? 0 : -1];
}

#pragma mark "Applications" tab pane

- (BOOL) canRemoveTicket {
	return canRemoveTicket;
}

- (void) setCanRemoveTicket:(BOOL)flag {
	canRemoveTicket = flag;
}

- (void) deleteTicket:(id)sender {
#pragma unused(sender)
	GrowlApplicationTicket *ticket = [[ticketsArrayController selectedObjects] objectAtIndex:0U];
	NSString *path = [ticket path];

	if ([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
		NSNumber *pidValue = [[NSNumber alloc] initWithInt:pid];
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			[ticket applicationName], @"TicketName",
			pidValue,                 @"pid",
			nil];
		[pidValue release];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged
																	   object:@"GrowlTicketDeleted"
																	 userInfo:userInfo];
		[userInfo release];
		unsigned idx = [tickets indexOfObject:ticket];
		CFArrayRemoveValueAtIndex(images, idx);

		unsigned oldSelectionIndex = [ticketsArrayController selectionIndex];

		///	Hmm... This doesn't work for some reason....
		//	Even though the same method definitely^H^H^H^H^H^H probably works in the appRegistered: method...

		//	[self removeFromTicketsAtIndex:	[ticketsArrayController selectionIndex]];

		NSMutableArray *newTickets = [tickets mutableCopy];
		[newTickets removeObject:ticket];
		[self setTickets:newTickets];
		[newTickets release];

		if (oldSelectionIndex >= [tickets count])
			oldSelectionIndex = [tickets count] - 1;

		[ticketsArrayController setSelectionIndex:oldSelectionIndex];
	}
}

#pragma mark "Network" tab pane

- (IBAction) showPreview:(id) sender {
#pragma unused(sender)
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreview object:currentPlugin];
}

- (void) loadViewForDisplay:(NSString *)displayName {
	NSView *newView = nil;
	NSPreferencePane *prefPane = nil, *oldPrefPane = nil;

	if (pluginPrefPane)
		oldPrefPane = pluginPrefPane;

	if (displayName) {
		// Old plugins won't support the new protocol. Check first
		if ([currentPluginController respondsToSelector:@selector(preferencePane)])
			prefPane = [currentPluginController preferencePane];

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
	if (!newView)
		newView = displayDefaultPrefView;
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
			[displayPluginsTable setNextKeyView:previewButton];
		}

		if (oldPrefPane)
			[oldPrefPane didUnselect];
	}
}

#pragma mark About Tab

- (void) setupAboutTab {
	[aboutBoxTextView readRTFDFromFile:[[self bundle] pathForResource:@"About" ofType:@"rtf"]];
}

- (IBAction) openGrowlWebSite:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:(NSURL *)growlWebSiteURL];
}

- (IBAction) openGrowlForum:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:(NSURL *)growlForumURL];
}

- (IBAction) openGrowlTrac:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:(NSURL *)growlTracURL];
}

#pragma mark TableView delegate methods

- (void) tableViewDidClickInBody:(NSTableView *)tableView {
	activeTableView = tableView;
	[self setCanRemoveTicket:(activeTableView == growlApplications) && [ticketsArrayController canRemove]];
}

- (IBAction) tableViewDoubleClick:(id)sender {
	if ([ticketsArrayController selectionIndex] != NSNotFound)
		[applicationsTab selectLastTabViewItem:sender];
}

#pragma mark NSNetServiceBrowser Delegate Methods

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
#pragma unused(aNetServiceBrowser)
	// check if a computer with this name has already been added
	NSString *name = [aNetService name];
	NSEnumerator *enumerator = [services objectEnumerator];
	GrowlBrowserEntry *entry;
	while ((entry = [enumerator nextObject]))
		if ([[entry computerName] isEqualToString:name])
			return;

	// don't add the local machine
	CFStringRef localHostName = SCDynamicStoreCopyComputerName(/*store*/ NULL,
															   /*nameEncoding*/ NULL);
	CFComparisonResult isLocalHost = CFStringCompare(localHostName, (CFStringRef)name, 0);
	CFRelease(localHostName);
	if (isLocalHost == kCFCompareEqualTo)
		return;

	// add a new entry at the end
	entry = [[GrowlBrowserEntry alloc] initWithComputerName:name netService:aNetService];
	[self willChangeValueForKey:@"services"];
	[services addObject:entry];
	[self didChangeValueForKey:@"services"];
	[entry release];

	if (!moreComing)
		[self writeForwardDestinations];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
#pragma unused(aNetServiceBrowser)
	// This case is slightly more complicated. We need to find the object in the list and remove it.
	unsigned count = [services count];
	GrowlBrowserEntry *currentEntry;
	NSString *name = [aNetService name];

	for (unsigned i = 0; i < count; ++i) {
		currentEntry = [services objectAtIndex:i];
		if ([[currentEntry computerName] isEqualToString:name]) {
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

	if (!moreComing)
		[self writeForwardDestinations];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender {
	NSArray *addresses = [sender addresses];
	if ([addresses count] > 0U) {
		NSData *address = [addresses objectAtIndex:0U];
		GrowlBrowserEntry *entry = [services objectAtIndex:currentServiceIndex];
		[entry setAddress:address];
		[self writeForwardDestinations];
	}
}

#pragma mark Bonjour

- (void) resolveService:(id)sender {
	int row = [sender selectedRow];
	if (row != -1) {
		GrowlBrowserEntry *entry = [services objectAtIndex:row];
		NSNetService *serviceToResolve = [entry netService];
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
			if ([serviceBeingResolved respondsToSelector:@selector(resolveWithTimeout:)])
				[serviceBeingResolved resolveWithTimeout:5.0];
			else
				// this selector is deprecated in 10.4
				[serviceBeingResolved resolve];
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

- (id) objectInServicesAtIndex:(unsigned)idx {
	return [services objectAtIndex:idx];
}

- (void) insertObject:(id)anObject inServicesAtIndex:(unsigned)idx {
	[services insertObject:anObject atIndex:idx];
}

- (void) replaceObjectInServicesAtIndex:(unsigned)idx withObject:(id)anObject {
	[services replaceObjectAtIndex:idx withObject:anObject];
}

#pragma mark Detecting Growl

- (void) checkGrowlRunning {
	[self setGrowlIsRunning:[preferencesController isGrowlRunning]];
	[self updateRunningStatus];
}

#pragma mark "Display Options" tab pane

- (NSArray *) displayPlugins {
	return plugins;
}

- (void) setDisplayPlugins:(NSArray *)thePlugins {
	if (thePlugins != plugins) {
		[plugins release];
		plugins = [thePlugins retain];
	}
}

#pragma mark -

/*!
 * @brief Refresh preferences when a new application registers with Growl
 */
- (void) appRegistered: (NSNotification *) note {
	NSString *app = [note object];
	GrowlApplicationTicket *newTicket = [[GrowlApplicationTicket alloc] initTicketForApplication:app];

	/*
	 *	Because the tickets array is under KVObservation by the TicketsArrayController
	 *	We need to remove the ticket using the correct KVC method:
	 */

	NSEnumerator *ticketEnumerator = [tickets objectEnumerator];
	GrowlApplicationTicket *ticket;
	int removalIndex = -1;

	int	i = 0;
	while ((ticket = [ticketEnumerator nextObject])) {
		if ([[ticket applicationName] isEqualToString:app]) {
			removalIndex = i;
			break;
		}
		++i;
	}

	if (removalIndex != -1)
		[self removeFromTicketsAtIndex:removalIndex];
	[self insertInTickets:newTicket];
	[newTicket release];

	[self cacheImages];
}

- (void) growlLaunched:(NSNotification *)note {
#pragma unused(note)
	[self setGrowlIsRunning:YES];
	[self updateRunningStatus];
}

- (void) growlTerminated:(NSNotification *)note {
#pragma unused(note)
	[self setGrowlIsRunning:NO];
	[self updateRunningStatus];
}

@end
