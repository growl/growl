//
//  GrowlPluginController.h
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>

@class GrowlPlugin, GrowlDisplayPlugin;

@interface GrowlPluginController : NSObject {
	//keys: plug-in names; values: GrowlPlugins.
	NSMutableDictionary		*pluginInstances;
	//keys: plug-in names; values: NSBundles.
	NSMutableDictionary		*pluginBundles;
}

+ (GrowlPluginController *) sharedController;

//takes a filename extension (or nil) and filters the list of plug-ins by it, using their path.
- (NSArray *) pluginsOfType:(NSString *)type;
//returns an array of display plug-ins (WebKit and Obj-C both).
- (NSArray *) displayPlugins;

- (GrowlDisplayPlugin *) displayPluginInstanceWithName:(NSString *)name;
-           (NSBundle *)   displayPluginBundleWithName:(NSString *)name;

- (GrowlPlugin *) pluginInstanceWithName:(NSString *)name type:(NSString *)type;
-    (NSBundle *)   pluginBundleWithName:(NSString *)name type:(NSString *)type;

- (void) installPlugin:(NSString *)filename;

@end
