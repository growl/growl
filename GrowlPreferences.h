//
//  GrowlPreferences.h
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * HelperAppBundleIdentifier;
extern NSString * GrowlPreferencesChanged;
extern NSString * GrowlDisplayPluginKey;
extern NSString * GrowlUserDefaultsKey;
extern NSString * GrowlStartServerKey;
extern NSString * GrowlRemoteRegistrationKey;

@interface GrowlPreferences : NSObject {
	NSUserDefaults			* helperAppDefaults;
	NSBundle				* helperAppBundle;
}

+ (GrowlPreferences *) preferences;

- (void) registerDefaults:(NSDictionary *)inDefaults;
- (id) objectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *) key;
- (void) synchronize;

- (NSBundle *) helperAppBundle;
- (NSString *) growlSupportDir;

- (BOOL) startGrowlAtLogin;
- (void) setStartGrowlAtLogin:(BOOL)flag;

@end
