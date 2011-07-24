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
#import "GrowlNotificationDatabase.h"
#import "GrowlProcessUtilities.h"
#import "GrowlVersionUtilities.h"
#import "GrowlBrowserEntry.h"
#import "NSStringAdditions.h"
#import "TicketsArrayController.h"
#import "ACImageAndTextCell.h"
#import <ApplicationServices/ApplicationServices.h>
#include <SystemConfiguration/SystemConfiguration.h>
#include "CFGrowlAdditions.h"
#include "GrowlPositionPicker.h"

#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>

#include <Carbon/Carbon.h>

@interface GrowlPreferencePane (PRIVATE)

- (void) populateDisplaysPopUpButton:(NSPopUpButton *)popUp nameOfSelectedDisplay:(NSString *)nameOfSelectedDisplay includeDefaultMenuItem:(BOOL)includeDefault;

@end

@implementation GrowlPreferencePane
@synthesize displayPlugins = plugins;
@synthesize services;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[browser         release];
	[services        release];
	[pluginPrefPane  release];
	[loadedPrefPanes release];
	[tickets         release];
	[plugins         release];
	[currentPlugin   release];
	[images          release];
	[super dealloc];
}

- (void) awakeFromNib {
    
    pid = getpid();
    loadedPrefPanes = [[NSMutableArray alloc] init];
    preferencesController = [GrowlPreferencesController sharedController];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reloadPrefs:)     name:GrowlPreferencesChanged object:nil];
    
    CFStringRef file = (CFStringRef)[[NSBundle mainBundle] pathForResource:@"GrowlDefaults" ofType:@"plist"];
    CFURLRef fileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, file, kCFURLPOSIXPathStyle, false);
    NSDictionary *defaultDefaults = (NSDictionary *)createPropertyListFromURL((NSURL *)fileURL, kCFPropertyListImmutable, NULL, NULL);
    CFRelease(fileURL);
    if (defaultDefaults) {
        [preferencesController registerDefaults:defaultDefaults];
        [defaultDefaults release];
    }

	ACImageAndTextCell *imageTextCell = [[[ACImageAndTextCell alloc] init] autorelease];

	[ticketsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];
	[displayPluginsArrayController addObserver:self forKeyPath:@"selection" options:0 context:nil];

	[self setCanRemoveTicket:NO];

	browser = [[NSNetServiceBrowser alloc] init];

	// create a deep mutable copy of the forward destinations
	NSArray *destinations = [preferencesController objectForKey:GrowlForwardDestinationsKey];
	NSMutableArray *theServices = [NSMutableArray array];
	for(NSDictionary *destination in destinations) {
		GrowlBrowserEntry *entry = [[GrowlBrowserEntry alloc] initWithDictionary:destination];
		[entry setOwner:self];
		[theServices addObject:entry];
		[entry release];
	}
	[self setServices:theServices];

	[browser setDelegate:self];
	//[browser searchForServicesOfType:@"_growl._tcp." inDomain:@""];
	[browser searchForServicesOfType:@"_gntp._tcp." inDomain:@""];
	
	[self setupAboutTab];

	[growlApplications setDoubleAction:@selector(tableViewDoubleClick:)];
	[growlApplications setTarget:self];
	
	// bind the global position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[globalPositionPicker bind:@"selectedPosition" toObject:preferencesController withKeyPath:@"selectedPosition" options:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePosition:) name:GrowlPositionPickerChangedSelectionNotification object:globalPositionPicker];

	// bind the app level position picker programmatically since its a custom view, register for notification so we can handle updating manually
	[appPositionPicker bind:@"selectedPosition" toObject:ticketsArrayController withKeyPath:@"selection.selectedPosition" options:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePosition:) name:GrowlPositionPickerChangedSelectionNotification object:appPositionPicker];
	
    [historyTable setAutosaveName:@"GrowlPrefsHistoryTable"];
    [historyTable setAutosaveTableColumns:YES];
    
	[applicationNameAndIconColumn setDataCell:imageTextCell];
   [serviceNameColumn setDataCell:imageTextCell];
	[networkTableView reloadData];
	    
    GrowlNotificationDatabase *db = [GrowlNotificationDatabase sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(growlDatabaseDidUpdate:) 
                                                 name:@"GrowlDatabaseUpdated" 
                                               object:db];
    
    [self reloadPreferences:nil];

	// Select the default style if possible. 
	{
		id arrangedObjects = [displayPluginsArrayController arrangedObjects];
		NSUInteger count = [arrangedObjects count];
		NSString *defaultDisplayPluginName = [[self preferencesController] defaultDisplayPluginName];
		NSUInteger defaultStyleRow = NSNotFound;
		for (NSUInteger i = 0; i < count; i++) {
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
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

- (void) cacheImages {
	if (images)
		[images removeAllObjects];
	else
		images = [[NSMutableArray alloc] init];

	for(GrowlApplicationTicket *ticket in [ticketsArrayController content]) {
		NSImage *icon = [[[NSImage alloc] initWithData:[ticket iconData]] autorelease];
		[icon setScalesWhenResized:YES];
		[icon setSize:NSMakeSize(32.0, 32.0)];
		[images addObject:icon];
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
	NSUInteger numPlugins = [plugins count];
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
 * @brief Called when a GrowlPreferencesChanged notification is received.
 */
- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	/*NSNumber *pidValue = [[notification userInfo] objectForKey:@"pid"];
	if (!pidValue || [pidValue intValue] != pid)*/
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
    
    if(!object || [object isEqualToString:GrowlSelectedPrefPane])
        [self setSelectedTab:[preferencesController selectedPreferenceTab]];

	self.displayPlugins = [[[GrowlPluginController sharedController] displayPlugins] valueForKey:GrowlPluginInfoKeyName];

	if ([plugins count] > 0U)
		[self reloadDisplayPluginView];
	else
		[self loadViewForDisplay:nil];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
						change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"selection"]) {
		if (object == ticketsArrayController)
			[self setCanRemoveTicket:(activeTableView == growlApplications) && [ticketsArrayController canRemove]];
		else if (object == displayPluginsArrayController)
			[self reloadDisplayPluginView];
	}
}

- (void) writeForwardDestinations {
	NSMutableArray *destinations = [[NSMutableArray alloc] initWithCapacity:[services count]];

	for(GrowlBrowserEntry *entry in services)
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

- (GrowlNotificationDatabase *) historyController {
   if(!historyController)
      historyController = [GrowlNotificationDatabase sharedInstance];
   
   return historyController;
}

- (NSArray *) sounds {
	NSMutableArray *soundNames = [[NSMutableArray alloc] init];
	
	NSArray *paths = [NSArray arrayWithObjects:@"/System/Library/Sounds",
												@"/Library/Sounds",
											   [NSString stringWithFormat:@"%@/Library/Sounds", NSHomeDirectory()],
											   nil];

	for (NSString *directory in paths) {
		BOOL isDirectory = NO;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory]) {
			if (isDirectory) {
				[soundNames addObject:@"-"];
				
				NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];

				for (NSString *filename in files) {
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
	
	NSInteger itemIndex = 0;
	
	while ((itemIndex = [menu indexOfItemWithTitle:@"-"]) != -1) {
		[menu removeItemAtIndex:itemIndex];
		[menu insertItem:[NSMenuItem separatorItem] atIndex:itemIndex];
	}
}


#pragma mark Toolbar support

-(void)setSelectedTab:(NSUInteger)tab
{
    [toolbar setSelectedItemIdentifier:[NSString stringWithFormat:@"%lu", tab]];
}

-(IBAction)selectedTabChanged:(id)sender
{
    [preferencesController setSelectedPreferenceTab:[[sender itemIdentifier] integerValue]];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [[toolbar visibleItems] containsObject:theItem];
}

-(NSArray*)toolbarSelectableItems:(NSToolbar*)theToolbar
{
    return [toolbar visibleItems];
}

#pragma mark "General" tab pane

#pragma mark "Applications" tab pane

- (BOOL) canRemoveTicket {
	return canRemoveTicket;
}

- (void) setCanRemoveTicket:(BOOL)flag {
	canRemoveTicket = flag;
}

- (void) deleteTicket:(id)sender {
	NSString *appName = [[[ticketsArrayController selectedObjects] objectAtIndex:0U] applicationName];
	NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Are you sure you want to remove %@?", nil, [NSBundle mainBundle], nil), appName]
									 defaultButton:NSLocalizedStringFromTableInBundle(@"Remove", nil, [NSBundle mainBundle], "Button title for removing something")
								   alternateButton:NSLocalizedStringFromTableInBundle(@"Cancel", nil, [NSBundle mainBundle], "Button title for canceling")
									   otherButton:nil
						 informativeTextWithFormat:[NSString stringWithFormat:
													NSLocalizedStringFromTableInBundle(@"This will remove all Growl settings for %@.", nil, [NSBundle mainBundle], ""), appName]];
	[alert setIcon:[[[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForImageResource:@"growl-icon"]] autorelease]];
	[alert beginSheetModalForWindow:[[NSApplication sharedApplication] keyWindow] modalDelegate:self didEndSelector:@selector(deleteCallbackDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

// this method is used as our callback to determine whether or not to delete the ticket
-(void) deleteCallbackDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)eventID {
	if (returnCode == NSAlertDefaultReturn) {
		GrowlApplicationTicket *ticket = [[ticketsArrayController selectedObjects] objectAtIndex:0U];
		NSString *path = [ticket path];

		if ([[NSFileManager defaultManager] removeItemAtPath:path error:nil]) {
			CFNumberRef pidValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pid);
			CFStringRef keys[2] = { CFSTR("TicketName"), CFSTR("pid") };
			CFTypeRef   values[2] = { [ticket applicationName], pidValue };
			CFDictionaryRef userInfo = CFDictionaryCreate(kCFAllocatorDefault, (const void **)keys, (const void **)values, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			CFRelease(pidValue);
			CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
												 (CFStringRef)GrowlPreferencesChanged,
												 CFSTR("GrowlTicketDeleted"),
												 userInfo, false);
			CFRelease(userInfo);
			NSUInteger idx = [tickets indexOfObject:ticket];
			[images removeObjectAtIndex:idx];

			NSUInteger oldSelectionIndex = [ticketsArrayController selectionIndex];

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

- (IBAction) showApplicationConfigurationTab:(id)sender {
	if ([ticketsArrayController selectionIndex] != NSNotFound) {
		[self populateDisplaysPopUpButton:displayMenuButton nameOfSelectedDisplay:[[ticketsArrayController selection] valueForKey:@"displayPluginName"] includeDefaultMenuItem:YES];
		[self populateDisplaysPopUpButton:notificationDisplayMenuButton nameOfSelectedDisplay:[[notificationsArrayController selection] valueForKey:@"displayPluginName"] includeDefaultMenuItem:YES];

		[applicationsTab selectLastTabViewItem:sender];
		[configurationTab selectFirstTabViewItem:sender];
	}
}

- (IBAction) changeNameOfDisplayForApplication:(id)sender {
	NSString *newDisplayPluginName = [[sender selectedItem] representedObject];
	[[ticketsArrayController selectedObjects] setValue:newDisplayPluginName forKey:@"displayPluginName"];
	[self showPreview:sender];
}
- (IBAction) changeNameOfDisplayForNotification:(id)sender {
	NSString *newDisplayPluginName = [[sender selectedItem] representedObject];
	[[notificationsArrayController selectedObjects] setValue:newDisplayPluginName forKey:@"displayPluginName"];
	[self showPreview:sender];
}

- (NSIndexSet *) selectedNotificationIndexes {
	return selectedNotificationIndexes;
}
- (void) setSelectedNotificationIndexes:(NSIndexSet *)newSelectedNotificationIndexes {
	if(selectedNotificationIndexes != newSelectedNotificationIndexes) {
		[selectedNotificationIndexes release];
		selectedNotificationIndexes = [newSelectedNotificationIndexes copy];

		NSInteger indexOfMenuItem = [[notificationDisplayMenuButton menu] indexOfItemWithRepresentedObject:[[notificationsArrayController selection] valueForKey:@"displayPluginName"]];
		if (indexOfMenuItem < 0)
			indexOfMenuItem = 0;
		[notificationDisplayMenuButton selectItemAtIndex:indexOfMenuItem];
	}
}

#pragma mark "Display" tab pane

- (IBAction) showDisabledDisplays:(id)sender {
	[disabledDisplaysList setString:[[pluginController disabledPlugins] componentsJoinedByString:@"\n"]];
	
	[NSApp beginSheet:disabledDisplaysSheet 
	   modalForWindow:[self window]
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction) endDisabledDisplays:(id)sender {
	[NSApp endSheet:disabledDisplaysSheet];
	[disabledDisplaysSheet orderOut:disabledDisplaysSheet];
}

// Returns a boolean based on whether any disabled displays are present, used for the 'hidden' binding of the button on the tab
- (BOOL)hasDisabledDisplays {
	return [pluginController disabledPluginsPresent];
}

// Popup buttons that post preview notifications support suppressing the preview with the Option key
- (IBAction) showPreview:(id)sender {
	if(([sender isKindOfClass:[NSPopUpButton class]]) && ([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask))
		return;
	
	NSDictionary *pluginToUse = currentPlugin;
	NSString *pluginName = nil;
	
	if ([sender isKindOfClass:[NSPopUpButton class]]) {
		NSPopUpButton *popUp = (NSPopUpButton *)sender;
		id representedObject = [[popUp selectedItem] representedObject];
		if ([representedObject isKindOfClass:[NSDictionary class]])
			pluginToUse = representedObject;
		else if ([representedObject isKindOfClass:[NSString class]])
			pluginName = representedObject;
		else
			NSLog(@"%s: WARNING: Pop-up button menu item had represented object of class %@: %@", __func__, [representedObject class], representedObject);
	}

	if (!pluginName)
		pluginName = [pluginToUse objectForKey:GrowlPluginInfoKeyName];
			
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreview
																   object:pluginName];
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
		[newView setFrame:[displayPrefView frame]];
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
	NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	if (versionString) {
		NSString *versionStringWithHgVersion = nil;
		struct Version version;
		if (parseVersionString(versionString, &version) && (version.releaseType == releaseType_development)) {
			const char *hgRevisionUTF8 = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"GrowlHgRevision"] UTF8String];
			if (hgRevisionUTF8) {
				version.development = (u_int32_t)strtoul(hgRevisionUTF8, /*next*/ NULL, 10);

				versionStringWithHgVersion = [NSMakeCollectable(createVersionDescription(version)) autorelease];
			}
		}
		if (versionStringWithHgVersion)
			versionString = versionStringWithHgVersion;
	}

	[aboutVersionString setStringValue:[NSString stringWithFormat:@"%@ %@", 
										[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"], 
										versionString]];
	[aboutBoxTextView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"About" ofType:@"rtf"]];
}

- (IBAction) openGrowlWebSite:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info"]];
}

- (IBAction) openGrowlBugSubmissionPage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://growl.info/reportabug.php"]];
}

#pragma mark Network Tab Methods

- (IBAction) removeSelectedForwardDestination:(id)sender
{
   GrowlBrowserEntry *toRemove = [services objectAtIndex:[networkTableView selectedRow]];
   [networkTableView noteNumberOfRowsChanged];
   [self willChangeValueForKey:@"services"];
   [services removeObjectAtIndex:[networkTableView selectedRow]];
   [self didChangeValueForKey:@"services"];
   [self writeForwardDestinations];
   
   if(![toRemove password])
      return;

   OSStatus status;
	SecKeychainItemRef itemRef = nil;
	const char *uuidChars = [[toRemove uuid] UTF8String];
	status = SecKeychainFindGenericPassword(NULL,
                                           (UInt32)strlen("GrowlOutgoingNetworkConnection"), "GrowlOutgoingNetworkConnection",
                                           (UInt32)strlen(uuidChars), uuidChars,
                                           NULL, NULL, &itemRef);
   if (status == errSecItemNotFound) {
      // Do nothing, we cant find it
	} else {
		status = SecKeychainItemDelete(itemRef);
      if(status != errSecSuccess)
         NSLog(@"Error deleting the password for %@: %@", [toRemove computerName], SecCopyErrorMessageString(status, NULL));
		if (itemRef)
			CFRelease(itemRef);
   }
}

- (IBAction)newManualForwader:(id)sender {
    GrowlBrowserEntry *newEntry = [[[GrowlBrowserEntry alloc] initWithComputerName:@""] autorelease];
    [newEntry setManualEntry:YES];
    [newEntry setOwner:self];
    [networkTableView noteNumberOfRowsChanged];
    [self willChangeValueForKey:@"services"];
    [services addObject:newEntry];
    [self didChangeValueForKey:@"services"];
}

#pragma mark TableView data source methods

- (NSInteger) numberOfRowsInTableView:(NSTableView*)tableView {
	if(tableView == networkTableView) {
		return [[self services] count];
	}
	return 0;
}
- (void) tableViewDidClickInBody:(NSTableView *)tableView {
	activeTableView = tableView;
	[self setCanRemoveTicket:(activeTableView == growlApplications) && [ticketsArrayController canRemove]];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if(aTableColumn == servicePasswordColumn) {
		[[services objectAtIndex:rowIndex] setPassword:anObject];
	}

}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	// we check to make sure we have the image + text column and then set its image manually
	if (aTableColumn == applicationNameAndIconColumn) {
		NSArray *arrangedTickets = [ticketsArrayController arrangedObjects];
		NSUInteger idx = [tickets indexOfObject:[arrangedTickets objectAtIndex:rowIndex]];
		[[aTableColumn dataCellForRow:rowIndex] setImage:[images objectAtIndex:idx]];
	} else if (aTableColumn == servicePasswordColumn) {
		return [[services objectAtIndex:rowIndex] password];
	} else if (aTableColumn == serviceNameColumn) {
        NSCell *cell = [aTableColumn dataCellForRow:rowIndex];
        static NSImage *manualImage = nil;
        static NSImage *bonjourImage = nil;
        if(!manualImage){
            manualImage = [[NSImage imageNamed:NSImageNameNetwork] retain];
            bonjourImage = [[NSImage imageNamed:NSImageNameBonjour] retain];
            NSSize imageSize = NSMakeSize([cell cellSize].height, [cell cellSize].height);
            [manualImage setSize:imageSize];
            [bonjourImage setSize:imageSize];
        }
        GrowlBrowserEntry *entry = [services objectAtIndex:rowIndex];
        if([entry manualEntry])
            [cell setImage:manualImage];
        else
            [cell setImage:bonjourImage];
    }

	return nil;
}

- (IBAction) tableViewDoubleClick:(id)sender {
	[self showApplicationConfigurationTab:sender];
}

#pragma mark NSNetServiceBrowser Delegate Methods

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	// check if a computer with this name has already been added
	NSString *name = [aNetService name];
	GrowlBrowserEntry *entry = nil;
	for (entry in services) {
		if ([[entry computerName] caseInsensitiveCompare:name] == NSOrderedSame) {
			[entry setActive:YES];
			return;
		}
	}

	// don't add the local machine    
    if([name isLocalHost])
        return;

	// add a new entry at the end
	entry = [[GrowlBrowserEntry alloc] initWithComputerName:name];
	[self willChangeValueForKey:@"services"];
	[services addObject:entry];
	[self didChangeValueForKey:@"services"];
	[entry release];

	if (!moreComing)
		[self writeForwardDestinations];
}

- (void) netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
	
	NSString *name = [aNetService name];
	for (GrowlBrowserEntry *currentEntry in services) {
		if ([[currentEntry computerName] isEqualToString:name]) {
			[currentEntry setActive:NO];
			break;
		}
	}

	if (!moreComing)
		[self writeForwardDestinations];
}

#pragma mark Bonjour

- (NSUInteger) countOfServices {
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


#pragma mark Display pop-up menus

//Empties the pop-up menu and fills it out with a menu item for each display, optionally including a special menu item for the default display, selecting the menu item whose name is nameOfSelectedDisplay.
- (void) populateDisplaysPopUpButton:(NSPopUpButton *)popUp nameOfSelectedDisplay:(NSString *)nameOfSelectedDisplay includeDefaultMenuItem:(BOOL)includeDefault {
	NSMenu *menu = [popUp menu];
	NSString *nameOfDisplay = nil, *displayNameOfDisplay;

	NSMenuItem *selectedItem = nil;

	[popUp removeAllItems];

	if (includeDefault) {
		displayNameOfDisplay = NSLocalizedStringFromTableInBundle(@"Default", nil, [NSBundle bundleForClass:[self class]], /*comment*/ @"Title of menu item for default display");
		NSMenuItem *item = [menu addItemWithTitle:displayNameOfDisplay
										   action:NULL
									keyEquivalent:@""];
		[item setRepresentedObject:nil];

		if (!nameOfSelectedDisplay)
			selectedItem = item;

		[menu addItem:[NSMenuItem separatorItem]];
	}

	for (nameOfDisplay in [plugins sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
		displayNameOfDisplay = [[pluginController pluginDictionaryWithName:nameOfDisplay] pluginHumanReadableName];
		if (!displayNameOfDisplay)
			displayNameOfDisplay = nameOfDisplay;

		NSMenuItem *item = [menu addItemWithTitle:displayNameOfDisplay
										   action:NULL
									keyEquivalent:@""];
		[item setRepresentedObject:nameOfDisplay];

		if (nameOfSelectedDisplay && [nameOfSelectedDisplay respondsToSelector:@selector(isEqualToString:)] && [nameOfSelectedDisplay isEqualToString:nameOfDisplay])
			selectedItem = item;
	}

	[popUp selectItem:selectedItem];
}

#pragma mark HistoryTab

-(void)growlDatabaseDidUpdate:(NSNotification*)notification
{
    [historyArrayController fetch:self];
}

-(IBAction)validateHistoryTrimSetting:(id)sender
{
   if([trimByDateCheck state] == NSOffState && [trimByCountCheck state] == NSOffState)
   {
      NSLog(@"User tried turning off both automatic trim options");
      NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Turning off both automatic trim functions is not allowed.", nil)
                                       defaultButton:NSLocalizedString(@"Ok", nil)
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:NSLocalizedString(@"To prevent the history database from growing indefinitely, at least one type of automatic trim must be active", nil)];
      [alert runModal];
      if ([sender isEqualTo:trimByDateCheck]) {
         [preferencesController setGrowlHistoryTrimByDate:YES];
      }
      
      if([sender isEqualTo:trimByCountCheck]){
         [preferencesController setGrowlHistoryTrimByCount:YES];
      }
   }
}

- (IBAction) deleteSelectedHistoryItems:(id)sender
{
   [[GrowlNotificationDatabase sharedInstance] deleteSelectedObjects:[historyArrayController selectedObjects]];
}

- (IBAction) clearAllHistory:(id)sender
{
   NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! About to delete ALL history", nil)
                                    defaultButton:NSLocalizedString(@"Cancel", nil)
                                  alternateButton:NSLocalizedString(@"Ok", nil)
                                      otherButton:nil
                        informativeTextWithFormat:NSLocalizedString(@"This action cannot be undone, please confirm that you want to delete the entire notification history", nil)];
   [alert beginSheetModalForWindow:[sender window]
                     modalDelegate:self
                    didEndSelector:@selector(clearAllHistoryAlert:didReturn:contextInfo:)
                       contextInfo:nil];
}

- (IBAction) clearAllHistoryAlert:(NSAlert*)alert didReturn:(NSInteger)returnCode contextInfo:(void*)contextInfo
{
   switch (returnCode) {
      case NSAlertDefaultReturn:
         NSLog(@"Doing nothing");
         break;
      case NSAlertAlternateReturn:
         [[GrowlNotificationDatabase sharedInstance] deleteAllHistory];
         break;
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

	int removalIndex = -1;
	int	i = 0;
	for (GrowlApplicationTicket *ticket in tickets) {
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

@end
