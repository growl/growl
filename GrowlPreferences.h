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


@interface GrowlPreferences : NSObject {
	NSUserDefaults *_realPrefs;
}

+ (GrowlPreferences *) preferences;

- (void) registerDefaults:(NSDictionary *)inDict;
- (id) objectForKey:(NSString *)inKey;
- (void) setObject:(id)inObject forKey:(NSString *)inKey;
- (BOOL) synchronize;

- (NSString *) growlSupportDir;


@end
