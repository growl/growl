//
//  GrowlPluginController.h
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlPluginController : NSObject {
		NSMutableDictionary		* allDisplayPlugins;
	
}

+ (GrowlPluginController *)controller;

- (NSArray *)allDisplayPlugins;
- (id <GrowlDisplayPlugin>) displayPluginNamed:(NSString *)name;

@end
