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
#import "GrowlPluginController.h"
#import "GrowlNotificationDatabase.h"

#import "GrowlPrefsViewController.h"
#import "GrowlGeneralViewController.h"
#import "GrowlApplicationsViewController.h"
#import "GrowlDisplaysViewController.h"
#import "GrowlServerViewController.h"
#import "GrowlAboutViewController.h"

#define GeneralPrefs       @"GeneralPrefs"
#define ApplicationPrefs   @"ApplicationPrefs"
#define DisplayPrefs       @"DisplayPrefs"
#define NetworkPrefs       @"NetworkPrefs"
#define HistoryPrefs       @"HistoryPrefs"
#define AboutPane          @"About"

@interface GrowlPreferencePane (PRIVATE)

- (void) populateDisplaysPopUpButton:(NSPopUpButton *)popUp nameOfSelectedDisplay:(NSString *)nameOfSelectedDisplay includeDefaultMenuItem:(BOOL)includeDefault;

@end

@implementation GrowlPreferencePane
@synthesize services;
@synthesize networkAddressString;
@synthesize currentViewController;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib {
    
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
    
    preferencesController = [GrowlPreferencesController sharedController];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reloadPrefs:)     name:GrowlPreferencesChanged object:nil];
    
    NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"GrowlDefaults" withExtension:@"plist"];
    NSDictionary *defaultDefaults = [NSDictionary dictionaryWithContentsOfURL:fileURL];
    if (defaultDefaults) {
        [preferencesController registerDefaults:defaultDefaults];
    }
   
    [historyTable setAutosaveName:@"GrowlPrefsHistoryTable"];
    [historyTable setAutosaveTableColumns:YES];
    	    
    GrowlNotificationDatabase *db = [GrowlNotificationDatabase sharedInstance];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(growlDatabaseDidUpdate:) 
                                                 name:@"GrowlDatabaseUpdated" 
                                               object:db];
       
    [self reloadPreferences:nil];

}

- (void)showWindow:(id)sender
{
    //if we're visible but not on the active space then go ahead and close the window
    if ([self.window isVisible] && ![self.window isOnActiveSpace])
        [self.window orderOut:self];
        
    //we change the collection behavior so that the window is brought over to the active space
    //instead of restoring its position on its previous home. If we don't perform a collection
    //behavior reset the window will cause us to space jump.
    [self.window setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    [super showWindow:sender];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
   
   if([currentViewController respondsToSelector:@selector(viewWillLoad)])
      [currentViewController viewWillLoad];
   if([currentViewController respondsToSelector:@selector(viewDidLoad)])
      [currentViewController viewDidLoad];
}

- (void)windowWillClose:(NSNotification *)notification
{
   if([currentViewController respondsToSelector:@selector(viewWillUnload)])
      [currentViewController viewWillUnload];
   
   //This should be seperate when the window has actually closed, but eh
   if([currentViewController respondsToSelector:@selector(viewDidUnload)])
      [currentViewController viewDidUnload];
}

#pragma mark -

/*!
 * @brief Returns the bundle version of the Growl.prefPane bundle.
 */
- (NSString *) bundleVersion {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}


/*!
 * @brief Called when a GrowlPreferencesChanged notification is received.
 */
- (void) reloadPrefs:(NSNotification *)notification {
	// ignore notifications which are sent by ourselves
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
   [self reloadPreferences:[notification object]];
	
	[pool release];
}

/*!
 * @brief Reloads the preferences and updates the GUI accordingly.
 */
- (void) reloadPreferences:(NSString *)object {
   if(!object || [object isEqualToString:GrowlHistoryLogEnabled]){
      if([preferencesController isGrowlHistoryLogEnabled])
         [historyOnOffSwitch setSelectedSegment:0];
      else
         [historyOnOffSwitch setSelectedSegment:1];
   }
       
    if(!object || [object isEqualToString:GrowlSelectedPrefPane])
        [self setSelectedTab:[preferencesController selectedPreferenceTab]];

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


#pragma mark Toolbar support

-(void)setSelectedTab:(NSUInteger)tab
{
    [toolbar setSelectedItemIdentifier:[NSString stringWithFormat:@"%lu", tab]];
      
   NSString *newTab = nil;
   Class newClass = [GrowlPrefsViewController class];
   switch (tab) {
      case 0:
         newTab = GeneralPrefs;
         newClass = [GrowlGeneralViewController class];
         break;
      case 1:
         newTab = ApplicationPrefs;
         newClass = [GrowlApplicationsViewController class];
         break;
      case 2:
         newTab = DisplayPrefs;
         newClass = [GrowlDisplaysViewController class];
         break;
      case 3:
         newTab = NetworkPrefs;
         newClass = [GrowlServerViewController class];
         break;
      case 4:
         newTab = HistoryPrefs;
         break;
      case 5:
         newTab = AboutPane;
         newClass = [GrowlAboutViewController class];
         break;
      default:
         newTab = GeneralPrefs;
         NSLog(@"Attempt to view unknown tab");
         break;
   }
   
   if(!prefViewControllers)
      prefViewControllers = [[NSMutableDictionary alloc] init];
   
   GrowlPrefsViewController *oldController = currentViewController;
   GrowlPrefsViewController *nextController = [prefViewControllers valueForKey:newTab];
   if(nextController && nextController == oldController)
      return;
   
   if(!nextController){
      nextController = [[newClass alloc] initWithNibName:newTab
                                                  bundle:nil 
                                             forPrefPane:self];
      [prefViewControllers setValue:nextController forKey:newTab];
      [nextController release];
   }
   
   NSWindow *aWindow = [self window];
   NSRect newFrameRect = [aWindow frameRectForContentRect:[[nextController view] frame]];
   NSRect oldFrameRect = [aWindow frame];
   
   NSSize newSize = newFrameRect.size;
   NSSize oldSize = oldFrameRect.size;
   
   NSRect frame = [aWindow frame];
   frame.size = newSize;
   frame.origin.y -= (newSize.height - oldSize.height);
   
   [oldController viewWillUnload];
   [nextController viewWillLoad];
   [aWindow setContentView:[nextController view]];
   [oldController viewDidUnload];
   [nextController viewDidLoad];
   self.currentViewController = nextController;
   [aWindow setFrame:frame display:YES animate:YES];
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

   NSArray *plugins = [[[GrowlPluginController sharedController] displayPlugins] valueForKey:GrowlPluginInfoKeyName];
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

- (IBAction) toggleHistory:(id)sender
{
   if([(NSSegmentedControl*)sender selectedSegment] == 0){
      [preferencesController setGrowlHistoryLogEnabled:YES];
   }else{
      [preferencesController setGrowlHistoryLogEnabled:NO];
   }
}

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

@end
