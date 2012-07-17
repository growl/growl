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

@interface GrowlPreferencePane ()

@property (nonatomic, assign) ProcessSerialNumber previousPSN;

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

@synthesize previousPSN;

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
	
	[super showWindow:sender];
   
   if(!firstOpen){
      if([currentViewController respondsToSelector:@selector(viewWillLoad)])
         [currentViewController viewWillLoad];
      if([currentViewController respondsToSelector:@selector(viewDidLoad)])
         [currentViewController viewDidLoad];
   }
   firstOpen = NO;
	
	ProcessSerialNumber psn = { 0, kCurrentProcess };
	TransformProcessType(&psn, kProcessTransformToForegroundApplication);
	NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
	[nc addObserverForName:NSWorkspaceDidActivateApplicationNotification
						 object:nil
						  queue:[NSOperationQueue mainQueue]
					usingBlock:^(NSNotification *note) {
						ProcessSerialNumber newFrontPSN;
						GetFrontProcess(&newFrontPSN);
						ProcessSerialNumber growlPsn = { 0, kCurrentProcess };
						Boolean result;
						SameProcess(&newFrontPSN, &growlPsn, &result);
						if(!result){
							GetFrontProcess(&previousPSN);
						}
					}];
}

- (void)windowWillClose:(NSNotification *)notification
{
   if([currentViewController respondsToSelector:@selector(viewWillUnload)])
      [currentViewController viewWillUnload];
   
   //This should be seperate when the window has actually closed, but eh
   if([currentViewController respondsToSelector:@selector(viewDidUnload)])
      [currentViewController viewDidUnload];
	
	if([preferencesController menuState] == GrowlNoMenu || [preferencesController menuState] == GrowlStatusMenu){
		dispatch_async(dispatch_get_main_queue(), ^{
			ProcessSerialNumber psn = { 0, kCurrentProcess };
			TransformProcessType(&psn, kProcessTransformToUIElementApplication);
			SetFrontProcess(&previousPSN);
		});
	}
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
	@autoreleasepool{
        id object = [notification object];
        if(!object || [object isEqualToString:GrowlSelectedPrefPane])
            [self setSelectedTab:[preferencesController selectedPreferenceTab]];
	}
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
      
   Class newClass;
    
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

@end
