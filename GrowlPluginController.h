//
//  GrowlPluginController.h
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Cocoa/Cocoa.h>
#import "GrowlDisplayProtocol.h"

@interface GrowlPluginController : NSObject {
		NSMutableDictionary		*allDisplayPlugins;	
}

+ (GrowlPluginController *) controller;

- (NSArray *) allDisplayPlugins;
- (id <GrowlDisplayPlugin>) displayPluginNamed:(NSString *)name;
- (void) loadPlugin:(NSString *)path;
- (void) installPlugin:(NSString *)filename;

@end
