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
		while( ( dir = [enumerator nextObject] ) ) {
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

	while ( (file = [enumerator nextObject]) ) {
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

- (void)pluginExistsSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSString *filename = (NSString *)contextInfo;
	if( returnCode == NSAlertAlternateReturn ) {
		NSString *pluginFile = [filename lastPathComponent];
		NSString *destination = [[[[[NSHomeDirectory()
			stringByAppendingPathComponent:@"Library"]
			stringByAppendingPathComponent:@"Application Support"]
			stringByAppendingPathComponent:@"Growl"]
			stringByAppendingPathComponent:@"Plugins"]
			stringByAppendingPathComponent: pluginFile];
		NSFileManager *fileManager = [NSFileManager defaultManager];

		// first remove old copy if present
		[fileManager removeFileAtPath:destination handler:nil];

		// copy new version to destination
		if( [fileManager copyPath:filename toPath:destination handler:nil] ) {
			NSBeginInformationalAlertSheet( NSLocalizedString( @"Plugin installed", @"" ),
											NSLocalizedString( @"OK", @"" ),
											nil, nil, nil, self, NULL, NULL, NULL,
											NSLocalizedString( @"Plugin '%@' has been installed successfully.", @"" ),
											[pluginFile stringByDeletingPathExtension] );
		} else {
			NSBeginCriticalAlertSheet( NSLocalizedString( @"Plugin not installed", @"" ),
									   NSLocalizedString( @"OK", @"" ),
									   nil, nil, nil, self, NULL, NULL, NULL,
									   NSLocalizedString( @"There was an error while installing the plugin '%@'.", @"" ),
									   [pluginFile stringByDeletingPathExtension] );
		}
	}
	[filename release];
}

- (void)installPlugin:(NSString *)filename
{
	NSString *pluginFile = [filename lastPathComponent];
	NSString *destination = [[[[[NSHomeDirectory()
		stringByAppendingPathComponent:@"Library"]
		stringByAppendingPathComponent:@"Application Support"]
		stringByAppendingPathComponent:@"Growl"]
		stringByAppendingPathComponent:@"Plugins"]
		stringByAppendingPathComponent: pluginFile];
	// retain a copy of the filename because it is passed as context to the sheetDidEnd selectors
	NSString *filenameCopy = [[NSString alloc] initWithString:filename];

	if( [[NSFileManager defaultManager] fileExistsAtPath:destination] ) {
		// plugin already exists at destination
		NSBeginAlertSheet( NSLocalizedString( @"Plugin already exists", @"" ),
						   NSLocalizedString( @"No", @"" ),
						   NSLocalizedString( @"Yes", @"" ), nil, nil, self,
						   NULL, @selector(pluginExistsSelector:returnCode:contextInfo:),
						   filenameCopy,
						   NSLocalizedString( @"Plugin '%@' is already installed, do you want to overwrite it?", @"" ),
						   [pluginFile stringByDeletingPathExtension] );
	} else {
		[self pluginExistsSelector:nil returnCode:NSAlertAlternateReturn contextInfo:filenameCopy];
	}
}

@end
