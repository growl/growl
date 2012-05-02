//
//  GrowlTicketDatabasePlugin.m
//  Growl
//
//  Created by Daniel Siemer on 3/2/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlTicketDatabasePlugin.h"
#import "GrowlPluginController.h"
#import <GrowlPlugins/GrowlPlugin.h>

@implementation GrowlTicketDatabasePlugin

@dynamic configuration;
@dynamic pluginID;
@dynamic displayName;
@dynamic configID;
@dynamic pluginType;

-(BOOL)canFindInstance {
	return ([self pluginInstanceForConfiguration] != nil);
}

-(GrowlPlugin*)pluginInstanceForConfiguration {
	NSDictionary *pluginDict = [[[GrowlPluginController sharedController] pluginsByBundleIdentifier] valueForKey:self.pluginID];
	NSString *displayName = [pluginDict valueForKey:GrowlPluginInfoKeyName];
	GrowlPlugin *plugin = [[GrowlPluginController sharedController] pluginInstanceWithName:displayName];
	return plugin;
}

@end
