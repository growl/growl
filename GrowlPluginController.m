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
	if(!sharedController) {
		sharedController = [[GrowlPluginController alloc] init];
	}
	return sharedController;
}

- (id) init {
	NSArray * libraries;
	NSEnumerator * enumerator;
	NSString * dir;

	if( (self = [super init]) ) {
		allDisplayPlugins = [[NSMutableDictionary alloc] init];

		libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);

		enumerator = [libraries objectEnumerator];
		while ( dir = [enumerator nextObject] ) {
			dir = [[[dir	stringByAppendingPathComponent:@"Application Support"]
							stringByAppendingPathComponent:@"Growl"]
							stringByAppendingPathComponent:@"Plugins"];

			[self findDisplayPluginsInDirectory:dir];
		}

		[self findDisplayPluginsInDirectory:[[[GrowlPreferences preferences] helperAppBundle] builtInPlugInsPath]];
	}
	
	return self;
}

- (NSArray *) allDisplayPlugins {
	return [allDisplayPlugins allKeys];
}

- (id <GrowlDisplayPlugin>) displayPluginNamed:(NSString *)name {
	return [allDisplayPlugins objectForKey:name];
}

- (void) dealloc {
	[[allDisplayPlugins allValues] makeObjectsPerformSelector:@selector(unloadPlugin:)];
	[allDisplayPlugins release];

	[super dealloc];
}

- (void)findDisplayPluginsInDirectory:(NSString *)dir {
	NSString * displayPluginExt = @"growlView";
	NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString * file;

	while ( file = [enumerator nextObject] ) {
		if ( [[file pathExtension] isEqualToString:displayPluginExt] ) {
			[self loadPlugin:[dir stringByAppendingPathComponent:file]];
		}
	}
}

- (void)loadPlugin:(NSString *)path
{
	NSBundle * pluginBundle;
	id <GrowlDisplayPlugin> plugin;

	pluginBundle = [NSBundle bundleWithPath:path];

	if ( pluginBundle 
		 && (plugin = [[[[pluginBundle principalClass] alloc] init] autorelease]) 
		 && [plugin name] ) {
		
		[plugin loadPlugin];
		[allDisplayPlugins setObject:plugin forKey:[plugin name]];
	} else {
		NSLog(@"Failed to load: %@", path);
	}
}

- (void)installPlugin:(NSString *)filename
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *destination = [[[[[NSHomeDirectory()
		stringByAppendingPathComponent:@"Library"]
		stringByAppendingPathComponent:@"Application Support"]
		stringByAppendingPathComponent:@"Growl"]
		stringByAppendingPathComponent:@"Plugins"]
		stringByAppendingPathComponent: [filename lastPathComponent]];

	if( ![fileManager copyPath:filename toPath:destination handler:nil] ) {
		NSLog( @"Could not copy '%@' to '%@'", filename, destination );
	}
}

@end
