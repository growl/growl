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
#import "GrowlHistoryViewController.h"
#import "GrowlRollupPrefsViewController.h"

@interface GrowlPreferencePane (PRIVATE)

- (void) populateDisplaysPopUpButton:(NSPopUpButton *)popUp nameOfSelectedDisplay:(NSString *)nameOfSelectedDisplay includeDefaultMenuItem:(BOOL)includeDefault;

@end

@implementation GrowlPreferencePane
@synthesize networkAddressString;
@synthesize currentViewController;
@synthesize prefViewControllers;

@synthesize settingsWindowTitle;
@synthesize generalItem;
@synthesize applicationsItem;
@synthesize displaysItem;
@synthesize networkItem;
@synthesize rollupItem;
@synthesize historyItem;
@synthesize aboutItem;

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
   
   [settingsWindowTitle release];
	[super dealloc];
}

- (id)initWithWindowNibName:(NSString *)windowNibName {
   if((self = [super initWithWindowNibName:windowNibName])){
      self.settingsWindowTitle = NSLocalizedString(@"Preferences", @"Preferences window title");
   }
   return self;
}

- (void) awakeFromNib {
   [generalItem setLabel:NSLocalizedString(@"General", @"General prefs tab title")];
   [applicationsItem setLabel:NSLocalizedString(@"Applications", @"Application prefs tab title")];
   [displaysItem setLabel:NSLocalizedString(@"Displays", @"Display prefs tab title")];
   [networkItem setLabel:NSLocalizedString(@"Network", @"Network prefs tab title")];
   [rollupItem setLabel:NSLocalizedString(@"Rollup", @"Rollup prefs tab title")];
   [historyItem setLabel:NSLocalizedString(@"History", @"History prefs tab title")];
   [aboutItem setLabel:NSLocalizedString(@"About", @"About prefs tab title")];

    firstOpen = YES;
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
    
    preferencesController = [GrowlPreferencesController sharedController];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(reloadPreferences:) name:GrowlPreferencesChanged object:nil];

    [self reloadPreferences:nil];
}

- (void)showWindow:(id)sender
{   
   [toolbar setVisible:YES];
    //if we're visible but not on the active space then go ahead and close the window
    if ([self.window isVisible] && ![self.window isOnActiveSpace])
        [self.window orderOut:self];
        
    //we change the collection behavior so that the window is brought over to the active space
    //instead of restoring its position on its previous home. If we don't perform a collection
    //behavior reset the window will cause us to space jump.
    [self.window setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
    [super showWindow:sender];
    [self.window setCollectionBehavior:NSWindowCollectionBehaviorMoveToActiveSpace];
   
   if(!firstOpen){
      if([currentViewController respondsToSelector:@selector(viewWillLoad)])
         [currentViewController viewWillLoad];
      if([currentViewController respondsToSelector:@selector(viewDidLoad)])
         [currentViewController viewDidLoad];
   }
   firstOpen = NO;
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
- (void) reloadPreferences:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   
   id object = [notification object];
   if(!object || [object isEqualToString:GrowlSelectedPrefPane])
      [self setSelectedTab:[preferencesController selectedPreferenceTab]];
	
	[pool release];
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

#pragma mark Toolbar support

-(void)setSelectedTab:(NSUInteger)tab
{
   [toolbar setSelectedItemIdentifier:[NSString stringWithFormat:@"%lu", tab]];
      
   Class newClass = [GrowlPrefsViewController class];
   switch (tab) {
      case 0:
         newClass = [GrowlGeneralViewController class];
         break;
      case 1:
         newClass = [GrowlApplicationsViewController class];
         break;
      case 2:
         newClass = [GrowlDisplaysViewController class];
         break;
      case 3:
         newClass = [GrowlServerViewController class];
         break;
      case 4:
         newClass = [GrowlRollupPrefsViewController class];
         break;
      case 5:
         newClass = [GrowlHistoryViewController class];
         break;
      case 6:
         newClass = [GrowlAboutViewController class];
         break;
      default:
         newClass = [GrowlGeneralViewController class];
         NSLog(@"Attempt to view unknown tab, loading general");
         break;
   }
   
   NSString *nibName = [newClass nibName];
   
   if(!prefViewControllers)
      prefViewControllers = [[NSMutableDictionary alloc] init];
   
   GrowlPrefsViewController *oldController = currentViewController;
   GrowlPrefsViewController *nextController = [prefViewControllers valueForKey:nibName];
   if(nextController && nextController == oldController)
      return;
   
   if(!nextController){
      nextController = [[newClass alloc] initWithNibName:nibName
                                                  bundle:nil 
                                             forPrefPane:self];
      [prefViewControllers setValue:nextController forKey:nibName];
      [nextController release];
   }
   
   NSWindow *aWindow = [self window];
   NSRect newFrameRect = [aWindow frameRectForContentRect:[[nextController view] frame]];
   NSRect oldFrameRect = [aWindow frame];
   
   NSSize newSize = newFrameRect.size;
   NSSize oldSize = oldFrameRect.size;
   NSSize minSize = [[self window] minSize];

   if(minSize.width > newSize.width)
      newSize.width = minSize.width;
   
   NSRect frame = [aWindow frame];
   frame.size = newSize;
   frame.origin.y -= (newSize.height - oldSize.height);
    frame.origin.x -= (newSize.width - oldSize.width)/2.0f;
   [oldController viewWillUnload];
   [aWindow setContentView:[[[NSView alloc] initWithFrame:NSZeroRect] autorelease]];
   [oldController viewDidUnload];
    
   self.currentViewController = nextController;
   [aWindow setFrame:frame display:YES animate:YES];
   
   [nextController viewWillLoad];
   [aWindow setContentView:[nextController view]];
   [aWindow makeFirstResponder:[nextController view]];
   [nextController viewDidLoad];
}

-(IBAction)selectedTabChanged:(id)sender
{
    [preferencesController setSelectedPreferenceTab:[[sender itemIdentifier] integerValue]];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return YES;
}

-(NSArray*)toolbarSelectableItemIdentifiers:(NSToolbar*)aToolbar
{
    return [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
   return [NSArray arrayWithObjects:NSToolbarFlexibleSpaceItemIdentifier, @"0", @"1", @"2", @"3", @"4", @"5", @"6", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)aToolbar 
{
   return [NSArray arrayWithObjects:NSToolbarFlexibleSpaceItemIdentifier, @"0", @"1", @"2", @"3", @"4", @"5", @"6", NSToolbarFlexibleSpaceItemIdentifier, nil];
}

-(void)releaseTab:(GrowlPrefsViewController *)tab
{
   if(tab == currentViewController) {
      NSLog(@"Should not let current view controller go for performance on prefs reload");
      return;
   }
   [prefViewControllers removeObjectForKey:[[tab class] nibName]];
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


@end
