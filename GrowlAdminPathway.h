//
//  GrowlAdminPathway.h
//  Growl
//
//  Created by Karl Adam on 10/31/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlPreferences;

@interface GrowlAdminPathway : NSObject {
	GrowlPreferences *_prefs;
}

+ (GrowlAdminPathway *) adminPathway;

- (id) objectForKey:(NSString *)inObject;
- (void) setObject:(id)inObject forKey:(NSString *)inKey;

- (NSString *) builtInPluginsPath;
- (NSDictionary *) infoForPluginNamed:(NSString *)inPluginNamed;
- (NSArray *) allDisplayPlugins;

- (oneway void) shutdown;
@end
