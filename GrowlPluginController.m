//
//  GrowlPluginController.m
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlPluginController.h"

static GrowlPluginController * sharedController;

@interface GrowlPluginController (PRIVATE) 
- (void)findDisplayPluginsInDirectory:(NSString *)dir;
@end

@implementation GrowlPluginController

+ (GrowlPluginController *) controller {
	if ( ! sharedController )
		sharedController = [[GrowlPluginController alloc] init];

	return sharedController;
}

- (id) init {
	if ( self = [super init] ) {
		NSArray *libraries;
		NSEnumerator *enumerator;
		NSString *dir;
		
		allDisplayPlugins = [[NSMutableDictionary alloc] init];
		
		libraries = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, 
														 NSAllDomainsMask, 
														 YES /* expand tildes */ );
		
		enumerator = [libraries objectEnumerator];
		while ( dir = [enumerator nextObject] ) {
			dir = [[[dir	stringByAppendingPathComponent:@"Application Support"]
							stringByAppendingPathComponent:@"Growl"]
							stringByAppendingPathComponent:@"Plugins"];

			[self findDisplayPluginsInDirectory:dir];
		}
		builtInPluginsPath = [[[NSBundle mainBundle] builtInPlugInsPath] retain];
		[self findDisplayPluginsInDirectory:builtInPluginsPath];
	}
	
	return self;
}

- (void) dealloc {
	[[allDisplayPlugins allValues] makeObjectsPerformSelector:@selector(unloadPlugin:)];
	[allDisplayPlugins release];
	[builtInPluginsPath release];
	
	allDisplayPlugins = nil;
	builtInPluginsPath = nil;
	
	[super dealloc];
}

#pragma mark -

- (NSArray *) allDisplayPlugins {
	return [allDisplayPlugins allKeys];
}

- (id <GrowlDisplayPlugin>) displayPluginNamed:(NSString *)name {
	return [allDisplayPlugins objectForKey:name];
}

- (void) findDisplayPluginsInDirectory:(NSString *)dir {
	NSString * displayPluginExt = @"growlView";
	
	NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString * file;
	NSBundle * pluginBundle;
	id <GrowlDisplayPlugin> plugin;
	
	while ( file = [enumerator nextObject] ) {

		if ( [[file pathExtension] isEqualToString:displayPluginExt] ) {
			pluginBundle = [NSBundle bundleWithPath:[dir stringByAppendingPathComponent:file]];

			if ( pluginBundle 
				 && ( plugin = [[[[pluginBundle principalClass] alloc] init] autorelease] ) 
				 && [plugin name] ) {

				[plugin loadPlugin];
				[allDisplayPlugins setObject:plugin forKey:[plugin name]];

			} else {
				NSLog(@"Failed to load: %@",file);
			}
			
		}
	}
}

@end
