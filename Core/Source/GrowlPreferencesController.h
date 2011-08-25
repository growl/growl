//
//  GrowlPreferencesController.h
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Renamed from GrowlPreferences.h by Mac-arena the Bored Zo on 2005-06-27.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#ifndef GROWL_PREFERENCES_CONTROLLER_H
#define GROWL_PREFERENCES_CONTROLLER_H

#ifdef __OBJC__
#define XSTR(x) (@x)
#else
#define XSTR CFSTR
#endif

#define GrowlPreferencesChanged		XSTR("GrowlPreferencesChanged")
#define GrowlSquelchMode            XSTR("GrowlSquelchMode")
#define GrowlPreview				XSTR("GrowlPreview")
#define GrowlDisplayPluginKey		XSTR("GrowlDisplayPluginName")
#define GrowlUserDefaultsKey		XSTR("GrowlUserDefaults")
#define GrowlStartServerKey			XSTR("GrowlStartServer")
#define GrowlEnableForwardKey		XSTR("GrowlEnableForward")
#define GrowlForwardDestinationsKey	XSTR("GrowlForwardDestinations")
#define GrowlUDPPortKey				XSTR("GrowlUDPPort")
#define GrowlTCPPortKey				XSTR("GrowlTCPPort")
#define	GrowlLoggingEnabledKey		XSTR("GrowlLoggingEnabled")
#define	GrowlLogTypeKey				XSTR("GrowlLogType")
#define	GrowlCustomHistKey1			XSTR("Custom log history 1")
#define	GrowlCustomHistKey2			XSTR("Custom log history 2")
#define	GrowlCustomHistKey3			XSTR("Custom log history 3")
#define GrowlMenuExtraKey			XSTR("GrowlMenuExtra")
#define LastKnownVersionKey			XSTR("LastKnownVersion")
#define GrowlStickyIdleThresholdKey	XSTR("IdleThreshold")
#define GrowlHistoryLogEnabled      XSTR("GrowlHistoryLogEnabled")
#define GrowlHistoryRetainAllWhileAway XSTR("GrowlHistoryRetainAllWhileAway")
#define GrowlHistoryCountLimit      XSTR("GrowlHistoryCountLimit")
#define GrowlHistoryDayLimit        XSTR("GrowlHistoryDayLimit")
#define GrowlHistoryTrimByCount     XSTR("GrowlHistoryTrimByCount")
#define GrowlHistoryTrimByDate      XSTR("GrowlHistoryTrimByDate")
#define GrowlSelectedPrefPane       XSTR("GrowlSelectedPrefPane")

#define GrowlFirstLaunch            XSTR("GrowlFirstLaunch")
#define GrowlAllowStartAtLogin      XSTR("GrowlAllowStartAtLogin")

CFTypeRef GrowlPreferencesController_objectForKey(CFTypeRef key);
CFIndex   GrowlPreferencesController_integerForKey(CFTypeRef key);
Boolean   GrowlPreferencesController_boolForKey(CFTypeRef key);
unsigned short GrowlPreferencesController_unsignedShortForKey(CFTypeRef key);

#ifdef __OBJC__

#import "GrowlAbstractSingletonObject.h"

@interface GrowlPreferencesController : GrowlAbstractSingletonObject {
	LSSharedFileListRef loginItems;
}

+ (GrowlPreferencesController *) sharedController;

- (void) registerDefaults:(NSDictionary *)inDefaults;
- (id) objectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *)key;
- (BOOL) boolForKey:(NSString*) key;
- (void) setBool:(BOOL)value forKey:(NSString *)key;
- (CFIndex) integerForKey:(NSString *)key;
- (void) setInteger:(CFIndex)value forKey:(NSString *)key;
- (void) synchronize;

- (BOOL) allowStartAtLogin;
- (void) setAllowStartAtLogin:(BOOL)start;
- (BOOL) shouldStartGrowlAtLogin;
- (void) setShouldStartGrowlAtLogin:(BOOL)flag;
- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)flag;

- (void) setSquelchMode:(BOOL)squelch;
- (BOOL) squelchMode;

#pragma mark -
//Simplified accessors

#pragma mark UI

- (NSString *) defaultDisplayPluginName;
- (void) setDefaultDisplayPluginName:(NSString *)name;

- (NSNumber*) idleThreshold;
- (void) setIdleThreshold:(NSNumber*)value;

- (NSUInteger) selectedPreferenceTab;
- (void) setSelectedPreferenceTab:(NSUInteger)tab;

#pragma mark Notification History
- (BOOL) isGrowlHistoryLogEnabled;
- (void) setGrowlHistoryLogEnabled:(BOOL)flag;

- (BOOL) retainAllNotesWhileAway;
- (void) setRetainAllNotesWhileAway:(BOOL)flag;

- (NSUInteger) growlHistoryDayLimit;
- (void) setGrowlHistoryDayLimit:(NSUInteger)limit;
- (NSUInteger) growlHistoryCountLimit;
- (void) setGrowlHistoryCountLimit:(NSUInteger)limit;

- (BOOL) isGrowlHistoryTrimByDate;
- (void) setGrowlHistoryTrimByDate:(BOOL)flag;
- (BOOL) isGrowlHistoryTrimByCount;
- (void) setGrowlHistoryTrimByCount:(BOOL)flag;

#pragma mark "Network" tab pane

- (BOOL) isGrowlServerEnabled;
- (void) setGrowlServerEnabled:(BOOL)enabled;

- (BOOL) isForwardingEnabled;
- (void) setForwardingEnabled:(BOOL)enabled;

- (NSString *) remotePassword;
- (void) setRemotePassword:(NSString *)value;

@end

#endif

#endif
