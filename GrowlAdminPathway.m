//
//  GrowlAdminPathway.m
//  Growl
//
//  Created by Karl Adam on 10/31/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import "GrowlAdminPathway.h"
#import "GrowlPreferences.h"

static GrowlAdminPathway *theOneGrowlAdminPathway = nil;

@implementation GrowlAdminPathway

+ (GrowlAdminPathway *) adminPathway {
	if ( ! theOneGrowlAdminPathway ) {
		theOneGrowlAdminPathway = [[self alloc] init];
		
		NSConnection *aConnection = [NSConnection defaultConnection];
		[aConnection setRootObject:theOneGrowlAdminPathway];
		
		NSString *uniqueName = [NSString stringWithFormat:@"GrowlPreferencesAdministrativeConnection-%@", NSUserName()];
		
		if ( ! [aConnection registerName:uniqueName] ) {
			NSLog( @"MAKE YOUR TIME, GROWL ADMIN CONNECTION BROKE" );
		}
		
	}
	
	return theOneGrowlAdminPathway;
}

- (id) init {
	if ( self = [super init] ) {
		_prefs = [GrowlPreferences preferences];
	}
	
	return self;
}

- (void) dealloc {
	[_prefs release];
	
	_prefs = nil;
	
	[super dealloc];
}

#pragma mark -

- (id) objectForKey:(NSString *)inString {
	return [_prefs objectForKey:inString];
}

- (void) setObject:(id)inObject forKey:(NSString *)inString {
	[_prefs setObject:inObject forKey:inString];
}

#pragma mark -

- (NSString *) builtInPluginsPath {
	return [[GrowlPluginController controller] builtInPluginsPath];
}

- (NSDictionary *) infoForPluginNamed:(NSString *)inPluginName {
	return [[[GrowlPluginController controller] displayPluginNamed:inPluginName] pluginInfo];
}

- (NSArray *) allDisplayPlugins {
	return [[GrowlPluginController controller] allDisplayPlugins];
}

- (oneway void) shutdown {
	[NSApp terminate: nil];
}

@end
