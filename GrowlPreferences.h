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


@interface GrowlPreferences : NSObject {
	NSUserDefaults			* helperAppDefaults;
	NSBundle				* helperAppBundle;
}

+ (GrowlPreferences *) preferences;

- (void) registerDefaults:(NSDictionary *)inDefaults;
- (id) objectForKey:(NSString *)key;
- (void) setObject:(id)object forKey:(NSString *) key;

- (NSBundle *) helperAppBundle;
- (NSString *) growlSupportDir;


@end
