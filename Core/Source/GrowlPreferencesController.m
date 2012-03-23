//
//  GrowlPreferencesController.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Renamed from GrowlPreferences.m by Peter Hosey on 2005-06-27.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlPreferencesController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlProcessUtilities.h"
#import "NSStringAdditions.h"
#import "GrowlNotificationDatabase.h"
#import "GrowlApplicationController.h"
#include "CFURLAdditions.h"
#import <GrowlPlugins/SGKeyCombo.h>
#import <GrowlPlugins/SGHotKey.h>
#import <GrowlPlugins/SGHotKeyCenter.h>
#import <GrowlPlugins/GrowlKeychainUtilities.h>
#import <GrowlPlugins/GrowlIdleStatusObserver.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

#import <ServiceManagement/ServiceManagement.h>

CFTypeRef GrowlPreferencesController_objectForKey(CFTypeRef key) {
	return [[GrowlPreferencesController sharedController] objectForKey:(id)key];
}

CFIndex GrowlPreferencesController_integerForKey(CFTypeRef key) {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppIntegerValue((CFStringRef)key, (CFStringRef)GROWL_HELPERAPP_BUNDLE_IDENTIFIER, &keyExistsAndHasValidFormat);
}

Boolean GrowlPreferencesController_boolForKey(CFTypeRef key) {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppBooleanValue((CFStringRef)key, (CFStringRef)GROWL_HELPERAPP_BUNDLE_IDENTIFIER, &keyExistsAndHasValidFormat);
}

unsigned short GrowlPreferencesController_unsignedShortForKey(CFTypeRef key)
{
	CFIndex theIndex = GrowlPreferencesController_integerForKey(key);
	
	if (theIndex > USHRT_MAX)
		return USHRT_MAX;
	else if (theIndex < 0)
		return 0;
	return (unsigned short)theIndex;
}

@implementation GrowlPreferencesController
@synthesize idleThreshold;
@synthesize idleMultiplier;
@synthesize useIdleByTime;
@synthesize useIdleByScreensaver;
@synthesize useIdleByScreenLock;
@synthesize idleTimeExceptionApps;

@synthesize rollupKeyCombo;
@synthesize closeAllCombo;

+ (GrowlPreferencesController *) sharedController {
	static GrowlPreferencesController *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (id) init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
															  selector:@selector(growlPreferencesChanged:)
																	name:GrowlPreferencesChanged
																 object:nil];
		
		//configure for rollup hotkey
		[self addObserver:self forKeyPath:@"rollupKeyCombo" options:NSKeyValueObservingOptionNew context:&self];
		
		NSNumber *code = [[NSUserDefaults standardUserDefaults] objectForKey:GrowlRollupKeyComboCode];
		NSNumber *modifiers = [[NSUserDefaults standardUserDefaults] objectForKey:GrowlRollupKeyComboFlags];
		if(code && modifiers)
			self.rollupKeyCombo = [SGKeyCombo keyComboWithKeyCode:[code integerValue] modifiers:[modifiers unsignedIntegerValue]];
		
		//configure for close all hotkey
		[self addObserver:self forKeyPath:@"closeAllCombo" options:NSKeyValueObservingOptionNew context:&self];
		
		code = [[NSUserDefaults standardUserDefaults] objectForKey:GrowlCloseAllKeyComboCode];
		modifiers = [[NSUserDefaults standardUserDefaults] objectForKey:GrowlCloseAllKeyComboFlags];
		if(code && modifiers)
			self.closeAllCombo = [SGKeyCombo keyComboWithKeyCode:[code integerValue] modifiers:[modifiers unsignedIntegerValue]];
		
	}
	return self;
}

- (void) dealloc {
    [self removeObserver:self forKeyPath:@"rollupKeyCombo"];
    [self removeObserver:self forKeyPath:@"closeAllCombo"];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if([keyPath isEqualToString:@"rollupKeyCombo"])
    {
        if(self.rollupKeyCombo.keyCode)
        {
            SGHotKey *hotKey = [[[SGHotKey alloc] initWithIdentifier:showHideHotKey keyCombo:self.rollupKeyCombo target:[GrowlApplicationController sharedController] action:@selector(toggleRollup)] autorelease];
            [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:self.rollupKeyCombo.keyCode] forKey:GrowlRollupKeyComboCode];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:self.rollupKeyCombo.modifiers] forKey:GrowlRollupKeyComboFlags];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else
        {
            SGHotKey *rollupKey = [[SGHotKeyCenter sharedCenter] hotKeyWithIdentifier:showHideHotKey];
            [[SGHotKeyCenter sharedCenter] unregisterHotKey:rollupKey];
            
        }
    }
    else if([keyPath isEqualToString:@"closeAllCombo"])
    {
        if(self.closeAllCombo.keyCode)
        {
            SGHotKey *hotKey = [[[SGHotKey alloc] initWithIdentifier:closeAllHotKey keyCombo:self.closeAllCombo target:[GrowlApplicationController sharedController] action:@selector(closeAllNotifications)] autorelease];
            [[SGHotKeyCenter sharedCenter] registerHotKey:hotKey];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:self.closeAllCombo.keyCode] forKey:GrowlCloseAllKeyComboCode];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithUnsignedInteger:self.closeAllCombo.modifiers] forKey:GrowlCloseAllKeyComboFlags];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        else
        {
            SGHotKey *rollupKey = [[SGHotKeyCenter sharedCenter] hotKeyWithIdentifier:closeAllHotKey];
            [[SGHotKeyCenter sharedCenter] unregisterHotKey:rollupKey];
            
        }
    }
}

#pragma mark -

- (void) registerDefaults:(NSDictionary *)inDefaults {
	NSUserDefaults *helperAppDefaults = [[NSUserDefaults alloc] init];
	[helperAppDefaults addSuiteNamed:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
	NSDictionary *existing = [helperAppDefaults persistentDomainForName:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
	if (existing) {
		NSMutableDictionary *domain = [inDefaults mutableCopy];
		[domain addEntriesFromDictionary:existing];
		[helperAppDefaults setPersistentDomain:domain forName:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
		[domain release];
	} else {
		[helperAppDefaults setPersistentDomain:inDefaults forName:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
	}
	[helperAppDefaults release];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	self.idleThreshold = [self objectForKey:GrowlIdleThresholdKey];
	self.idleMultiplier = [self integerForKey:GrowlIdleMultiplierKey];
	self.useIdleByTime = [self boolForKey:GrowlIdleByTimeKey];
	self.useIdleByScreensaver = [self boolForKey:GrowlIdleByScreensaverKey];
	self.useIdleByScreenLock = [self boolForKey:GrowlIdleByScreenLockKey];
	self.idleTimeExceptionApps = [self objectForKey:GrowlIdleTimeExceptionsKey];
}

- (id) objectForKey:(NSString *)key {
	id value = (id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)GROWL_HELPERAPP_BUNDLE_IDENTIFIER);
	if(value)
		CFMakeCollectable(value);
	return [value autorelease];
}

- (void) setObject:(id)object forKey:(NSString *)key {
	[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];

	int pid = getpid();
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:pid] forKey:@"pid"];	
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged object:key userInfo:userInfo];
}

- (BOOL) boolForKey:(NSString *)key {
	return GrowlPreferencesController_boolForKey((CFTypeRef)key);
}

- (void) setBool:(BOOL)value forKey:(NSString *)key {
	NSNumber *object = [[NSNumber alloc] initWithBool:value];
	[self setObject:object forKey:key];
	[object release];
}

- (CFIndex) integerForKey:(NSString *)key {
	return GrowlPreferencesController_integerForKey((CFTypeRef)key);
}

- (void) setInteger:(CFIndex)value forKey:(NSString *)key {
#ifdef __LP64__
	NSNumber *object = [[NSNumber alloc] initWithInteger:value];
#else
	NSNumber *object = [[NSNumber alloc] initWithInt:value];
#endif
	[self setObject:object forKey:key];
	[object release];
}

- (unsigned short)unsignedShortForKey:(NSString *)key
{
	return GrowlPreferencesController_unsignedShortForKey((CFTypeRef)key);
}


- (void)setUnsignedShort:(unsigned short)theShort forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithUnsignedShort:theShort] forKey:key];
}

#pragma mark -
#pragma mark Start-at-login control

- (BOOL) allowStartAtLogin{
    return [self boolForKey:GrowlAllowStartAtLogin];
}

- (void) setAllowStartAtLogin:(BOOL)start{
    [self setBool:start forKey:GrowlAllowStartAtLogin];
}

- (BOOL) shouldStartGrowlAtLogin {
   return [self boolForKey:GrowlShouldStartAtLogin];
}

- (void) setShouldStartGrowlAtLogin:(BOOL)flag {
   NSURL *urlOfLoginItem = [[[NSBundle mainBundle] bundleURL] URLByAppendingPathComponent:@"Contents/Library/LoginItems/GrowlLauncher.app"];
   if(!LSRegisterURL((__bridge CFURLRef)urlOfLoginItem, YES)){
      //NSLog(@"Failure registering %@ with Launch Services", [urlOfLoginItem description]);
   }
   if(!SMLoginItemSetEnabled(CFSTR("com.growl.GrowlLauncher"), flag)){
      //NSLog(@"Failure Setting GrowlLauncher to %@start at login", flag ? @"" : @"not ");
   }
   [self setBool:flag forKey:GrowlShouldStartAtLogin];
}

#pragma mark -
#pragma mark Growl running state

- (void) setSquelchMode:(BOOL)squelch
{
    [self willChangeValueForKey:@"squelchMode"];
    [self setBool:squelch forKey:GrowlSquelchMode];
    [self didChangeValueForKey:@"squelchMode"];
   
   if(!squelch && [[GrowlNotificationDatabase sharedInstance] notificationsWhileAway] && [self isRollupAutomatic]){
       [self setRollupShown:YES];
   }
}

- (BOOL) squelchMode
{
    return [self boolForKey:GrowlSquelchMode];
}

#pragma mark -
//Simplified accessors

#pragma mark UI

- (NSUInteger) selectedPreferenceTab{
   return [self integerForKey:GrowlSelectedPrefPane];
}
- (void) setSelectedPreferenceTab:(NSUInteger)tab{
   if (tab < 7 ) {
      [self setInteger:tab forKey:GrowlSelectedPrefPane];
   }else {
      [self setInteger:0 forKey:GrowlSelectedPrefPane];
   }

}

- (CFIndex)selectedPosition {
	return [self integerForKey:GROWL_POSITION_PREFERENCE_KEY];
}

- (NSString *) defaultDisplayPluginName {
	return [self objectForKey:GrowlDisplayPluginKey];
}
- (void) setDefaultDisplayPluginName:(NSString *)name {
	[self setObject:name forKey:GrowlDisplayPluginKey];
}

- (NSArray *) defaultActionPluginIDArray {
	return [self objectForKey:GrowlActionPluginsKey];
}
- (void) setDefaultActionPluginIDArray:(NSArray*)actions {
	[self setObject:actions forKey:GrowlActionPluginsKey];
}
							  
#pragma mark Idle Detection

-(void)updateIdleThreshold {
	NSTimeInterval threshold = [idleThreshold doubleValue];
	threshold *= (NSTimeInterval)idleMultiplier;
	[[GrowlIdleStatusObserver sharedObserver] setValue:[NSNumber numberWithDouble:threshold] forKey:@"idleThreshold"];
}

- (void) setIdleThreshold:(NSNumber*)value {
	if(idleThreshold)
		[idleThreshold release];
	idleThreshold = [value retain];
	[self setObject:value forKey:GrowlIdleThresholdKey];
	[self updateIdleThreshold];
}

- (void) setIdleMultiplier:(NSUInteger)value {
	idleMultiplier = value;
	[self setInteger:value forKey:GrowlIdleMultiplierKey];
	[self updateIdleThreshold];
}

- (void) setUseIdleByTime:(BOOL)value	{
	useIdleByTime = value;
	[self setBool:value forKey:GrowlIdleByTimeKey];
	[[GrowlIdleStatusObserver sharedObserver] setValue:[NSNumber numberWithBool:value] forKey:@"useTime"];
}
- (void) setUseIdleByScreensaver:(BOOL)value {
	useIdleByScreensaver = value;
	[self setBool:value forKey:GrowlIdleByScreensaverKey];
	[[GrowlIdleStatusObserver sharedObserver] setValue:[NSNumber numberWithBool:value] forKey:@"useScreensaver"];
}
- (void) setUseIdleByScreenLock:(BOOL)value	{
	useIdleByScreenLock = value;
	[self setBool:value forKey:GrowlIdleByScreenLockKey];
	[[GrowlIdleStatusObserver sharedObserver] setValue:[NSNumber numberWithBool:value] forKey:@"useLock"];
}

- (void)setIdleTimeExceptionApps:(NSArray *)array {
	if(idleTimeExceptionApps)
		[idleTimeExceptionApps release];
	idleTimeExceptionApps = [array retain];
	[self setObject:array forKey:GrowlIdleTimeExceptionsKey];
	[[GrowlIdleStatusObserver sharedObserver] setValue:array forKey:@"applicationExceptions"];
}

#pragma mark Logging

- (BOOL) loggingEnabled {
	return [self boolForKey:GrowlLoggingEnabledKey];
}

- (void) setLoggingEnabled:(BOOL)flag {
	[self setBool:flag forKey:GrowlLoggingEnabledKey];
}

- (BOOL) isGrowlServerEnabled {
	return [self boolForKey:GrowlStartServerKey];
}

- (void) setGrowlServerEnabled:(BOOL)enabled {
	[self setBool:enabled forKey:GrowlStartServerKey];
}

- (void) setMenuNumber:(NSNumber*)state{
   [self setMenuState:[state integerValue]];
}
- (NSInteger) menuState {
   return [self integerForKey:GrowlMenuState];
}
- (void) setMenuState:(NSInteger)state {
   NSInteger current = [self menuState];
   if(state == current)
      return;
   
   switch (state) {
      case GrowlStatusMenu:
         if(current == GrowlDockMenu || current == GrowlBothMenus){
            [self removeDockMenu];
         }
         break;
      case GrowlDockMenu:
      case GrowlBothMenus:
         [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
         [[NSApp dockTile] setBadgeLabel:nil];
         break;
      case GrowlNoMenu:
         if(![self isBackgroundAllowed]){
            NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Warning! Enabling this option will cause Growl to run in the background", nil)
                                             defaultButton:NSLocalizedString(@"Ok", nil)
                                           alternateButton:NSLocalizedString(@"Cancel", nil)
                                               otherButton:nil
                                 informativeTextWithFormat:NSLocalizedString(@"Enabling this option will cause Growl to run without showing a dock icon or a menu item.\n\nTo access preferences, tap Growl in Launchpad, or open Growl in Finder.", nil)];
            [alert setShowsSuppressionButton:YES];
            NSInteger allow = [alert runModal];
            BOOL suppress = [[alert suppressionButton] state] == NSOnState;
            if(suppress)
               [self setBackgroundAllowed:YES];
            
            if(allow == NSAlertDefaultReturn)
               [self removeDockMenu];
            else{
               //While the state will already be reset below, we call the new setMenuNumber with our current, and thats enough to trigger the menu updating
               [self performSelector:@selector(setMenuNumber:) withObject:[NSNumber numberWithInteger:current] afterDelay:0];
               state = current;
            }
         }else
            [self removeDockMenu];
         
         break;
      default:
         //Don't know what to do, leave it where it was
         return;
   }
   
   [[GrowlApplicationController sharedController] updateMenu:state];
   [self setInteger:state forKey:GrowlMenuState];
}

- (void)removeDockMenu {
   //We can't actually remove the dock menu without restarting, inform the user.
   if([self menuState] != GrowlDockMenu && [self menuState] != GrowlBothMenus)
      return;

   if(![self boolForKey:GrowlRelaunchWarnSuppress]){
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:NSLocalizedString(@"Growl must restart for this change to take effect.",nil)];
      [alert setShowsSuppressionButton:YES];
      [alert runModal];
      if([[alert suppressionButton] state] == NSOnState){
         [self setBool:YES forKey:GrowlRelaunchWarnSuppress];
      }
      [alert release];
   }
}

- (BOOL) isBackgroundAllowed {
   return [self boolForKey:GrowlBackgroundAllowed];
}
- (void) setBackgroundAllowed:(BOOL)allow {
   [self setBool:allow forKey:GrowlBackgroundAllowed];
}

- (BOOL)isGrowlMenuPulseEnabled {
   return [self boolForKey:GrowlMenuPulseEnabled];
}
- (void)setGrowlMenuPulseEnabled:(BOOL)enabled {
   [self setBool:enabled forKey:GrowlMenuPulseEnabled];
}

#pragma mark Notification History

- (BOOL) isRollupShown {
   return [self boolForKey:GrowlRollupShown];
}
- (void) setRollupShown:(BOOL)shown {
   if(shown && ![self isRollupShown] && ![self isRollupEnabled])
      shown = NO;
   [self setBool:shown forKey:GrowlRollupShown];
   if (shown) {
      [[GrowlNotificationDatabase sharedInstance] showRollup];
   }else{
      [[GrowlNotificationDatabase sharedInstance] hideRollup];
   }
}
- (BOOL) isRollupEnabled {
   return [self boolForKey:GrowlRollupEnabled];
}
- (void) setRollupEnabled:(BOOL)enabled{
   [self setBool:enabled forKey:GrowlRollupEnabled];
}
- (BOOL) isRollupAutomatic {
   return [self boolForKey:GrowlRollupAutomatic];
}
- (void) setRollupAutomatic:(BOOL)automatic {
   [self setBool:automatic forKey:GrowlRollupAutomatic];
}

- (BOOL) isGrowlHistoryLogEnabled {
   return [self boolForKey:GrowlHistoryLogEnabled];
}
- (void) setGrowlHistoryLogEnabled:(BOOL)flag {
   [self setBool:flag forKey:GrowlHistoryLogEnabled];
}

- (BOOL) retainAllNotesWhileAway {
   return [self boolForKey:GrowlHistoryRetainAllWhileAway];
}
- (void) setRetainAllNotesWhileAway:(BOOL)flag {
   [self setBool:flag forKey:GrowlHistoryRetainAllWhileAway];
}

- (NSUInteger) growlHistoryDayLimit {
	return [self integerForKey:GrowlHistoryDayLimit];
}
- (void) setGrowlHistoryDayLimit:(NSUInteger)limit {
	[self setInteger:limit forKey:GrowlHistoryDayLimit];
}

- (NSUInteger) growlHistoryCountLimit {
   return [self integerForKey:GrowlHistoryCountLimit];
}
- (void) setGrowlHistoryCountLimit:(NSUInteger)limit {
	[self setInteger:limit forKey:GrowlHistoryCountLimit];
}

- (BOOL) isGrowlHistoryTrimByDate {
   return [self boolForKey:GrowlHistoryTrimByDate];
}
- (void) setGrowlHistoryTrimByDate:(BOOL)flag {
   [self setBool:flag forKey:GrowlHistoryTrimByDate];
}

- (BOOL) isGrowlHistoryTrimByCount {
   return [self boolForKey:GrowlHistoryTrimByCount];
}
- (void) setGrowlHistoryTrimByCount:(BOOL)flag {
   [self setBool:flag forKey:GrowlHistoryTrimByCount];
}

#pragma mark Remote Growling

- (NSString *) remotePassword {
	return [GrowlKeychainUtilities passwordForServiceName:GrowlIncomingNetworkPassword accountName:GrowlIncomingNetworkPassword];
}

- (void) setRemotePassword:(NSString *)value {
   [GrowlKeychainUtilities setPassword:value forService:GrowlIncomingNetworkPassword accountName:GrowlIncomingNetworkPassword];
}

- (BOOL) isForwardingEnabled {
	return [self boolForKey:GrowlEnableForwardKey];
}
- (void) setForwardingEnabled:(BOOL)enabled {
	[self setBool:enabled forKey:GrowlEnableForwardKey];
}

#pragma mark Subscriptions

- (BOOL) isSubscriptionAllowed{
   return [self boolForKey:GrowlSubscriptionEnabledKey];
}
- (void) setSubscriptionAllowed:(BOOL)allowed{
   [self setBool:allowed forKey:GrowlSubscriptionEnabledKey];
}

- (NSString*) GNTPSubscriberID{
   return [self objectForKey:@"GNTPSubscriberID"];
}
- (void) setGNTPSubscriberID:(NSString*)newID{
   [self setObject:newID forKey:@"GNTPSubscriberID"];
}

#pragma mark -
/*
 * @brief Growl preferences changed
 *
 * Synchronize our NSUserDefaults to immediately get any changes from the disk
 */
- (void) growlPreferencesChanged:(NSNotification *)notification {
	@autoreleasepool {
        NSString *object = [notification object];
    //	NSLog(@"%s: %@\n", __func__, object);
        if (!object || [object isEqualToString:GrowlDisplayPluginKey]) {
            [self willChangeValueForKey:@"defaultDisplayPluginName"];
            [self didChangeValueForKey:@"defaultDisplayPluginName"];
        }
        if (!object || [object isEqualToString:GrowlMenuExtraKey]) {
            [self willChangeValueForKey:@"growlMenuEnabled"];
            [self didChangeValueForKey:@"growlMenuEnabled"];
        }
        if (!object || [object isEqualToString:GrowlEnableForwardKey]) {
            [self willChangeValueForKey:@"forwardingEnabled"];
            [self didChangeValueForKey:@"forwardingEnabled"];
        }
        if (!object || [object isEqualToString:GrowlIdleThresholdKey]) {
            [self willChangeValueForKey:@"idleThreshold"];
            [self didChangeValueForKey:@"idleThreshold"];
        }
        if (!object || [object isEqualToString:GrowlSelectedPrefPane]) {
            [self willChangeValueForKey:@"selectedPreferenceTab"];
            [self didChangeValueForKey:@"selectedPreferenceTab"];
        }	
	}
}

@end
