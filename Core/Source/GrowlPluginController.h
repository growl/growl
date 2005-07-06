//
//  GrowlPluginController.h
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

@protocol GrowlPlugin, GrowlDisplayPlugin;

@interface GrowlPluginController : NSObject {
	//keys: plug-in names; values: GrowlPlugins.
	NSMutableDictionary		*pluginInstances;
	//keys: plug-in names; values: NSBundles.
	NSMutableDictionary		*pluginBundles;
}

+ (GrowlPluginController *) sharedController;

/*files or bundles with a pathname extension in this set are plug-ins that the
 *	plug-in controller believes it can load.
 */
- (NSSet *) pluginPathExtensions;

//for use by plug-ins.
/*NOTE: currently does nothing, in the absence of any way (so far) to bind an
 *	extension to a plug-in.
 */
- (void) addPluginPathExtension:(NSString *)ext;

//takes a filename extension and filters the list of loaded plug-ins by it, using their path.
//if you pass nil, all loaded plug-ins are returned.
- (NSArray *) pluginsOfType:(NSString *)type;
//returns an array of display plug-ins (WebKit and Obj-C both).
- (NSArray *) displayPlugins;

- (id<GrowlDisplayPlugin>) displayPluginInstanceWithName:(NSString *)name;
-           (NSBundle *)   displayPluginBundleWithName:(NSString *)name;

- (id<GrowlPlugin>) pluginInstanceWithName:(NSString *)name type:(NSString *)type;
-    (NSBundle *)   pluginBundleWithName:(NSString *)name type:(NSString *)type;

- (void) installPlugin:(NSString *)filename;

@end
