//
//  GrowlPluginController.m
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPluginController.h"
#import "GrowlPreferences.h"
#import "GrowlDisplayProtocol.h"

#define GROWL_PREFPANE_BUNDLE_IDENTIFIER		@"com.growl.prefpanel"
#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY	@"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION				@"prefPane"
#define GROWL_PREFPANE_NAME						@"Growl.prefPane"

static GrowlPluginController *sharedController;

@interface GrowlPluginController (PRIVATE) 
+ (NSBundle *) growlPrefPaneBundle;
- (void) findDisplayPluginsInDirectory:(NSString *)dir;
@end

#pragma mark -

@implementation GrowlPluginController

+ (GrowlPluginController *) controller {
	if (!sharedController) {
		sharedController = [[GrowlPluginController alloc] init];
	}
	
	return sharedController;
}

- (id) init {
	NSArray *libraries;
	NSEnumerator *enumerator;
	NSString *dir;

	if ((self = [super init])) {
		allDisplayPlugins = [[NSMutableDictionary alloc] init];
		allDisplayPluginBundles = [[NSMutableDictionary alloc] init];

		libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);

		enumerator = [libraries objectEnumerator];
		while ((dir = [enumerator nextObject])) {
			dir = [[[dir	stringByAppendingPathComponent:@"Application Support"]
							stringByAppendingPathComponent:@"Growl"]
							stringByAppendingPathComponent:@"Plugins"];
			
			[self findDisplayPluginsInDirectory:dir];
		}

		[self findDisplayPluginsInDirectory:[[[GrowlPreferences preferences] helperAppBundle] builtInPlugInsPath]];
	}

	return self;
}

#pragma mark -

+ (NSBundle *) growlPrefPaneBundle {
	NSArray			*librarySearchPaths;
	NSString		*path;
	NSString		*bundleIdentifier;
	NSEnumerator	*searchPathEnumerator;
	NSBundle		*prefPaneBundle;

	static const unsigned bundleIDComparisonFlags = NSCaseInsensitiveSearch | NSBackwardsSearch;

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask & ~NSSystemDomainMask, YES);
	
	/* First up, we'll have a look for Growl.prefPane, and if it exists, check it is our prefPane
	 * This is much faster than having to enumerate all preference panes, and can drop a significant
	 * amount of time off this code
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		path = [path stringByAppendingPathComponent:GROWL_PREFPANE_NAME];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			prefPaneBundle = [NSBundle bundleWithPath:path];
			
			if (prefPaneBundle) {
				bundleIdentifier = [prefPaneBundle bundleIdentifier];

				if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
					return prefPaneBundle;
				}
			}
		}
	}

	/* Enumerate all installed preference panes, looking for the growl prefpane bundle 
	 * identifier and stopping when we find it
	 * Note that we check the bundle identifier because we should not insist the user not 
	 * rename his preference pane files, although most users of course will not.  If the user 
	 * wants to destroy the info.plist file inside the bundle, he/she deserves not to have a 
	 * non-working Growl installation.
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		NSString				*bundlePath;
		NSDirectoryEnumerator   *bundleEnum;
		
		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
		
		while ((bundlePath = [bundleEnum nextObject])) {
			if ([[bundlePath pathExtension] isEqualToString:PREFERENCE_PANE_EXTENSION]) {
				prefPaneBundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:bundlePath]];
				
				if (prefPaneBundle) {
					bundleIdentifier = [prefPaneBundle bundleIdentifier];

					if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
						return prefPaneBundle;
					}
				}

				[bundleEnum skipDescendents];
			}
		}
	}

	return nil;
}

- (NSArray *) allDisplayPlugins {
	return [[allDisplayPluginBundles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (id <GrowlDisplayPlugin>) displayPluginNamed:(NSString *)name {
	id <GrowlDisplayPlugin> plugin = [allDisplayPlugins objectForKey:name];
	if (!plugin) {
		NSBundle *pluginBundle = [allDisplayPluginBundles objectForKey:name];
		if (pluginBundle && (plugin = [[[pluginBundle principalClass] alloc] init])) {
			[allDisplayPlugins setObject:plugin forKey:name];
			[plugin release];
		} else {
			NSLog(@"Could not load %@", name);
		}
	}

	return plugin;
}

- (NSDictionary *) infoDictionaryForPluginNamed:(NSString *)name {
	return [[allDisplayPluginBundles objectForKey:name] infoDictionary];
}

- (void) dealloc {
	[allDisplayPlugins       release];
	[allDisplayPluginBundles release];

	[super dealloc];
}

- (void) findDisplayPluginsInDirectory:(NSString *)dir {
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString *file;

	while ((file = [enumerator nextObject])) {
		if ([[file pathExtension] isEqualToString:@"growlView"]) {
			[self loadPlugin:[dir stringByAppendingPathComponent:file]];
			[enumerator skipDescendents];
		}
	}
}

- (void) loadPlugin:(NSString *)path {
	NSBundle *pluginBundle = [NSBundle bundleWithPath:path];

	if (pluginBundle) {
		NSString *pluginName = [[pluginBundle infoDictionary] objectForKey:@"GrowlPluginName"];
		if (pluginName) {
			[allDisplayPluginBundles setObject:pluginBundle forKey:pluginName];
		} else {
			NSLog(@"Plugin at path '%@' has no name", path);
		}
	} else {
		NSLog(@"Failed to load: %@", path);
	}
}

- (void) pluginInstalledSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
		NSBundle *prefPane = [GrowlPluginController growlPrefPaneBundle];

		if (prefPane && ![[NSWorkspace sharedWorkspace] openFile: [prefPane bundlePath]]) {
			NSLog( @"Could not open Growl PrefPane" );
		}
	}
}

- (void) pluginExistsSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	NSString *filename = (NSString *)contextInfo;

	if (returnCode == NSAlertAlternateReturn) {
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
		if ([fileManager copyPath:filename toPath:destination handler:nil]) {
			NSBeginInformationalAlertSheet( NSLocalizedString( @"Plugin installed", @"" ),
											NSLocalizedString( @"No", @"" ),
											NSLocalizedString( @"Yes", @"" ),
											nil, nil, self,
											@selector(pluginInstalledSelector:returnCode:contextInfo:),
											NULL, NULL,
											NSLocalizedString( @"Plugin '%@' has been installed successfully. Do you want to configure it now?", @"" ),
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

- (void) installPlugin:(NSString *)filename {
	NSString *pluginFile = [filename lastPathComponent];
	NSString *destination = [[[[[NSHomeDirectory()
		stringByAppendingPathComponent:@"Library"]
		stringByAppendingPathComponent:@"Application Support"]
		stringByAppendingPathComponent:@"Growl"]
		stringByAppendingPathComponent:@"Plugins"]
		stringByAppendingPathComponent: pluginFile];
	// retain a copy of the filename because it is passed as context to the sheetDidEnd selectors
	NSString *filenameCopy = [[NSString alloc] initWithString:filename];

	if ([[NSFileManager defaultManager] fileExistsAtPath:destination]) {
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
