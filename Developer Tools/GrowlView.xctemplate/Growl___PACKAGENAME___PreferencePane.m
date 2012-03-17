//
//  ___FILENAME___
//  ___PACKAGENAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright (c) ___YEAR___ ___ORGANIZATIONNAME___. All rights reserved.
//
//  This class represents your plugin's preference pane.  There will be only one instance, but possibly many configurations
//  In order to access a configuration values, use the NSMutableDictionary *configuration for getting them. 
//  In order to change configuration values, use [self setConfigurationValue:forKey:]
//  This ensures that the configuration gets saved into the database properly.

#import "Growl___PACKAGENAME___PreferencePane.h"

@implementation Growl___PACKAGENAME___PreferencePane

-(NSString*)mainNibName {
	return @"___PACKAGENAME___PrefPane";
}

/* This returns the set of keys the preference pane needs updated via bindings 
 * This is called by GrowlPluginPreferencePane when it has had its configuration swapped
 * Since we really only need a fixed set of keys updated, use dispatch_once to create the set
 */
- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet set] retain];
	});
	return keys;
}

/* This method is called when our configuration values have been changed 
 * by switching to a new configuration.  This is where we would update certain things
 * that are unbindable.  Call the super version in order to ensure bindingKeys is also called and used.
 * Uncomment the method to use.
 */
/*
-(void)updateConfigurationValues {
	[super updateConfigurationValues];
}
*/

@end
