//
//  GrowlPreferencePane.m
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPreferencePane.h"
#import "GrowlPreferencesController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlTicketController.h"
#import "GrowlApplicationTicket.h"
#import "GrowlPlugin.h"
#import "GrowlPluginController.h"
#import "GrowlVersionUtilities.h"
#import "GrowlBrowserEntry.h"
#import "NSStringAdditions.h"
#import "TicketsArrayController.h"
#import "ACImageAndTextCell.h"
#import <ApplicationServices/ApplicationServices.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include "CFGrowlAdditions.h"
#include "GrowlPositionPicker.h"

#include <Carbon/Carbon.h>

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
		if (NSRunInformationalAlertPanel(NSLocalizedStringFromTableInBundle(@"System requirements not met", nil, bundle, "Title for the dialogue shown if attempting to run Growl on 10.2 or earlier"),
										 NSLocalizedStringFromTableInBundle(@"Mac OS X 10.3 \"Panther\" or greater is required.", nil, bundle, nil), 
										 NSLocalizedStringFromTableInBundle(@"Quit", nil, bundle, "Quit button title"), 
										 NSLocalizedStringFromTableInBundle(@"Upgrade Mac OS X...", nil, bundle, "Button title"), 
										 nil) == NSAlertAlternateReturn) {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.apple.com/macosx/"]];
		}
		[NSApp terminate:nil];
	}

	if ((self = [super initWithBundle:bundle])) {
		pid = getpid();
		loadedPrefPanes = [[NSMutableArray alloc] init];
		preferencesController = [GrowlPreferencesController sharedController];

		NSNotificationCenter *nc = [NSDistributedNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(growlLaunched:)   name:GROWL_IS_READY object:nil];
		[nc addObserver:self selector:@selector(growlTerminated:) name:GROWL_SHUTDOWN object:nil];
		[nc addObserver:self selector:@selector(reloadPrefs:)     name:GrowlPreferencesChanged object:nil];

		CFStringRef file = (CFStringRef)[bundle pathForResource:@"GrowlDefaults" ofType:@"plist"];
		CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, file, kCFURLPOSIXPathStyle, /*isDirectory*/ false);
		NSDictionary *defaultDefaults = (NSDictionary *)createPropertyListFromURL((NSURL *)fileURL, kCFPropertyListImmutable, NULL, NULL);
		CFRelease(fileURL);
		if (defaultDefaults) {
			[preferencesController registerDefaults:defaultDefaults];
			[defaultDefaults release];
		}
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
	[versionCheckURL release];
	[growlWebSiteURL release];
	[growlForumURL release];
	[growlTracURL release];
	[growlDonateURL release];
	CFRelease(images);
	[super dealloc];
}

- (void) awakeFromNib {
	ACImageAndTextCell *imageTextCell = [[[ACImageAndTextCell alloc] init] autorelease];

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

	growlWebSiteURL = [[NSURL alloc] initWithString:@"http://growl.info"];
	growlForumURL = [[NSURL alloc] initWithString:@"http://forums.cocoaforge.com/viewforum.php?f=6"];
	growlTracURL = [[NSURL alloc] initWithString:@"http://trac.growl.info"];
	growlDonateURL = [[NSURL alloc] initWithString:@"http://growl.info/donate.php"];

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
	
	// bind the global position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[globalPositionPicker bind:@"selectedPosition" toObject:preferencesController withKeyPath:@"selectedPosition" options:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePosition:) name:GrowlPositionPickerChangedSelectionNotification object:globalPositionPicker];

	// bind the app level position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[appPositionPicker bind:@"selectedPosition" toObject:ticketsArrayController withKeyPath:@"selection.selectedPosition" options:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePosition:) name:GrowlPositionPickerChangedSelectionNotification object:appPositionPicker];
	
	[applicationNameAndIconColumn setDataCell:imageTextCell];
	[networkTableView reloadData];
	
	// Select the default style if possible. 
	{
		id arrangedObjects = [displayPluginsArrayController arrangedObjects];
		int count = [arrangedObjects count];
		NSString *defaultDisplayPluginName = [[self preferencesController] defaultDisplayPluginName];
		int defaultStyleRow = NSNotFound;
		for (int i = 0; i < count; i++) {
			if ([[[arrangedObjects objectAtIndex:i] valueForKey:@"CFBundleName"] isEqualToString:defaultDisplayPluginName]) {
				defaultStyleRow = i;
				break;
			}
		}

		if (defaultStyleRow != NSNotFound) {
			/* Wait until the next run loop; otherwise everything isn't finished loading and we throw an exception.
			* This is setting the view for the Displays tab, which isn't initially visible, so the user won't see
			* the flicker. I'm don't know why this is necessary. -evands
			*/
			[self performSelector:@selector(selectRow:)
					   withObject:[NSIndexSet indexSetWithIndex:defaultStyleRow]
					   afterDelay:0];
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(translateSeparatorsInMenu:)
													 name:NSPopUpButtonWillPopUpNotification
												    object:soundMenuButton];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(translateSeparatorsInMenu:)
													 name:NSPopUpButtonWillPopUpNotification
												    object:displayMenuButton];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(translateSeparatorsInMenu:)
													 name:NSPopUpButtonWillPopUpNotification
												    object:notificationDisplayMenuButton];
	}
}

- (void)selectRow:(NSIndexSet *)indexSet
{
	[displayPluginsTable selectRowIndexes:indexSet byExtendingSelection:NO];
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
	return [[self bundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
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
		versionCheckURL = [[NSURL alloc] initWithString:@"http://growl.info/version.xml"];

	NSBundle *bundle = [self bundle];
	NSDictionary *infoDict = [bundle infoDictionary];
	NSString *currVersionNumber = [infoDict objectForKey:(NSString *)kCFBundleVersionKey];
	NSDictionary *productVersionDict = [[NSDictionary alloc] initWithContentsOfURL:versionCheckURL];
	NSString *executableName = [infoDict objectForKey:(NSString *)kCFBundleExecutableKey];
	NSString *latestVersionNumber = [productVersionDict objectForKey:executableName];

	CFURLRef downloadURL = CFURLCreateWithString(kCFAllocatorDefault,
		(CFStringRef)[productVersionDict objectForKey:[executableName stringByAppendingString:@"DownloadURL"]], NULL);
	/*
	 NSLog([[[NSBundle bundleWithIdentifier:GROWL_PREFPANE_BUNDLE_IDENTIFIER] infoDictionary] objectForKey:(NSString *)kCFBundleExecutableKey] );
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
						  /*contextInfo*/ (void *)downloadURL,
						  /*msg*/ NSLocalizedStringFromTableInBundle(@"A newer version of Growl is available online. Would you like to download it now?", nil, [self bundle], @""));
	else
		CFRelease(downloadURL);

	[productVersionDict release];

	[growlVersionProgress stopAnimation:self];
}

- (void) downloadSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
#pragma unused(sheet)
	CFURLRef downloadURL = (CFURLRef)contextInfo;
	if (returnCode == NSAlertDefaultReturn)
		[[NSWorkspace sharedWorkspace] openURL:(NSURL *)downloadURL];
	CFRelease(downloadURL);
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

	NSEnumerator *enumerator = [[ticketsArrayController content] objectEnumerator];
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

//using setTickets: will tip off the controller (KVO).
//use this to set the tickets secretly.
- (void) setTicketsWithoutTellingAnybody:(NSArray *)theTickets {
	if (theTickets != tickets) {
		if (tickets)
			[tickets setArray:theTickets];
		else
			tickets = [theTickets mutableCopy];
	}
}

//we don't need to do any special extra magic here - just being setTickets: is enough to tip off the controller.
- (void) setTickets:(NSArray *)theTickets {
	[self setTicketsWithoutTellingAnybody:theTickets];
}

- (void) removeFromTicketsAtIndex:(int)indexToRemove {
	NSIndexSet *indices = [NSIndexSet indexSetWithIndex:indexToRemove];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"tickets"];

	[tickets removeObjectAtIndex:indexToRemove];

	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"tickets"];
}

- (void) insertInTickets:(GrowlApplicationTicket *)newTicket {
	NSIndexSet *indices = [NSIndexSet indexSetWithIndex:[tickets count]];
	[self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"tickets"];

	[tickets addObject:newTicket];

	[self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indices forKey:@"tickets"];
}

- (void) reloadDisplayPluginView {
	NSArray *selectedPlugins = [displayPluginsArrayController selectedObjects];
	unsigned numPlugins = [plugins count];
	[currentPlugin release];
	if (numPlugins > 0U && selectedPlugins && [selectedPlugins count] > 0U)
		currentPlugin = [[selectedPlugins objectAtIndex:0U] retain];
	else
		currentPlugin = nil;

	NSString *currentPluginName = [currentPlugin objectForKey:(NSString *)kCFBundleNameKey];
	currentPluginController = (GrowlPlugin *)[pluginController pluginInstanceWithName:currentPluginName];
	[self loadViewForDisplay:currentPluginName];
	[displayAuthor setStringValue:[currentPlugin objectForKey:@"GrowlPluginAuthor"]];
	[displayVersion setStringValue:[currentPlugin objectForKey:(NSString *)kCFBundleNameKey]];
}

/*!
 * @brief Called when a distributed GrowlPreferencesChanged notification is received.
 */
- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSNumber *pidValue = [[notification userInfo] objectForKey:@"pid"];
	if (!pidValue || [pidValue intValue] != pid)
		[self reloadPreferences:[notification object]];
	
	[pool release];
}

- (void) updatePosition:(NSNotification *)notification {
	if([notification object] == globalPositionPicker) {
		[preferencesController setInteger:[globalPositionPicker selectedPosition] forKey:GROWL_POSITION_PREFERENCE_KEY];
	}
	else if([notification object] == appPositionPicker) {
		// a cheap hack around selection not providing a workable object
		NSArray *selection = [ticketsArrayController selectedObjects];
		if ([selection count] > 0)
			[[selection objectAtIndex:0] setSelectedPosition:[appPositionPicker selectedPosition]];
	}
}

/*!
 * @brief Reloads the preferences and updates the GUI accordingly.
 */
- (void) reloadPreferences:(NSString *)object {
	if (!object || [object isEqualToString:@"GrowlTicketChanged"]) {
		GrowlTicketController *ticketController = [GrowlTicketController sharedController];
		[ticketController loadAllSavedTickets];
		[self setTickets:[[ticketController allSavedTickets] allValues]];
		[self cacheImages];
	}

	[self setDisplayPlugins:[[GrowlPluginController sharedController] registeredPluginNamesArrayForType:GROWL_VIEW_EXTENSION]];

#ifdef THIS_CODE_WAS_REMOVED_AND_I_DONT_KNOW_WHY
	if (!object || [object isEqualToString:@"GrowlTicketChanged"])
		[self setTickets:[[ticketController allSavedTickets] allValues]];

	[preferencesController setSquelchMode:[preferencesController squelchMode]];
	[preferencesController setGrowlMenuEnabled:[preferencesController isGrowlMenuEnabled]];

	[self cacheImages];
#endif

	// If Growl is enabled, ensure the helper app is launched
	if ([preferencesController boolForKey:GrowlEnabledKey])
		[preferencesController launchGrowl:NO];

	if ([plugins count] > 0U)
		[self reloadDisplayPluginView];
	else
		[self loadViewForDisplay:nil];
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

- (NSArray *) sounds {
	NSMutableArray *soundNames = [[NSMutableArray alloc] init];
	
	NSArray *paths = [NSArray arrayWithObjects:@"/System/Library/Sounds",
												@"/Library/Sounds",
											   [NSString stringWithFormat:@"%@/Library/Sounds", NSHomeDirectory()],
											   nil];

	NSString *directory;
	NSEnumerator *dirEnumerator = [paths objectEnumerator];
	while ((directory = [dirEnumerator nextObject])) {
		BOOL isDirectory = NO;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory]) {
			if (isDirectory) {
				[soundNames addObject:@"-"];
				
				NSArray *files = [[NSFileManager defaultManager] directoryContentsAtPath:directory];

				NSString *filename = nil;
				NSEnumerator *fileEnumerator = [files objectEnumerator];
				while ((filename = [fileEnumerator nextObject])) {
					NSString *file = [filename stringByDeletingPathExtension];
			
					if (![file isEqualToString:@".DS_Store"])
						[soundNames addObject:file];
				}
			}
		}
	}
	
	return [soundNames autorelease];
}

- (void)translateSeparatorsInMenu:(NSNotification *)notification
{
	NSPopUpButton * button = [notification object];
	
	NSMenu *menu = [button menu];
	
	int itemIndex = 0;
	
	while ((itemIndex = [menu indexOfItemWithTitle:@"-"]) != -1) {
		[menu removeItemAtIndex:itemIndex];
		[menu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex];
	}
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


/*
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
}*/

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
	[customMenuButton addItemWithTitle:NSLocalizedStringFromTableInBundle(@"Browse menu item title", nil, [self bundle], nil)];
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
	NSString *appName = [[[ticketsArrayController selectedObjects] objectAtIndex:0U] applicationName];
	NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Are you sure you want to remove %@?", nil, [self bundle], nil), appName]
									 defaultButton:NSLocalizedStringFromTableInBundle(@"Remove", nil, [self bundle], "Button title for removing something")
								   alternateButton:NSLocalizedStringFromTableInBundle(@"Cancel", nil, [self bundle], "Button title for canceling")
									   otherButton:nil
						 informativeTextWithFormat:[NSString stringWithFormat:
													NSLocalizedStringFromTableInBundle(@"This will remove all Growl settings for %@.", nil, [self bundle], ""), appName]];
	[alert setIcon:[[[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForImageResource:@"growl-icon"]] autorelease]];
	[alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(deleteCallbackDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

// this method is used as our callback to determine whether or not to delete the ticket
-(void) deleteCallbackDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)eventID {
#pragma unused(alert)
#pragma unused(eventID)
	if (returnCode == NSAlertDefaultReturn) {
		GrowlApplicationTicket *ticket = [[ticketsArrayController selectedObjects] objectAtIndex:0U];
		NSString *path = [ticket path];

		if ([[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
			CFNumberRef pidValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pid);
			CFStringRef keys[2] = { CFSTR("TicketName"), CFSTR("pid") };
			CFTypeRef   values[2] = { [ticket applicationName], pidValue };
			CFDictionaryRef userInfo = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			CFRelease(pidValue);
			CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
												 (CFStringRef)GrowlPreferencesChanged,
												 CFSTR("GrowlTicketDeleted"),
												 userInfo, false);
			CFRelease(userInfo);
			unsigned idx = [tickets indexOfObject:ticket];
			CFArrayRemoveValueAtIndex(images, idx);

			unsigned oldSelectionIndex = [ticketsArrayController selectionIndex];

			///	Hmm... This doesn't work for some reason....
			//	Even though the same method definitely (?) probably works in the appRegistered: method...

			//	[self removeFromTicketsAtIndex:	[ticketsArrayController selectionIndex]];

			NSMutableArray *newTickets = [tickets mutableCopy];
			[newTickets removeObject:ticket];
			[self setTickets:newTickets];
			[newTickets release];

			if (oldSelectionIndex >= [tickets count])
				oldSelectionIndex = [tickets count] - 1;
			[self cacheImages];
			[ticketsArrayController setSelectionIndex:oldSelectionIndex];
		}
	}
}

-(IBAction)playSound:(id)sender
{
	if([sender indexOfSelectedItem] > 0) // The 0 item is "None"
		[[NSSound soundNamed:[[sender selectedItem] title]] play];
}

#pragma mark "Display" tab pane

- (IBAction) showDisabledDisplays:(id)sender {
#pragma unused(sender)
	[disabledDisplaysList setString:[[pluginController disabledPlugins] componentsJoinedByString:@"\n"]];
	
	[NSApp beginSheet:disabledDisplaysSheet 
	   modalForWindow:[[self mainView] window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction) endDisabledDisplays:(id)sender {
#pragma unused(sender)
	[NSApp endSheet:disabledDisplaysSheet];
	[disabledDisplaysSheet orderOut:disabledDisplaysSheet];
}

// Returns a boolean based on whether any disabled displays are present, used for the 'hidden' binding of the button on the tab
- (BOOL)hasDisabledDisplays {
	return [pluginController disabledPluginsPresent];
}

// Popup buttons that post preview notifications support suppressing the preview with the Option key
- (IBAction) showPreview:(id)sender {
	if(([sender isKindOfClass:[NSPopUpButton class]]) && (GetCurrentKeyModifiers() & optionKey))
		return;
	
	NSDictionary *pluginToUse = currentPlugin;
	
#warning This does not work if the popup button is not using the exact same order as displayPluginsArrayController - a default or separator item breaks it
	if([sender isKindOfClass:[NSPopUpButton class]]) 
		pluginToUse = [[displayPluginsArrayController content] objectAtIndex:[(NSPopUpButton *)sender indexOfSelectedItem]];
			
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreview
																   object:[pluginToUse objectForKey:GrowlPluginInfoKeyName]];
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
	[aboutVersionString setStringValue:[NSString stringWithFormat:@"%@ %@", 
										[[self bundle] objectForInfoDictionaryKey:@"CFBundleName"], 
										[[self bundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
	[aboutBoxTextView readRTFDFromFile:[[self bundle] pathForResource:@"About" ofType:@"rtf"]];
}

- (IBAction) openGrowlWebSite:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:growlWebSiteURL];
}

- (IBAction) openGrowlForum:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:growlForumURL];
}

- (IBAction) openGrowlTrac:(id)sender {
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:growlTracURL];
}

- (IBAction) openGrowlDonate:(id)sender {
 #pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:growlDonateURL];
}
#pragma mark TableView data source methods

- (int) numberOfRowsInTableView:(NSTableView*)tableView {
	if(tableView == networkTableView) {
		return [[self services] count];
	}
	return 0;
}
- (void) tableViewDidClickInBody:(NSTableView *)tableView {
	activeTableView = tableView;
	[self setCanRemoveTicket:(activeTableView == growlApplications) && [ticketsArrayController canRemove]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
#pragma unused(aTableView)
	if(aTableColumn == servicePasswordColumn) {
		[[services objectAtIndex:rowIndex] setPassword:anObject];
	}

}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
#pragma unused(aTableView)
	// we check to make sure we have the image + text column and then set its image manually
	if (aTableColumn == applicationNameAndIconColumn) {
		NSArray *arrangedTickets = [ticketsArrayController arrangedObjects];
		unsigned idx = [tickets indexOfObject:[arrangedTickets objectAtIndex:rowIndex]];
		[[aTableColumn dataCellForRow:rowIndex] setImage:(NSImage *)CFArrayGetValueAtIndex(images,idx)];
	} else if (aTableColumn == servicePasswordColumn) {
		return [[services objectAtIndex:rowIndex] password];
	}

	return nil;
}

- (IBAction) tableViewDoubleClick:(id)sender {
	if ([ticketsArrayController selectionIndex] != NSNotFound) {
		[applicationsTab selectLastTabViewItem:sender];
		[configurationTab selectFirstTabViewItem:sender];
	}
}

#pragma mark NSNetServiceBrowser Delegate Methods

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
#pragma unused(aNetServiceBrowser)
	// check if a computer with this name has already been added
	NSString *name = [aNetService name];
	NSEnumerator *enumerator = [services objectEnumerator];
	GrowlBrowserEntry *entry;
	while ((entry = [enumerator nextObject])) {
		if ([[entry computerName] isEqualToString:name]) {
			[entry setActive:YES];
			return;
		}
	}

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
	NSEnumerator *serviceEnum = [services objectEnumerator];
	GrowlBrowserEntry *currentEntry;
	NSString *name = [aNetService name];

	while ((currentEntry = [serviceEnum nextObject])) {
		if ([[currentEntry computerName] isEqualToString:name]) {
			[currentEntry setActive:NO];
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
		if (theServices) {
			if (services)
				[services setArray:theServices];
			else
				services = [theServices retain];
		} else {
			[services release];
			services = nil;
		}
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
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

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
	
	[pool release];
}

- (void) growlLaunched:(NSNotification *)note {
#pragma unused(note)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[self setGrowlIsRunning:YES];
	[self updateRunningStatus];
	
	[pool release];
}

- (void) growlTerminated:(NSNotification *)note {
#pragma unused(note)
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[self setGrowlIsRunning:NO];
	[self updateRunningStatus];
	
	[pool release];
}

@end
