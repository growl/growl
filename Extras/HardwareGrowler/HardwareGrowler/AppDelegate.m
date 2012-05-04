//
//  AppDelegate.m
//  HardwareGrowler
//
//  Created by Daniel Siemer on 5/2/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import "GrowlOnSwitch.h"
#import "HWGrowlPluginController.h"
#import <ServiceManagement/ServiceManagement.h>

#define ShowDevicesTitle     NSLocalizedString(@"Show Connected Devices at Launch", nil)
#define GroupNetworkTitle    NSLocalizedString(@"Group Network Notifications", nil)
#define QuitTitle	           NSLocalizedString(@"Quit HardwareGrowler", nil)
#define PreferencesTitle     NSLocalizedString(@"Preferences...", nil)
#define OpenPreferencesTitle NSLocalizedString(@"Open HardwareGrowler Preferences...", nil)
#define IconTitle            NSLocalizedString(@"Icon:", nil)
#define StartAtLoginTitle    NSLocalizedString(@"Start HardwareGrowler at Login:", nil)

@implementation AppDelegate

@synthesize window = _window;
@synthesize iconPopUp;
@synthesize pluginController;

@synthesize showDevices;
@synthesize groupNetworkTitle;
@synthesize quitTitle;
@synthesize preferencesTitle;
@synthesize openPreferencesTitle;
@synthesize iconTitle;
@synthesize startAtLoginTitle;

@synthesize iconInMenu;
@synthesize iconInDock;
@synthesize iconInBoth;
@synthesize noIcon;

@synthesize toolbar;
@synthesize tabView;
@synthesize tableView;
@synthesize containerView;
@synthesize placeholderView;
@synthesize currentView;

- (void)dealloc
{
    [super dealloc];
}

- (void) awakeFromNib {
	self.iconInMenu = NSLocalizedString(@"Show icon in the menubar", @"default option for where the icon should be seen");
	self.iconInDock = NSLocalizedString(@"Show icon in the dock", @"display the icon only in the dock");
	self.iconInBoth = NSLocalizedString(@"Show icon in both", @"display the icon in both the menubar and the dock");
	self.noIcon = NSLocalizedString(@"No icon visible", @"display no icon at all");            
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																				[NSNumber numberWithInteger:1], @"OnLogin",
																				[NSNumber numberWithBool:YES], @"ShowExisting",
																				[NSNumber numberWithBool:NO], @"GroupNetwork",
																				[NSNumber numberWithInteger:0], @"Visibility", nil]];
	
	NSNumber *visibility = [[NSUserDefaults standardUserDefaults] objectForKey:@"Visibility"];
	if(visibility == nil || [visibility integerValue] == kShowIconInDock || [visibility integerValue] == kShowIconInBoth){
		[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	}
	
	if(visibility == nil || [visibility integerValue] == kShowIconInMenu || [visibility integerValue] == kShowIconInBoth){
		[self initMenu];
	}
	
	[onLoginSwitch setState:[[[NSUserDefaultsController sharedUserDefaultsController] defaults] boolForKey:@"OnLogin"]];
   [onLoginSwitch addObserver:self 
						 forKeyPath:@"state" 
							 options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
							 context:nil];
	
	self.pluginController = [[[HWGrowlPluginController alloc] init] autorelease];
}

- (IBAction)showPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
   if(![self.window isVisible]){
      [self.window center];
      [self.window setFrameAutosaveName:@"HWGrowlerPrefsWindowFrame"];
      [self.window setFrameUsingName:@"HWGrowlerPrefsWindowFrame" force:YES];
   }
	[self.window makeKeyAndOrderFront:sender];
}

- (void) initMenu{
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setMenu:statusMenu];
	
	NSString* icon_path = [[NSBundle mainBundle] pathForResource:@"menubarIcon_Normal" ofType:@"png"];
	NSString* icon_path_selected = [[NSBundle mainBundle] pathForResource:@"menubarIcon_Selected" ofType:@"png"];    
	NSImage *icon = [[NSImage alloc] initWithContentsOfFile:icon_path];
	NSImage *icon_selected = [[NSImage alloc] initWithContentsOfFile:icon_path_selected];
	
	[statusItem setImage:icon];
	[statusItem setAlternateImage:icon_selected];
	[icon release];
	[icon_selected release];
	
	[statusItem setHighlightMode:YES];
	
}

- (void) initTitles{
	self.showDevices = ShowDevicesTitle;
	self.groupNetworkTitle = GroupNetworkTitle;
	self.quitTitle = QuitTitle;
	self.preferencesTitle = PreferencesTitle;
	self.openPreferencesTitle = OpenPreferencesTitle;
	self.iconTitle = IconTitle;
	self.startAtLoginTitle = StartAtLoginTitle;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[[self toolbar] setVisible:YES];
	if([[[self toolbar] items] count] == 0){
		[[self toolbar] insertItemWithItemIdentifier:@"General" atIndex:0];
		[[self toolbar] insertItemWithItemIdentifier:@"Modules" atIndex:1];
	}
	[self selectTabIndex:0];
	[self expiryCheck];
	[self initTitles];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
																				 forKeyPath:@"values.Visibility" 
																					 options:NSKeyValueObservingOptionNew 
																					 context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
																				 forKeyPath:@"values.OnLogin" 
																					 options:NSKeyValueObservingOptionNew 
																					 context:nil];
	oldIconValue = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] integerForKey:@"Visibility"];
	oldOnLoginValue = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] boolForKey:@"OnLogin"];
}

- (BOOL) applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self showPreferences:self];
	return YES;
}

- (void)observeValueForKeyPath:(NSString*)keyPath 
							 ofObject:(id)object 
								change:(NSDictionary*)change 
							  context:(void*)context
{
	if([keyPath isEqualToString:@"values.Visibility"])
	{
		
		NSNumber *value = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey:@"Visibility"];
		HWGrowlIconState index   = [value integerValue];
		switch (index) {
			case kDontShowIcon:
				[NSApp activateIgnoringOtherApps:YES];
				NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! Enabling this option will cause HardwareGrowler to run in the background", nil)
															defaultButton:NSLocalizedString(@"Ok", nil)
														 alternateButton:NSLocalizedString(@"Cancel", nil)
															  otherButton:nil
											informativeTextWithFormat:NSLocalizedString(@"Enabling this option will cause HardwareGrowler to run without showing a dock icon or a menu item.\n\nTo access preferences, tap HardwareGrowler in Launchpad, or open HardwareGrowler in Finder.", nil)];
				NSInteger allow = [alert runModal];
				if(allow == NSAlertDefaultReturn)
				{
					[self warnUserAboutIcons];
					[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
					[statusItem release];
					statusItem = nil;
				}
				else
				{
					[[[NSUserDefaultsController sharedUserDefaultsController] defaults] setInteger:oldIconValue forKey:@"Visibility"];
					[[[NSUserDefaultsController sharedUserDefaultsController] defaults] synchronize];
					[iconPopUp selectItemAtIndex:oldIconValue];
				}
				break;
			case kShowIconInBoth:
				[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
				if(!statusItem)
					[self initMenu];
				break;
			case kShowIconInDock:
				[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
				[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
				[statusItem release];
				statusItem = nil;
				break;
			case kShowIconInMenu:
			default:
				if(!statusItem)
					[self initMenu];
				if(oldIconValue == kShowIconInBoth || oldIconValue == kShowIconInDock)
					[self warnUserAboutIcons];
				break;
		}
		oldIconValue = index;
	}
	else if ([keyPath isEqualToString:@"values.OnLogin"])
	{
		BOOL state = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] boolForKey:@"OnLogin"];
		if(!state && (oldOnLoginValue != state))
		{
			[NSApp activateIgnoringOtherApps:YES];
			NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert! Enabling this option will add HardwareGrowler to your login items", nil)
														defaultButton:NSLocalizedString(@"Ok", nil)
													 alternateButton:NSLocalizedString(@"Cancel", nil)
														  otherButton:nil
										informativeTextWithFormat:NSLocalizedString(@"Allowing this will let HardwareGrowler launch everytime you login, so that it is available for applications which use it at all times", nil)];
			NSInteger allow = [alert runModal];
			if(allow == NSAlertDefaultReturn)
			{
				[self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:YES];
			}
			else
			{
				[self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:NO];
				[[[NSUserDefaultsController sharedUserDefaultsController] defaults] setBool:oldOnLoginValue forKey:@"OnLogin"];
				[[[NSUserDefaultsController sharedUserDefaultsController] defaults] synchronize];
				[onLoginSwitch setState:oldOnLoginValue];
			}
		}
		else
			[self setStartAtLogin:[[NSBundle mainBundle] bundlePath] enabled:NO];
		
		oldOnLoginValue = state;
	}
	else if(object == onLoginSwitch && [keyPath isEqualToString:@"state"])
	{
		[[[NSUserDefaultsController sharedUserDefaultsController] defaults] setBool:![(GrowlOnSwitch*)object state] forKey:@"OnLogin"];
		[[[NSUserDefaultsController sharedUserDefaultsController] defaults] synchronize];
	}
}

- (void)warnUserAboutIcons
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:NSLocalizedString(@"This setting will take effect when Hardware Growler restarts",nil)];
	[alert runModal];    
}

- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled {
   NSURL *urlOfLoginItem = [[NSURL URLWithString:path] URLByAppendingPathComponent:@"Contents/Library/LoginItems/GrowlLauncher.app"];
   if(!LSRegisterURL((__bridge CFURLRef)urlOfLoginItem, YES)){
      //NSLog(@"Failure registering %@ with Launch Services", [urlOfLoginItem description]);
   }
   if(!SMLoginItemSetEnabled(CFSTR("com.growl.HardwareGrowlLauncher"), enabled)){
      //NSLog(@"Failure Setting HardwareGrowlLauncher to %@start at login", flag ? @"" : @"not ");
   }
}

#pragma mark Module Table

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selection = [tableView selectedRow];
	NSView *newView = nil;
	if(selection >= 0 && (NSUInteger)selection < [[pluginController plugins] count]){
		id<HWGrowlPluginProtocol> plugin = [[pluginController plugins] objectAtIndex:selection];
		if([plugin preferencePane]){
			newView = [plugin preferencePane];
		}else{
			newView = placeholderView;
		}
	}else
		newView = placeholderView;
	[newView setFrameSize:[containerView frame].size];
	if([currentView superview])
		[currentView removeFromSuperview];
	[containerView addSubview:newView];
	self.currentView = newView;
}

#pragma mark Toolbar

-(void)selectTabIndex:(NSInteger)tab {
	if(tab < 0 || tab > 1)
		tab = 0;
	[toolbar setSelectedItemIdentifier:[NSString stringWithFormat:@"%ld", tab]];
	[tabView selectTabViewItemAtIndex:tab];
}

-(IBAction)selectTab:(id)sender {
	[self selectTabIndex:[sender tag]];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	return YES;
}

-(NSArray*)toolbarSelectableItemIdentifiers:(NSToolbar*)aToolbar
{
	return [NSArray arrayWithObjects:@"0", @"1", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
   return [NSArray arrayWithObjects:@"0", @"1", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)aToolbar 
{
   return [NSArray arrayWithObjects:@"0", @"1", nil];
}

#ifdef BETA
#define DAYSTOEXPIRY 21
- (NSCalendarDate *)dateWithString:(NSString *)str {
	str = [str stringByReplacingOccurrencesOfString:@"  " withString:@" "];
	NSArray *dateParts = [str componentsSeparatedByString:@" "];
	int month = 1;
	NSString *monthString = [dateParts objectAtIndex:0];
	if ([monthString isEqualToString:@"Feb"]) {
		month = 2;
	} else if ([monthString isEqualToString:@"Mar"]) {
		month = 3;
	} else if ([monthString isEqualToString:@"Apr"]) {
		month = 4;
	} else if ([monthString isEqualToString:@"May"]) {
		month = 5;
	} else if ([monthString isEqualToString:@"Jun"]) {
		month = 6;
	} else if ([monthString isEqualToString:@"Jul"]) {
		month = 7;
	} else if ([monthString isEqualToString:@"Aug"]) {
		month = 8;
	} else if ([monthString isEqualToString:@"Sep"]) {
		month = 9;
	} else if ([monthString isEqualToString:@"Oct"]) {
		month = 10;
	} else if ([monthString isEqualToString:@"Nov"]) {
		month = 11;
	} else if ([monthString isEqualToString:@"Dec"]) {
		month = 12;
	}
	
	NSString *dateString = [NSString stringWithFormat:@"%@-%d-%@ 00:00:00 +0000", [dateParts objectAtIndex:2], month, [dateParts objectAtIndex:1]];
	return [NSCalendarDate dateWithString:dateString];
}

- (BOOL)expired
{
	BOOL result = YES;
	
	NSCalendarDate* nowDate = [self dateWithString:[NSString stringWithUTF8String:__DATE__]];
	NSCalendarDate* expiryDate = [nowDate dateByAddingTimeInterval:(60*60*24* DAYSTOEXPIRY)];
	
	if ([expiryDate earlierDate:[NSDate date]] != expiryDate)
		result = NO;
	
	return result;
}

- (void)expiryCheck
{
	if([self expired])
	{
		[NSApp activateIgnoringOtherApps:YES];
		NSInteger alert = NSRunAlertPanel(@"This Beta Has Expired", [NSString stringWithFormat:@"Please download a new version to keep using %@.", [[NSProcessInfo processInfo] processName]], @"Quit", nil, nil);
		if (alert == NSOKButton) 
		{
			[NSApp terminate:self];
		}
	}
}
#else
- (void)expiryCheck{
}
#endif

@end
