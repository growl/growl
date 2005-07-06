//
//  GrowlPathUtil.m
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "GrowlPathUtilities.h"
#import "GrowlApplicationBridge.h"
#import "GrowlPreferencesController.h"
#import "GrowlTicketController.h"

static NSBundle *helperAppBundle;
static NSBundle *prefPaneBundle;

#define NAME_OF_SCREENSHOTS_DIRECTORY           @"Screenshots"
#define NAME_OF_TICKETS_DIRECTORY               @"Tickets"
#define NAME_OF_PLUGINS_DIRECTORY               @"Plugins"

#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY   @"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION               @"prefPane"

@implementation GrowlPathUtilities

#pragma mark Bundles

+ (NSBundle *) growlPrefPaneBundle {
	NSArray			*librarySearchPaths;
	NSString		*path;
	NSString		*bundleIdentifier;
	NSEnumerator	*searchPathEnumerator;
	NSBundle		*bundle;

	if (prefPaneBundle)  
		return prefPaneBundle;  

	prefPaneBundle = [NSBundle bundleWithIdentifier:GROWL_PREFPANE_BUNDLE_IDENTIFIER];
 	if (prefPaneBundle)  
		return prefPaneBundle; 

	static const unsigned bundleIDComparisonFlags = NSCaseInsensitiveSearch | NSBackwardsSearch;

	NSFileManager *fileManager = [NSFileManager defaultManager];

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask & ~NSSystemDomainMask, YES);

	/*First up, we'll look for Growl.prefPane, and if it exists, check whether
	 *	it is our prefPane.
	 *This is much faster than having to enumerate all preference panes, and
	 *	can drop a significant amount of time off this code.
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		path = [path stringByAppendingPathComponent:GROWL_PREFPANE_NAME];

		if ([fileManager fileExistsAtPath:path]) {
			bundle = [NSBundle bundleWithPath:path];

			if (bundle) {
				bundleIdentifier = [bundle bundleIdentifier];

				if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
					prefPaneBundle = bundle;
					return prefPaneBundle;
				}
			}
		}
	}

	/*Enumerate all installed preference panes, looking for the Growl prefpane
	 *	bundle identifier and stopping when we find it.
	 *Note that we check the bundle identifier because we should not insist
	 *	that the user not rename his preference pane files, although most users
	 *	of course will not.  If the user wants to mutilate the Info.plist file
	 *	inside the bundle, he/she deserves to not have a working Growl
	 *	installation.
	 */
	searchPathEnumerator = [librarySearchPaths objectEnumerator];
	while ((path = [searchPathEnumerator nextObject])) {
		NSString				*bundlePath;
		NSDirectoryEnumerator   *bundleEnum;

		path = [path stringByAppendingPathComponent:PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY];
		bundleEnum = [fileManager enumeratorAtPath:path];

		while ((bundlePath = [bundleEnum nextObject])) {
			if ([[bundlePath pathExtension] isEqualToString:PREFERENCE_PANE_EXTENSION]) {
				bundle = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:bundlePath]];

				if (bundle) {
					bundleIdentifier = [bundle bundleIdentifier];

					if (bundleIdentifier && ([bundleIdentifier compare:GROWL_PREFPANE_BUNDLE_IDENTIFIER options:bundleIDComparisonFlags] == NSOrderedSame)) {
						prefPaneBundle = bundle;
						return prefPaneBundle;
					}
				}

				[bundleEnum skipDescendents];
			}
		}
	}

	return nil;
}

+ (NSBundle *) helperAppBundle {
	if (!helperAppBundle) {
		helperAppBundle = [NSBundle bundleWithIdentifier:HelperAppBundleIdentifier];  
		if (!helperAppBundle) {  
			//look in the prefpane bundle.
			NSBundle *bundle = [GrowlPathUtilities growlPrefPaneBundle];
			NSString *helperAppPath = [bundle pathForResource:@"GrowlHelperApp" ofType:@"app"];
			helperAppBundle = [NSBundle bundleWithPath:helperAppPath];
		}
	}
	return helperAppBundle;
}

#pragma mark -
#pragma mark Directories

+ (NSArray *) searchPathForDirectory:(GrowlSearchPathDirectory) directory inDomains:(GrowlSearchPathDomainMask) domainMask mustBeWritable:(BOOL)flag {
	if (directory < GrowlSupportDirectory) {
		NSArray *searchPath = NSSearchPathForDirectoriesInDomains(directory, domainMask, /*expandTilde*/ YES);
		if (!flag)
			return searchPath;
		else {
			//flag is not NO: exclude non-writable directories.
			NSMutableArray *result = [NSMutableArray arrayWithCapacity:[searchPath count]];
			NSFileManager *mgr = [NSFileManager defaultManager];

			NSEnumerator *searchPathEnum = [searchPath objectEnumerator];
			NSString *dir;
			while ((dir = [searchPathEnum nextObject])) {
				if ([mgr isWritableFileAtPath:dir])
					[result addObject:dir];
			}

			return result;
		}
	} else {
		//determine what to append to each Application Support folder.
		NSString *subpath = nil;
		switch (directory) {
			case GrowlSupportDirectory:
				//do nothing.
				break;

			case GrowlScreenshotsDirectory:
				subpath = NAME_OF_SCREENSHOTS_DIRECTORY;
				break;

			case GrowlTicketsDirectory:
				subpath = NAME_OF_TICKETS_DIRECTORY;
				break;

			case GrowlPluginsDirectory:
				subpath = NAME_OF_PLUGINS_DIRECTORY;
				break;

			default:
				NSLog(@"ERROR: GrowlPathUtil was asked for directory 0x%x, but it doesn't know what directory that is. Please tell the Growl developers.", directory);
				return nil;
		}
		if (subpath)
			subpath = [@"Application Support/Growl" stringByAppendingPathComponent:subpath];
		else
			subpath =  @"Application Support/Growl";

		/*get the search path, and append the subpath to all the items therein.
		 *exclude results that don't exist.
		 */
		NSFileManager *mgr = [NSFileManager defaultManager];
		BOOL isDir = NO;

		NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, domainMask, /*expandTilde*/ YES);
		NSMutableArray *mSearchPath = [NSMutableArray arrayWithCapacity:[searchPath count]];
		NSEnumerator *searchPathEnum = [searchPath objectEnumerator];
		NSString *path;
		while ((path = [searchPathEnum nextObject])) {
			path = [path stringByAppendingPathComponent:subpath];
			if ([mgr fileExistsAtPath:path isDirectory:&isDir] && isDir)
				[mSearchPath addObject:path];
		}

		return mSearchPath;
	}
}

+ (NSArray *) searchPathForDirectory:(GrowlSearchPathDirectory) directory inDomains:(GrowlSearchPathDomainMask) domainMask {
	//NO to emulate the default NSSearchPathForDirectoriesInDomains behaviour.
	return [self searchPathForDirectory:directory inDomains:domainMask mustBeWritable:NO];
}

+ (NSString *) growlSupportDirectory {
	NSArray *searchPath = [self searchPathForDirectory:GrowlSupportDirectory inDomains:NSUserDomainMask mustBeWritable:YES];
	if ([searchPath count])
		return [searchPath objectAtIndex:0U];
	else {
		NSString *path = nil;

		//if this doesn't return any writable directories, path will still be nil.
		searchPath = [self searchPathForDirectory:NSLibraryDirectory inDomains:NSAllDomainsMask mustBeWritable:YES];
		if ([searchPath count]) {
			path = [[searchPath objectAtIndex:0U] stringByAppendingPathComponent:@"Application Support/Growl"];
			//try to create it. if that doesn't work, don't return it. return nil instead.
			if (![[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil])
				path = nil;
		}

		return path;
	}
}

+ (NSString *) screenshotsDirectory {
	NSArray *searchPath = [self searchPathForDirectory:GrowlScreenshotsDirectory inDomains:NSAllDomainsMask mustBeWritable:YES];
	if ([searchPath count])
		return [searchPath objectAtIndex:0U];
	else {
		NSString *path = nil;

		//if this doesn't return any writable directories, path will still be nil.
		path = [self growlSupportDirectory];
		if (path) {
			path = [path stringByAppendingPathComponent:NAME_OF_SCREENSHOTS_DIRECTORY];
			//try to create it. if that doesn't work, don't return it. return nil instead.
			if (![[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil])
				path = nil;
		}

		return path;
	}
}

+ (NSString *) ticketsDirectory {
	NSArray *searchPath = [self searchPathForDirectory:GrowlTicketsDirectory inDomains:NSAllDomainsMask mustBeWritable:YES];
	if ([searchPath count])
		return [searchPath objectAtIndex:0U];
	else {
		NSString *path = nil;
		
		//if this doesn't return any writable directories, path will still be nil.
		path = [self growlSupportDirectory];
		if (path) {
			path = [path stringByAppendingPathComponent:NAME_OF_TICKETS_DIRECTORY];
			//try to create it. if that doesn't work, don't return it. return nil instead.
			if (![[NSFileManager defaultManager] createDirectoryAtPath:path attributes:nil])
				path = nil;
		}
		
		return path;
	}
}

#pragma mark -
#pragma mark Screenshot names

+ (NSString *) nextScreenshotName {
	return [self nextScreenshotNameInDirectory:nil];
}

+ (NSString *) nextScreenshotNameInDirectory:(NSString *) directory {
	NSFileManager *mgr = [NSFileManager defaultManager];

	if (!directory)
		directory = [GrowlPathUtilities screenshotsDirectory];

	//build a set of all the files in the directory, without their filename extensions.
	NSArray *origContents = [mgr directoryContentsAtPath:directory];
	NSMutableSet *directoryContents = [[NSMutableSet alloc] initWithCapacity:[origContents count]];

	NSEnumerator *filesEnum = [origContents objectEnumerator];
	NSString *existingFilename;
	while ((existingFilename = [filesEnum nextObject]))
		[directoryContents addObject:[existingFilename stringByDeletingPathExtension]];

	//look for a filename that doesn't exist (with any extension) in the directory.
	NSString *filename = nil;
	for (unsigned long long i = 1ULL; i < ULLONG_MAX; ++i) {
		[filename release];
		filename = [[NSString alloc] initWithFormat:@"Screenshot %llu", i];
		if (![directoryContents containsObject:filename])
			break;
	}
	[directoryContents release];

	return [filename autorelease];
}

#pragma mark -
#pragma mark Tickets

+ (NSString *) defaultSavePathForTicketWithApplicationName:(NSString *) appName {
	return [[self ticketsDirectory] stringByAppendingPathComponent:[appName stringByAppendingPathExtension:GROWL_PATHEXTENSION_TICKET]];
}

@end
