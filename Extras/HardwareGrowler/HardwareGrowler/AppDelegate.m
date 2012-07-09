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
#import "ACImageAndTextCell.h"
#import <ServiceManagement/ServiceManagement.h>

#define ShowDevicesTitle     NSLocalizedString(@"Show Connected Devices at Launch", nil)
#define QuitTitle	           NSLocalizedString(@"Quit HardwareGrowler", nil)
#define PreferencesTitle     NSLocalizedString(@"Preferences", nil)
#define OpenPreferencesTitle NSLocalizedString(@"Open HardwareGrowler Preferences...", nil)
#define IconTitle            NSLocalizedString(@"Icon:", nil)
#define StartAtLoginTitle    NSLocalizedString(@"Start HardwareGrowler at Login:", nil)
#define NoPluginPrefsTitle   NSLocalizedString(@"There are no preferences available for this monitor.", @"")
#define ModuleLabel          NSLocalizedString(@"Modules", @"")

@interface AppDelegate ()

@property (nonatomic, assign) ProcessSerialNumber previousPSN;

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize iconPopUp;
@synthesize pluginController;

@synthesize showDevices;
@synthesize quitTitle;
@synthesize preferencesTitle;
@synthesize openPreferencesTitle;
@synthesize iconTitle;
@synthesize startAtLoginTitle;
@synthesize noPluginPrefsTitle;
@synthesize moduleLabel;

@synthesize iconInMenu;
@synthesize iconInDock;
@synthesize iconInBoth;
@synthesize noIcon;

@synthesize toolbar;
@synthesize generalItem;
@synthesize modulesItem;
@synthesize tabView;
@synthesize tableView;
@synthesize moduleColumn;
@synthesize containerView;
@synthesize noPrefsLabel;
@synthesize placeholderView;
@synthesize currentView;

@synthesize previousPSN;

+(void)initialize
{
	[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
																				[NSNumber numberWithBool:NO], @"OnLogin",
																				[NSNumber numberWithBool:YES], @"ShowExisting",
																				[NSNumber numberWithBool:NO], @"GroupNetwork",
																				[NSNumber numberWithInteger:0], @"Visibility", nil]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[super initialize];
}

- (void)dealloc
{
	[showDevices release];
	[quitTitle release];
	[preferencesTitle release];
	[openPreferencesTitle release];
	[iconTitle release];
	[startAtLoginTitle release];
	[noPluginPrefsTitle release];
	[moduleLabel release];
	
	[iconInMenu release];
	[iconInDock release];
	[iconInBoth release];
	[noIcon release];
	[pluginController release];
	[super dealloc];
}

- (void) awakeFromNib {
	self.iconInMenu = NSLocalizedString(@"Show icon in the menubar", @"default option for where the icon should be seen");
	self.iconInDock = NSLocalizedString(@"Show icon in the dock", @"display the icon only in the dock");
	self.iconInBoth = NSLocalizedString(@"Show icon in both", @"display the icon in both the menubar and the dock");
	self.noIcon = NSLocalizedString(@"No icon visible", @"display no icon at all");
	
	[generalItem setLabel:NSLocalizedString(@"General", @"")];
	[modulesItem setLabel:NSLocalizedString(@"Modules", @"")];
	
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
	
	
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0 alpha:.75]];
	[shadow setShadowOffset:CGSizeMake(0.0, -1.0)];
	
	NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:13.0f], NSFontAttributeName,
									  [NSColor colorWithDeviceWhite:0.5f alpha:1.0f], NSForegroundColorAttributeName,
									  shadow, NSShadowAttributeName, nil];
	NSMutableAttributedString *noPrefsAttributed = [[NSMutableAttributedString alloc] initWithString:NoPluginPrefsTitle 
																													  attributes:attrDict];
	[noPrefsAttributed setAlignment:NSCenterTextAlignment range:NSMakeRange(0, [noPrefsAttributed length])];

	
	[noPrefsLabel setAttributedStringValue:noPrefsAttributed];
	[shadow release];
	[noPrefsAttributed release];
	
	ACImageAndTextCell *imageTextCell = [[[ACImageAndTextCell alloc] init] autorelease];
   [moduleColumn setDataCell:imageTextCell];
}

#ifndef NSFoundationVersionNumber10_7
#define NSFoundationVersionNumber10_7   833.1
#endif
- (IBAction)showPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
   if(![self.window isVisible]){
      [self.window center];
      [self.window setFrameAutosaveName:@"HWGrowlerPrefsWindowFrame"];
      [self.window setFrameUsingName:@"HWGrowlerPrefsWindowFrame" force:YES];
   }
	[self.window makeKeyAndOrderFront:sender];
	
	if((BOOL)isgreaterequal(NSFoundationVersionNumber, NSFoundationVersionNumber10_7)) {
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
}

- (void)windowWillClose:(NSNotification *)notification {
	if((BOOL)isgreaterequal(NSFoundationVersionNumber, NSFoundationVersionNumber10_7)) {
		NSNumber *value = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey:@"Visibility"];
		HWGrowlIconState visibility = [value integerValue];
		if(visibility == kDontShowIcon || visibility == kShowIconInMenu){
			dispatch_async(dispatch_get_main_queue(), ^{
				ProcessSerialNumber psn = { 0, kCurrentProcess };
				TransformProcessType(&psn, kProcessTransformToUIElementApplication);
				SetFrontProcess(&previousPSN);
			});
		}
	}
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
	self.quitTitle = QuitTitle;
	self.preferencesTitle = PreferencesTitle;
	self.openPreferencesTitle = OpenPreferencesTitle;
	self.iconTitle = IconTitle;
	self.startAtLoginTitle = StartAtLoginTitle;
	self.noPluginPrefsTitle = NoPluginPrefsTitle;
	self.moduleLabel = ModuleLabel;
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
	NSUserDefaultsController *defaultController = [NSUserDefaultsController sharedUserDefaultsController];
	if([keyPath isEqualToString:@"values.Visibility"])
	{
		NSNumber *value = [[defaultController defaults] valueForKey:@"Visibility"];
		HWGrowlIconState index   = [value integerValue];
		switch (index) {
			case kDontShowIcon:
				if(![[defaultController defaults] boolForKey:@"SuppressNoIconWarn"])
				{
					[NSApp activateIgnoringOtherApps:YES];
					NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! Enabling this option will cause HardwareGrowler to run in the background", nil)
																defaultButton:NSLocalizedString(@"Ok", nil)
															 alternateButton:NSLocalizedString(@"Cancel", nil)
																  otherButton:nil
												informativeTextWithFormat:NSLocalizedString(@"Enabling this option will cause HardwareGrowler to run without showing a dock icon or a menu item.\n\nTo access preferences, tap HardwareGrowler in Launchpad, or open HardwareGrowler in Finder.", nil)];
					alert.showsSuppressionButton = YES;
					[[alert suppressionButton] bind:NSValueBinding
												  toObject:defaultController
											  withKeyPath:@"values.SuppressNoIconWarn"
													options:nil];
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
						[[defaultController defaults] setInteger:oldIconValue forKey:@"Visibility"];
						[[defaultController defaults] synchronize];
						[iconPopUp selectItemAtIndex:oldIconValue];
					}
				}else{
					[self warnUserAboutIcons];
					[[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
					[statusItem release];
					statusItem = nil;
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
		BOOL state = [[defaultController defaults] boolForKey:@"OnLogin"];
		if(state && (oldOnLoginValue != state))
		{
			if(![[defaultController defaults] boolForKey:@"SuppressStartAtLogin"])
			{
				[NSApp activateIgnoringOtherApps:YES];
				NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Alert! Enabling this option will add HardwareGrowler to your login items", nil)
															defaultButton:NSLocalizedString(@"Ok", nil)
														 alternateButton:NSLocalizedString(@"Cancel", nil)
															  otherButton:nil
											informativeTextWithFormat:NSLocalizedString(@"Allowing this will let HardwareGrowler launch everytime you login, so that it is available for applications which use it at all times", nil)];
				alert.showsSuppressionButton = YES;
				[[alert suppressionButton] bind:NSValueBinding
											  toObject:defaultController
										  withKeyPath:@"values.SupressStartAtLogin"
												options:nil];
				NSInteger allow = [alert runModal];
				if(allow == NSAlertDefaultReturn)
				{
					[self setStartAtLogin:YES];
				}
				else
				{
					[self setStartAtLogin:NO];
					[[defaultController defaults] setBool:oldOnLoginValue forKey:@"OnLogin"];
					[[defaultController defaults] synchronize];
					[onLoginSwitch setState:oldOnLoginValue];
				}
			}else{
				[self setStartAtLogin:YES];
			}
		}
		else{
			[self setStartAtLogin:NO];
		}
		oldOnLoginValue = state;
	}
	else if(object == onLoginSwitch && [keyPath isEqualToString:@"state"])
	{
		[[defaultController values] setValue:[NSNumber numberWithBool:[onLoginSwitch state]] forKey:@"OnLogin"];
		[defaultController save:nil];
	}
}

- (void)warnUserAboutIcons
{
	if((BOOL)isless(NSFoundationVersionNumber, NSFoundationVersionNumber10_7)) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert setMessageText:NSLocalizedString(@"This setting will take effect when Hardware Growler restarts",nil)];
		[alert runModal];
	}
}

- (void) setStartAtLogin:(BOOL)enabled {
   if(!SMLoginItemSetEnabled(CFSTR("com.growl.HardwareGrowlerLauncher"), enabled)){
      //NSLog(@"Failure Setting HardwareGrowlLauncher to %@start at login", enabled ? @"" : @"not ");
   }
}

#pragma mark Module Table

-(IBAction)moduleCheckbox:(id)sender {
	NSInteger selection = [tableView clickedRow];
	if(selection >= 0 && (NSUInteger)selection < [[pluginController plugins] count]){
		NSMutableDictionary *pluginDict = [[pluginController plugins] objectAtIndex:selection];
		id<HWGrowlPluginProtocol> plugin = [pluginDict objectForKey:@"plugin"];
		NSString *identifier = [[NSBundle bundleForClass:[plugin class]] bundleIdentifier];
		NSNumber *disabled = [pluginDict objectForKey:@"disabled"];
		
		if([disabled boolValue]){
			if([plugin respondsToSelector:@selector(stopObserving)])
				[plugin stopObserving];
		}else{
			if([plugin respondsToSelector:@selector(startObserving)])
				[plugin startObserving];
		}
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSMutableDictionary *disabledDict = [[[defaults objectForKey:@"DisabledPlugins"] mutableCopy] autorelease];
		if(!disabledDict)
			disabledDict = [NSMutableDictionary dictionary];
		[disabledDict setObject:disabled forKey:identifier];
		[defaults setObject:disabledDict forKey:@"DisabledPlugins"];
		[defaults synchronize];
	}
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSInteger selection = [tableView selectedRow];
	NSView *newView = nil;
	if(selection >= 0 && (NSUInteger)selection < [[pluginController plugins] count]){
		id<HWGrowlPluginProtocol> plugin = [[[pluginController plugins] objectAtIndex:selection] objectForKey:@"plugin"];
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
	[_window recalculateKeyViewLoop];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if (aTableColumn == moduleColumn) {
		NSCell *cell = [aTableColumn dataCellForRow:rowIndex];
		id<HWGrowlPluginProtocol> plugin = [[[pluginController plugins] objectAtIndex:rowIndex] objectForKey:@"plugin"];
		if([plugin preferenceIcon])
			[cell setImage:[plugin preferenceIcon]];
		else{
			static NSImage *placeholder = nil;
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				placeholder = [[NSImage imageNamed:@"HWGPrefsDefault"] retain];
			});
			[cell setImage:placeholder];
		}
   }
	return nil;
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
