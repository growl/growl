//
//  GrowlPreferences.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlPreferences.h"
#import "NSGrowlAdditions.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#include <Carbon/Carbon.h>

static GrowlPreferences * sharedPreferences;

@implementation GrowlPreferences

+ (GrowlPreferences *) preferences {
	if (!sharedPreferences) {
		sharedPreferences = [[GrowlPreferences alloc] init];
	}
	return sharedPreferences;
}

- (id) init {
	if ((self = [super init])) {
		helperAppDefaults = [[NSUserDefaults alloc] init];
		[helperAppDefaults addSuiteNamed:HelperAppBundleIdentifier];
	}
	return self;
}

- (void) dealloc {
	[helperAppDefaults release];
	
	[super dealloc];
}

#pragma mark -

- (void) registerDefaults:(NSDictionary *)inDefaults {
	NSDictionary *existing = [helperAppDefaults persistentDomainForName:HelperAppBundleIdentifier];
	if (existing) {
		NSMutableDictionary *domain = [inDefaults mutableCopy];
		[domain addEntriesFromDictionary:existing];
		[helperAppDefaults setPersistentDomain:domain forName:HelperAppBundleIdentifier];
		[domain release];
	} else {
		[helperAppDefaults setPersistentDomain:inDefaults forName:HelperAppBundleIdentifier];
	}
}

- (id) objectForKey:(NSString *)key {
	[helperAppDefaults synchronize];
	return [helperAppDefaults objectForKey:key];
}

- (void) setObject:(id)object forKey:(NSString *) key {
	CFPreferencesSetAppValue((CFStringRef)key			/* key */,
							 (CFPropertyListRef)object /* value */,
							 (CFStringRef)HelperAppBundleIdentifier) /* application ID */;\

	CFPreferencesAppSynchronize((CFStringRef)HelperAppBundleIdentifier);

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged
																   object:key];
}

- (void) synchronize {
	[helperAppDefaults synchronize];
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -
#pragma mark Ganked from GrowlApplicationBridge

#warning XXX - need to find someplace to put this code so it isnt duplicated --boredzo

#define GROWL_PREFPANE_BUNDLE_IDENTIFIER		@"com.growl.prefpanel"
#define GROWL_PREFPANE_NAME						@"Growl.prefPane"
#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY	@"PreferencePanes"
#define PREFERENCE_PANE_EXTENSION				@"prefPane"

+ (NSBundle *) growlPrefPaneBundle {
	NSArray			*librarySearchPaths;
	NSString		*path;
	NSString		*bundleIdentifier;
	NSEnumerator	*searchPathEnumerator;
	NSBundle		*prefPaneBundle;

	static const unsigned bundleIDComparisonFlags = NSCaseInsensitiveSearch | NSBackwardsSearch;

	//Find Library directories in all domains except /System (as of Panther, that's ~/Library, /Library, and /Network/Library)
	librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask & ~NSSystemDomainMask, YES);

	/*First up, we'll have a look for Growl.prefPane, and if it exists, check
	 *	whether it is our prefPane.
	 *This is much faster than having to enumerate all preference panes, and
	 *	can drop a significant amount of time off this code.
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

#pragma mark -
#pragma mark Important file-system objects

- (NSBundle *) helperAppBundle {
	if (!helperAppBundle) {
		NSBundle *bundle = [NSBundle mainBundle];
		if ([[bundle bundleIdentifier] isEqualToString:HelperAppBundleIdentifier]) {
			//we are running in GHA.
			helperAppBundle = bundle;
		} else {
			//look in the prefpane bundle.
			bundle = [NSBundle bundleForClass:[GrowlPreferences class]];
			if (![[bundle bundleIdentifier] isEqualToString:GROWL_PREFPANE_BUNDLE_IDENTIFIER]) {
				bundle = [GrowlPreferences growlPrefPaneBundle];
			}
			NSString *helperAppPath = [bundle pathForResource:@"GrowlHelperApp" ofType:@"app"];
			helperAppBundle = [NSBundle bundleWithPath:helperAppPath];
		}
	}
	return helperAppBundle;
}

- (NSString *) growlSupportDir {
	NSString *supportDir;
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, /* expandTilde */ YES);

	supportDir = [searchPath objectAtIndex:0U];
	supportDir = [supportDir stringByAppendingPathComponent:@"Application Support"];
	supportDir = [supportDir stringByAppendingPathComponent:@"Growl"];

	return supportDir;
}

#pragma mark -
#pragma mark Start-at-login control

- (BOOL) startGrowlAtLogin {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSArray        *loginItems = [[defs persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"];

	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA      = [[NSBundle bundleForClass:[GrowlPreferences class]] pathForResource:@"GrowlHelperApp" ofType:@"app"];
	//get an Alias (as in Alias Manager) representation of same.
	NSURL    *URLToGHA       = [NSURL fileURLWithPath:pathToGHA];

	BOOL foundIt = NO;

	NSEnumerator *e = [loginItems objectEnumerator];
	NSDictionary *item;
	while ((item = [e nextObject])) {
		/*first compare by alias.
		 *we do this by converting to URL and comparing those.
		 */
		NSData *thisAliasData = [item objectForKey:@"AliasData"];
		if (thisAliasData) {
			NSURL *thisURL = [NSURL fileURLWithAliasData:thisAliasData];
			foundIt = [thisURL isEqual:URLToGHA];
		} else {
			//nope, not the same alias. try comparing by path.
			NSString *thisPath = [[item objectForKey:@"Path"] stringByExpandingTildeInPath];
			foundIt = (thisPath && [thisPath isEqualToString:pathToGHA]);
		}

		if (foundIt)
			break;
	}

	return foundIt;
}

- (void) setStartGrowlAtLogin:(BOOL)flag {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA      = [[NSBundle bundleForClass:[GrowlPreferences class]] pathForResource:@"GrowlHelperApp" ofType:@"app"];
	//get an Alias (as in Alias Manager) representation of same.
	NSURL    *URLToGHA       = [NSURL fileURLWithPath:pathToGHA];
	NSData   *aliasDataToGHA = [URLToGHA aliasData];

	/*the start-at-login pref is an array of dictionaries, like so:
	 *	{
	 *		AliasData = <...>
	 *		Hide = Boolean (maps to kLSLaunchAndHide)
	 *		Path = POSIX path to the bundle, file, or folder (in that order of
	 *			preference)
	 *	}
	 */
	NSMutableDictionary *loginWindowPrefs = [[defs persistentDomainForName:@"loginwindow"] mutableCopy];
	NSMutableArray      *loginItems = [[loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy];

	/*remove any previous mentions of this GHA in the start-at-login array.
	 *note that other GHAs are ignored.
	 */
	BOOL foundOne = NO;

	for (unsigned i = 0U, numItems = [loginItems count]; i < numItems; ) {
		NSDictionary *item = [loginItems objectAtIndex:i];
		BOOL thisIsUs = NO;

		/*first compare by alias.
		 *we do this by converting to URL and comparing those.
		 */
		NSString *thisPath = [[item objectForKey:@"Path"] stringByExpandingTildeInPath];
		NSData *thisAliasData = [item objectForKey:@"AliasData"];
		if (thisAliasData) {
			NSURL *thisURL = [NSURL fileURLWithAliasData:thisAliasData];
			thisIsUs = [thisURL isEqual:URLToGHA];
		} else {
			//nope, not the same alias. try comparing by path.
			/*NSString **/thisPath = [[item objectForKey:@"Path"] stringByExpandingTildeInPath];
			thisIsUs = (thisPath && [thisPath isEqualToString:pathToGHA]);
		}

		if (thisIsUs && ((!flag) || (!foundOne))) {
			[loginItems removeObjectAtIndex:i];
			--numItems;
			foundOne = YES;
		} else //only increment if we did not change the array
			++i;
	}

	if (flag && !foundOne) {
		/*we were called with YES, and we weren't already in the start-at-login
		 *	array, so add ourselves to its end.
		 */
		NSNumber *hide = [[NSNumber alloc] initWithBool:NO];
		NSDictionary *launchDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			hide,           @"Hide",
			pathToGHA,      @"Path",
			aliasDataToGHA, @"AliasData",
			nil];
		[hide release];
		[loginItems addObject:launchDict];
		[launchDict release];
	}

	//save to disk.
	[loginWindowPrefs setObject:loginItems
						 forKey:@"AutoLaunchedApplicationDictionary"];
	[loginItems release];
	[defs setPersistentDomain:loginWindowPrefs forName:@"loginwindow"];
	[loginWindowPrefs release];
	[defs synchronize];
}

#pragma mark -
#pragma mark Growl running state

- (void) setGrowlRunning:(BOOL)flag {
	// Store the desired running-state of the helper app for use by GHA.
	NSNumber *growlEnabled = [[NSNumber alloc] initWithBool:flag];
	[self setObject:growlEnabled forKey:GrowlEnabledKey];
	[growlEnabled release];

	//now launch or terminate as appropriate.
	if (flag)
		[self launchGrowl];
	else		
		[self terminateGrowl];
}

- (BOOL)isGrowlRunning {
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };

	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		NSString *bundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
		isRunning = bundleID && [bundleID isEqualToString:@"com.Growl.GrowlHelperApp"];
		[infoDict release];

		if (isRunning)
			break;
	}

	return isRunning;
}

- (void) launchGrowl {
	NSString *helperPath = [[self helperAppBundle] bundlePath];

	// We want to launch in background, so we have to resort to Carbon
	LSLaunchFSRefSpec spec;
	FSRef appRef;
	OSStatus status = FSPathMakeRef((const UInt8 *)[helperPath fileSystemRepresentation], &appRef, NULL);
	
	if (status == noErr) {
		spec.appRef = &appRef;
		spec.numDocs = 0;
		spec.itemRefs = NULL;
		spec.passThruParams = NULL;
		spec.launchFlags = kLSLaunchNoParams | kLSLaunchAsync | kLSLaunchDontSwitch;
		spec.asyncRefCon = NULL;
		status = LSOpenFromRefSpec(&spec, NULL);
	}	
}

- (void) terminateGrowl {
	// Ask the Growl Helper App to shutdown via the DNC
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN object:nil];
}


@end
