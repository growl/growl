//
//  GrowlTunesPreferencesWindowController.m
//  GrowlTunes
//
//  Created by Daniel Siemer on 11/18/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTunesPreferencesWindowController.h"
#import "GrowlTunesController.h"
#import "GrowlTunesFormattingController.h"
#import "FormattingToken.h"
#import "GrowlOnSwitch.h"
#import "GrowlProcessTransformation.h"
#import "StartAtLoginController.h"
#import "iTunes.h"
#import "iTunes+iTunesAdditions.h"

#import "SGHotKeyCenter.h"
#import "SGHotKey.h"
#import "SGKeyCombo.h"

@interface GrowlTunesPreferencesWindowController ()

@property (readonly, nonatomic) GrowlTunesFormattingController *formatController;

@property (nonatomic, assign) IBOutlet NSToolbar *toolbar;
@property (nonatomic, assign) IBOutlet NSToolbarItem *generalItem;
@property (nonatomic, assign) IBOutlet NSToolbarItem *formatItem;

@property (nonatomic, assign) IBOutlet NSView *generalTabView;
@property (nonatomic, assign) IBOutlet GrowlOnSwitch *onLoginSwitch;
@property (nonatomic, assign) IBOutlet NSPopUpButton *iconPopUp;
@property (nonatomic, assign) GrowlTunesIconState oldIconValue;
@property (nonatomic, assign) BOOL oldOnLoginValue;

@property (nonatomic, assign) IBOutlet NSView *formatTabView;
@property (nonatomic, assign) IBOutlet NSView *keyboardTabView;

@property (nonatomic, assign) IBOutlet SRRecorderControl *nowPlayingRecorder;
@property (nonatomic, assign) IBOutlet SRRecorderControl *volumeUpRecorder;
@property (nonatomic, assign) IBOutlet SRRecorderControl *volumeDownRecorder;
@property (nonatomic, assign) IBOutlet SRRecorderControl *nextRecorder;
@property (nonatomic, assign) IBOutlet SRRecorderControl *previousRecorder;
@property (nonatomic, assign) IBOutlet SRRecorderControl *playPauseRecorder;
@property (nonatomic, assign) IBOutlet SRRecorderControl *activateiTunesRecorder;

-(IBAction)selectTab:(id)sender;
@end

@implementation GrowlTunesPreferencesWindowController

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
	return NO;
}

-(id)initWithWindowNibName:(NSString *)windowNibName
{
	if ((self = [super initWithWindowNibName:windowNibName])) {
		// Initialization code here.
	}
	return self;
}

-(GrowlTunesFormattingController*)formatController {
	return [(GrowlTunesController*)NSApp formatController];
}

-(GrowlTunesController*)appDelegate {
	return (GrowlTunesController*)NSApp;
}

-(void)windowDidLoad {
	//Make me load a preference
	[self selectTabIndex:0];
	[_generalItem setLabel:[[self localizedStringsController] stringForKey:@"GeneralTabTitle"]];
	[_formatItem setLabel:[[self localizedStringsController] stringForKey:@"FormatTabTitle"]];
				
	[_onLoginSwitch setState:[[[NSUserDefaultsController sharedUserDefaultsController] defaults] boolForKey:@"OnLogin"]];
	[_onLoginSwitch addObserver:self
						  forKeyPath:@"state"
							  options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
							  context:nil];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																				 forKeyPath:@"values.Visibility"
																					 options:NSKeyValueObservingOptionNew
																					 context:nil];
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
																				 forKeyPath:@"values.OnLogin"
																					 options:NSKeyValueObservingOptionNew
																					 context:nil];

	[self setupHotKeys];
}

- (void)setupHotKeys
{
	NSArray *hotKeys = @[NowPlayingHotKeyIdentifier, VolumeUpHotKeyIdentifier, VolumeDownHotKeyIdentifier, NextTrackHotKeyIdentifier, PreviousTrackHotKeyIdentifier, PlayPauseHotKeyIdentifier, ActivateHotKeyIdentifier];
	NSArray *recorders = @[_nowPlayingRecorder, _volumeUpRecorder, _volumeDownRecorder, _nextRecorder, _previousRecorder, _playPauseRecorder, _activateiTunesRecorder];
	[hotKeys enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger idx, BOOL *stop)
	 {
		 SRRecorderControl *recorder = [recorders objectAtIndex:idx];
		 NSDictionary *plist = [[NSUserDefaults standardUserDefaults] objectForKey:identifier];
		 if(plist)
		 {
			 SGKeyCombo *combo = [[SGKeyCombo alloc] initWithPlistRepresentation:plist];
			 if(([combo keyCode] != -1) && ([combo modifiers] != -1))
			 {
				 KeyCombo srCombo = {combo.modifiers, combo.keyCode};
				 [recorder setKeyCombo:srCombo];
			 }
		 }
		 //we specify the delegate here instead of in the xib so that setting the key combo doesn't cause the save delegate method to be invoked when we assign the load key combo state
		 recorder.delegate = self;
	 }];
}

- (id)localizedStringsController
{
	id returnValue = [[NSApp delegate] performSelector:@selector(localizedStringsController)];
	return returnValue;
}

-(void)showWindow:(id)sender {
	[GrowlProcessTransformation makeForgroundApp];
	[super showWindow:sender];
}

-(void)windowWillClose:(NSNotification *)notification {
	NSNumber *value = [[[NSUserDefaultsController sharedUserDefaultsController] defaults] valueForKey:@"Visibility"];
	GrowlTunesIconState visibility = value != nil ? [value integerValue] : kShowIconInMenu;
	if(visibility == kDontShowIcon || visibility == kShowIconInMenu){
		[GrowlProcessTransformation makeUIElementApp];
	}
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
		GrowlTunesIconState index = value != nil ? [value integerValue] : kShowIconInMenu;
		switch (index) {
			case kDontShowIcon:
				if(![[defaultController defaults] boolForKey:@"SuppressNoIconWarn"])
				{
					[NSApp activateIgnoringOtherApps:YES];
					NSAlert *alert = [NSAlert alertWithMessageText:[[self localizedStringsController] stringForKey:@"BackgroundAlertTitle"]
													 defaultButton:[[self localizedStringsController] stringForKey:@"OkButtonTitle"]
												   alternateButton:[[self localizedStringsController] stringForKey:@"CancelButtonTitle"]
													   otherButton:nil
										 informativeTextWithFormat:@"%@",[[self localizedStringsController] stringForKey:@"BackgroundAlertMessage"]];
					alert.showsSuppressionButton = YES;
					NSInteger allow = [alert runModal];
					if(allow == NSAlertDefaultReturn)
					{
						if([[alert suppressionButton] state] == NSOnState){
							[[defaultController defaults] setBool:YES forKey:@"SuppressNoIconWarn"];
						}
						[self warnUserAboutIcons];
						[[self appDelegate] destroyStatusItem];
					}
					else
					{
						[[defaultController defaults] setInteger:_oldIconValue forKey:@"Visibility"];
						[[defaultController defaults] synchronize];
						[_iconPopUp selectItemAtIndex:_oldIconValue];
					}
				}else{
					[self warnUserAboutIcons];
					[[self appDelegate] destroyStatusItem];
				}
				break;
			case kShowIconInBoth:
				[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
				[[self appDelegate] createStatusItem];
				break;
			case kShowIconInDock:
				[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
				[[self appDelegate] destroyStatusItem];
				break;
			case kShowIconInMenu:
			default:
				[[self appDelegate] createStatusItem];
				if(_oldIconValue == kShowIconInBoth || _oldIconValue == kShowIconInDock)
					[self warnUserAboutIcons];
				break;
		}
		_oldIconValue = index;
	}
	else if ([keyPath isEqualToString:@"values.OnLogin"])
	{
		BOOL state = [[defaultController defaults] boolForKey:@"OnLogin"];
		if(state && (_oldOnLoginValue != state))
		{
			if(![[defaultController defaults] boolForKey:@"SuppressStartAtLogin"])
			{
				[NSApp activateIgnoringOtherApps:YES];
				NSAlert *alert = [NSAlert alertWithMessageText:[[self localizedStringsController] stringForKey:@"AlertTitleStartAtLogin"]
												 defaultButton:[[self localizedStringsController] stringForKey:@"OkButtonTitle"]
														 alternateButton:[[self localizedStringsController] stringForKey:@"CancelButtonTitle"]
															  otherButton:nil
											informativeTextWithFormat:@"%@", [[self localizedStringsController] stringForKey:@"AlertMessageStartAtLogin"]];
				alert.showsSuppressionButton = YES;
				NSInteger allow = [alert runModal];
				if(allow == NSAlertDefaultReturn)
				{
					if([[alert suppressionButton] state] == NSOnState){
						[[defaultController defaults] setBool:YES forKey:@"SuppressStartAtLogin"];
					}
					[[[self appDelegate] loginController] setStartAtLogin:YES];
				}
				else
				{
					[[[self appDelegate] loginController] setStartAtLogin:NO];
					[[defaultController defaults] setBool:_oldOnLoginValue forKey:@"OnLogin"];
					[[defaultController defaults] synchronize];
					[_onLoginSwitch setState:_oldOnLoginValue];
				}
			}else{
				[[[self appDelegate] loginController] setStartAtLogin:YES];
			}
		}
		else{
			[[[self appDelegate] loginController] setStartAtLogin:NO];
		}
		_oldOnLoginValue = state;
	}
	else if(object == _onLoginSwitch && [keyPath isEqualToString:@"state"])
	{
		[[defaultController values] setValue:[NSNumber numberWithBool:[_onLoginSwitch state]] forKey:@"OnLogin"];
		[defaultController save:nil];
	}

}

- (void)warnUserAboutIcons
{
	if((BOOL)isless(NSFoundationVersionNumber, NSFoundationVersionNumber10_7)) {
		NSAlert *alert = AUTORELEASE([[NSAlert alloc] init]);
		[alert setMessageText:[[self localizedStringsController] stringForKey:@"MessageTextEffectiveUponRestart"]];
		[alert runModal];
	}
}

#pragma mark Toolbar/Tab support

-(void)selectTabIndex:(NSInteger)tab {
	if(tab < 0 || tab > 2)
		tab = 0;
	[_toolbar setSelectedItemIdentifier:[NSString stringWithFormat:@"%ld", tab]];
	//Set our new content view
	NSView *currentView = [[self window] contentView];
	NSView *nextView = nil;
	switch (tab) {
		case 2:
			nextView = _keyboardTabView;
			break;
		case 1:
			nextView = _formatTabView;
			break;
		case 0:
		default:
			nextView = _generalTabView;
			break;
	}
	if(currentView != nextView){
		CGRect newFrame = [[self window] frame];
		CGSize newSize = [nextView frame].size;
		newFrame.origin.y -= (newSize.height - newFrame.size.height);
		newFrame.size = newSize;
		
		[[self window] setContentView:AUTORELEASE([[NSView alloc] initWithFrame:NSZeroRect])];
		
		[[self window] setFrame:newFrame display:YES animate:YES];
		[[self window] setContentView:nextView];
		[[self window] makeFirstResponder:nextView];
	}
}

-(IBAction)selectTab:(id)sender {
	[self selectTabIndex:[sender tag]];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
	return YES;
}
-(NSArray*)toolbarSelectableItemIdentifiers:(NSToolbar*)aToolbar {
	return [NSArray arrayWithObjects:@"0", @"1", @"2", nil];
}
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
   return [NSArray arrayWithObjects:@"0", @"1", @"2", nil];
}
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)aToolbar {
   return [NSArray arrayWithObjects:@"0", @"1", @"2", nil];
}

#pragma mark NSTokenField Delegate methods

- (NSArray*)tokenField:(NSTokenField *)tokenField
completionsForSubstring:(NSString *)substring
			 indexOfToken:(NSInteger)tokenIndex
	indexOfSelectedItem:(NSInteger *)selectedIndex
{
	NSMutableArray *buildArray = [NSMutableArray array];
	[[[self formatController] tokenCloud] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if([[obj displayString] rangeOfString:substring options:NSCaseInsensitiveSearch|NSAnchoredSearch].location != NSNotFound ||
			[[obj editingString] rangeOfString:substring options:NSCaseInsensitiveSearch|NSAnchoredSearch].location != NSNotFound)
		{
			[buildArray addObject:[obj editingString]];
		}
	}];
	*selectedIndex = -1;
	return [buildArray sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
	if ([representedObject respondsToSelector:@selector(displayString)]) {
		return [representedObject valueForKey:@"displayString"];
	}
	return representedObject;
}

- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject
{
	if ([representedObject respondsToSelector:@selector(editingString)]) {
		return [representedObject valueForKey:@"editingString"];
	}
	return representedObject;
}

- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
{
	return AUTORELEASE([[FormattingToken alloc] initWithEditingString:editingString]);
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
	if ([representedObject respondsToSelector:@selector(tokenStyle)]) {
		return (NSTokenStyle)[representedObject performSelector:@selector(tokenStyle)];
	}
	return NSPlainTextTokenStyle;
}

- (NSArray*)tokenField:(NSTokenField *)tokenField shouldAddObjects:(NSArray *)tokens atIndex:(NSUInteger)index {
	dispatch_async(dispatch_get_main_queue(), ^{
		[[self formatController] saveTokens];
	});
	return tokens;
}

- (NSArray*)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard {
	NSMutableArray *results = [NSMutableArray array];
	NSArray *pBoardItems = [pboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
	[pBoardItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		FormattingToken *token = [[FormattingToken alloc] initWithEditingString:obj];
		[results addObject:token];
		RELEASE(token);
	}];
	return results;
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard {
	[pboard writeObjects:[objects valueForKey:@"editingString"]];
	return YES;
}

#pragma mark ShortcutRecorder

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	NSString *identifier = nil;
	id target = [NSApp delegate];
	SEL selector = nil;
	SGKeyCombo *combo = [SGKeyCombo keyComboWithKeyCode:newKeyCombo.code modifiers:newKeyCombo.flags];

	if([aRecorder isEqualTo:_nowPlayingRecorder])
	{
		identifier = NowPlayingHotKeyIdentifier;
		selector = @selector(nowPlaying:);
	}
	else if ([aRecorder isEqualTo:_volumeUpRecorder])
	{
		identifier = VolumeUpHotKeyIdentifier;
		selector = @selector(volumeUp:);
	}
	else if ([aRecorder isEqualTo:_volumeDownRecorder])
	{
		identifier = VolumeDownHotKeyIdentifier;
		selector = @selector(volumeDown:);
	}
	else if ([aRecorder isEqualTo:_nextRecorder])
	{
		identifier = NextTrackHotKeyIdentifier;
		selector = @selector(nextTrack:);
	}
	else if ([aRecorder isEqualTo:_previousRecorder])
	{
		identifier = PreviousTrackHotKeyIdentifier;
		selector = @selector(previousTrack:);
	}
	else if ([aRecorder isEqualTo:_playPauseRecorder])
	{
		identifier = PlayPauseHotKeyIdentifier;
		selector = @selector(playPause:);
	}
	else if ([aRecorder isEqualTo:_activateiTunesRecorder])
	{
		identifier = ActivateHotKeyIdentifier;
		selector = @selector(activateItunes:);
	}
	
	if(identifier)
	{		
		if(newKeyCombo.code == -1)
		{
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:identifier];
			[[SGHotKeyCenter sharedCenter] unregisterHotKey:[[SGHotKeyCenter sharedCenter] hotKeyWithIdentifier:identifier]];
		}
		else
		{
			[[NSUserDefaults standardUserDefaults] setObject:[combo plistRepresentation] forKey:identifier];
			combo.modifiers = SRCocoaToCarbonFlags(combo.modifiers);
			SGHotKey *hotKey = [[SGHotKey alloc] initWithIdentifier:identifier keyCombo:combo target:target action:selector];
			
			[[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
		}
	}
}
@end
