//
//  GrowlPluginController.m
//  Growl
//
//  Created by Nelson Elhage on 8/25/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlPluginController.h"

#define GROWL_PREFPANE_BUNDLE_IDENTIFIER		@"com.growl.prefpanel"
#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY	@"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION				@"prefPane"

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

//Returns an array of paths to all user-installed .prefPane bundles
+ (NSArray *)_allPreferencePaneBundles
{
	NSArray			*librarySearchPaths;
	NSEnumerator	*searchPathEnumerator;
	NSString		*preferencePanesSubfolder, *path, *prefPaneExtension;
	NSMutableArray  *pathArray = [NSMutableArray arrayWithCapacity:4];
	NSMutableArray  *allPreferencePaneBundles = [NSMutableArray array];
	
	preferencePanesSubfolder = PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY;
	
	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSAllDomainsMask & (~NSSystemDomainMask), YES );
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	
	//Copy each discovered path into the pathArray after adding our subfolder path
	while( (path = [searchPathEnumerator nextObject] ) ) {
		[pathArray addObject:[path stringByAppendingPathComponent:preferencePanesSubfolder]];
	}
	
	prefPaneExtension = PREFERENCE_PANE_EXTENSION;
	
	searchPathEnumerator = [pathArray objectEnumerator];		
    while( ( path = [searchPathEnumerator nextObject] ) ) {
		
        NSString				*bundlePath;
		NSDirectoryEnumerator   *bundleEnum;
		
        bundleEnum = [[NSFileManager defaultManager] enumeratorAtPath:path];
		
        if(bundleEnum) {
            while( ( bundlePath = [bundleEnum nextObject] ) ) {
                if([[bundlePath pathExtension] isEqualToString:prefPaneExtension]) {
					[allPreferencePaneBundles addObject:[path stringByAppendingPathComponent:bundlePath]];
                }
            }
        }
    }
	
	return allPreferencePaneBundles;
}

+ (NSBundle *)growlPrefPaneBundle
{
	NSString		*path;
	NSString		*bundleIdentifier;
	NSEnumerator	*preferencePanesPathsEnumerator;
	NSBundle		*prefPaneBundle;
	NSBundle		*growlPrefPaneBundle = nil;
	
	//Enumerate all installed preference panes, looking for the growl prefpane bundle identifier and stopping when we find it
	//Note that we check the bundle identifier because we should not insist the user not rename his preference pane files, although most users
	//of course will not.  If the user wants to destroy the info.plist file inside the bundle, he/she deserves not to have a working Growl installation.
	preferencePanesPathsEnumerator = [[GrowlPluginController _allPreferencePaneBundles] objectEnumerator];
	while( (path = [preferencePanesPathsEnumerator nextObject] ) ) {
		prefPaneBundle = [NSBundle bundleWithPath:path];
		if (prefPaneBundle) {
			bundleIdentifier = [prefPaneBundle bundleIdentifier];
			if (bundleIdentifier && [bundleIdentifier isEqualToString:GROWL_PREFPANE_BUNDLE_IDENTIFIER]) {
				growlPrefPaneBundle = prefPaneBundle;
				break;
			}
		}
	}
	
	return( growlPrefPaneBundle );
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

- (void)pluginInstalledSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if( returnCode == NSAlertAlternateReturn ) {
		NSBundle *prefPane = [GrowlPluginController growlPrefPaneBundle];
		if( prefPane ) {
			if( ![[NSWorkspace sharedWorkspace] openFile: [prefPane bundlePath]] ) {
				NSLog( @"Could not open Growl PrefPane" );
			}
		}
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
