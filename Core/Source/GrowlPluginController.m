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
#import "GrowlPathUtilities.h"
#import "GrowlWebKitController.h"

static GrowlPluginController *sharedController;

@interface GrowlPluginController (PRIVATE)
- (void) loadPlugin:(NSString *)path;
- (void) findPluginsInDirectory:(NSString *)dir;
- (void) pluginInstalledSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void) pluginExistsSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
@end

@interface WebCoreCache
+ (void) empty;
@end

//for use as CFSetCallBacks.equal
static Boolean caseInsensitiveStringComparator(const void *value1, const void *value2);

#pragma mark -

@implementation GrowlPluginController

+ (GrowlPluginController *) sharedController {
	if (!sharedController) {
		sharedController = [[GrowlPluginController alloc] init];
	}

	return sharedController;
}

- (id) init {
	if ((self = [super init])) {
		pluginInstances = [[NSMutableDictionary alloc] init];
		pluginBundles   = [[NSMutableDictionary alloc] init];

		NSArray *libraries = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
		NSEnumerator *enumerator = [libraries objectEnumerator];
		NSString *dir;
		while ((dir = [enumerator nextObject])) {
			dir = [dir stringByAppendingPathComponent:@"Application Support/Growl/Plugins"];
			[self findPluginsInDirectory:dir];
		}

		NSBundle *helperAppBundle = [GrowlPathUtilities helperAppBundle];
		[self findPluginsInDirectory:[helperAppBundle builtInPlugInsPath]];
	}

	return self;
}

- (void) dealloc {
	[pluginInstances release];
	[pluginBundles   release];

	[super dealloc];
}

#pragma mark -

- (NSSet *) pluginPathExtensions {
	//XXX: make this non-hard-coded so that plug-ins can have plug-ins
	NSString *pathExtensions[] = { @"growlStyle", @"growlView", @"growlPlugin" };
	static CFSetCallBacks callbacks = kCFTypeSetCallBacks; //XXX use kCFCopyStringSetCallBacks when making this mutable
	static BOOL hasSetUpCallbacks = NO;
	if(!hasSetUpCallbacks)
		callbacks.equal = caseInsensitiveStringComparator;
	return [CFSetCreate(kCFAllocatorDefault,
	                    pathExtensions,
	                    /*numValues*/ 2,
	                    &callbacks) autorelease];
}

- (void) addPluginPathExtension:(NSString *)ext {
	//XXX
}

#pragma mark -

- (NSArray *) pluginsOfType:(NSString *)type {
	NSParameterAssert(type != nil);

	NSMutableArray *array = [NSMutableArray arrayWithCapacity:pluginBundles];

	NSEnumerator *pluginBundlesEnum = [pluginBundles objectEnumerator];
	NSBundle *bundle;
	while((bundle = [pluginBundlesEnum nextObject])) {
		if([[[bundle path] pathExtension] caseInsensitiveCompare:type] == NSOrderedSame)
			[array addObject:bundle];
	}

	return array;
}

- (NSArray *) displayPlugins {
	return [[pluginBundles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

#pragma mark -

- (GrowlDisplayPlugin *) displayPluginNamed:(NSString *)name {
	GrowlDisplayPlugin *plugin = [pluginInstances objectForKey:name];
	if (!plugin) {
		NSBundle *pluginBundle = [pluginBundles objectForKey:name];
		NSString *filename = [[pluginBundle bundlePath] lastPathComponent];
		NSString *pathExtension = [filename pathExtension];
		if ([pathExtension isEqualToString:GROWL_VIEW_EXTENSION]) {
			if (pluginBundle && (plugin = [[[pluginBundle principalClass] alloc] init])) {
				[allDisplayPlugins setObject:plugin forKey:name];
				[plugin release];
			} else {
				NSLog(@"Could not load %@", name);
			}
		} else if ([pathExtension isEqualToString:GROWL_STYLE_EXTENSION]) {
			// empty the WebCoreCache to reload stylesheets
			Class webCoreCache = NSClassFromString(@"WebCoreCache");
			[webCoreCache empty];

			// load GrowlWebKitController dynamically so that GrowlMenu does not
			// have to link against it and all of its dependencies
			Class webKitController = NSClassFromString(@"GrowlWebKitController");
			plugin = [[webKitController alloc] initWithStyle:name];
			[allDisplayPlugins setObject:plugin forKey:name];
			[plugin release];
		} else {
			NSLog(@"Unknown plugin filename extension '%@' (from filename '%@' of plugin named '%@')", pathExtension, filename, name);
		}
	}

	return plugin;
}

- (NSBundle *) displayPluginBundleWithName:(NSString *)name {
	GrowlDisplayPlugin *plugin = [pluginBundles objectForKey:name];
	return [plugin isKindOfClass:[GrowlDisplayPlugin class]] ? plugin : nil;
}

- (void) findPluginsInDirectory:(NSString *)dir {
	NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:dir];
	NSString *file;
	while ((file = [enumerator nextObject])) {
		NSString *pathExtension = [file pathExtension];
		if ([pathExtension isEqualToString:GROWL_VIEW_EXTENSION] || [pathExtension isEqualToString:GROWL_STYLE_EXTENSION]) {
			[self loadPlugin:[dir stringByAppendingPathComponent:file]];
			[enumerator skipDescendents];
		}
	}
}

- (void) loadPlugin:(NSString *)path {
	NSBundle *pluginBundle = [[NSBundle alloc] initWithPath:path];

	if (pluginBundle) {
		// TODO: We should use CFBundleIdentifier as the key and display CFBundleName to the user
		NSString *pluginName = [[pluginBundle infoDictionary] objectForKey:(NSString *)kCFBundleNameKey];
		if (pluginName) {
			[allDisplayPluginBundles setObject:pluginBundle forKey:pluginName];
			[allDisplayPlugins removeObjectForKey:pluginName];
		} else {
			NSLog(@"Plugin at path '%@' has no name", path);
		}
		[pluginBundle release];
	} else {
		NSLog(@"Failed to load: %@", path);
	}
}

- (void) pluginInstalledSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
#pragma unused(sheet, contextInfo)
	if (returnCode == NSAlertAlternateReturn) {
		NSBundle *prefPane = [GrowlPathUtilities growlPrefPaneBundle];

		if (prefPane && ![[NSWorkspace sharedWorkspace] openFile: [prefPane bundlePath]]) {
			NSLog(@"Could not open Growl PrefPane");
		}
	}
}

- (void) pluginExistsSelector:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
#pragma unused(sheet)
	NSString *filename = (NSString *)contextInfo;

	if (returnCode == NSAlertAlternateReturn) {
		NSString *pluginFile = [filename lastPathComponent];
		NSString *destination = [[NSHomeDirectory()
			stringByAppendingPathComponent:@"Library/Application Support/Growl/Plugins"]
			stringByAppendingPathComponent:pluginFile];
		NSFileManager *fileManager = [NSFileManager defaultManager];

		// first remove old copy if present
		[fileManager removeFileAtPath:destination handler:nil];

		// copy new version to destination
		if ([fileManager copyPath:filename toPath:destination handler:nil]) {
			[self loadPlugin:destination];
			NSBeginInformationalAlertSheet( NSLocalizedString( @"Plugin installed", @"" ),
											NSLocalizedString( @"No",  @"" ),
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
	NSString *destination = [[NSHomeDirectory()
		stringByAppendingPathComponent:@"Library/Application Support/Growl/Plugins"]
		stringByAppendingPathComponent:pluginFile];
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

static Boolean caseInsensitiveStringComparator(const void *value1, const void *value2) {
	Class NSStringClass = [NSString class];
	return [(id)value1 isKindOfClass:NSStringClass] \
	    && [(id)value2 isKindOfClass:NSStringClass]  \
	    && ([(NSString *)value1 caseInsensitiveCompare:(NSString *)value2] == NSOrderedSame);
}
