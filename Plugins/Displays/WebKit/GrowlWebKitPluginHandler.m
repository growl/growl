//
//  GrowlWebKitPluginHandler.m
//  Growl
//
//  Created by JKP on 03/11/2005.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlWebKitPluginHandler.h"
#import "GrowlWebKitDisplayPlugin.h"
#import "GrowlPluginController.h"

@implementation GrowlWebKitPluginHandler

- (id) initSingleton {
	if ((self = [super initSingleton]))
		[[GrowlPluginController sharedController] addPluginHandler:self forPluginTypes:[NSSet setWithObject:GROWL_STYLE_EXTENSION]];

	return self;
}

- (BOOL) loadPluginAtPath:(NSString *)path {
	NSBundle *pluginBundle = [[NSBundle alloc] initWithPath:path];
	if (!pluginBundle) {
		NSLog(@"%@ Failed to load: %@",NSStringFromClass([self class]),path);
		[pluginBundle release];
		return NO;
	}

	GrowlWebKitDisplayPlugin *instance = [[GrowlWebKitDisplayPlugin alloc] initWithStyleBundle:pluginBundle];
	if (!instance) {
		NSLog(@"%@ Failed to load: %@ - the bundle did not contain a valid WebKit plugin",
			  NSStringFromClass([self class]),
			  path);
		[pluginBundle release];
		return NO;
	}

	[[GrowlPluginController sharedController] addPluginInstance:instance fromBundle:pluginBundle];
	[instance release];
	[pluginBundle release];
	return YES;
}


@end
