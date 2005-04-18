//
//  GrowlPreferences.h
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

#define HelperAppBundleIdentifier	@"com.Growl.GrowlHelperApp"
#define GrowlPreferencesChanged		@"GrowlPreferencesChanged"
#define GrowlPreview				@"GrowlPreview"
#define GrowlDisplayPluginKey		@"GrowlDisplayPluginName"
#define GrowlUserDefaultsKey		@"GrowlUserDefaults"
#define GrowlStartServerKey			@"GrowlStartServer"
#define GrowlRemoteRegistrationKey	@"GrowlRemoteRegistration"
#define GrowlEnableForwardKey		@"GrowlEnableForward"
#define GrowlForwardDestinationsKey	@"GrowlForwardDestinations"
#define GrowlUpdateCheckKey			@"GrowlUpdateCheck"
#define LastUpdateCheckKey			@"LastUpdateCheck"
#define	GrowlLoggingEnabledKey		@"Log enabled"
#define	GrowlLogTypeKey				@"Log type"
#define	GrowlCustomHistKey1			@"Custom log history 1"
#define	GrowlCustomHistKey2			@"Custom log history 2"
#define	GrowlCustomHistKey3			@"Custom log history 3"

@interface GrowlPreferences : NSObject {
	NSUserDefaults *helperAppDefaults;
}

+ (GrowlPreferences *) preferences;

- (void) registerDefaults:(NSDictionary *)inDefaults;
- (id) objectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *)key;
- (BOOL) boolForKey:(NSString*) key;
- (void) setBool:(BOOL)value forKey:(NSString *)key;
- (void) synchronize;

- (BOOL) startGrowlAtLogin;
- (void) setStartGrowlAtLogin:(BOOL)flag;

- (BOOL) isGrowlRunning;
- (void) setGrowlRunning:(BOOL)flag;
- (void) launchGrowl;
- (void) terminateGrowl;

@end
