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
	NSMutableDictionary * domain = [[helperAppDefaults persistentDomainForName:HelperAppBundleIdentifier] mutableCopy];
	if (!domain) {
		domain = [[NSMutableDictionary alloc] init];
	}

	NSEnumerator		* e = [inDefaults keyEnumerator];
	NSString			* key;
	
	while ((key = [e nextObject])) {
		if (![domain objectForKey:key]) {
			[domain setObject:[inDefaults objectForKey:key] forKey:key];
		}
	}
	
	[helperAppDefaults setPersistentDomain:domain forName:HelperAppBundleIdentifier];
	
	[domain release];
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

- (NSBundle *) helperAppBundle {
	if (!helperAppBundle) {
		if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:HelperAppBundleIdentifier]) {
			//We are running in the GHA bundle
			helperAppBundle = [NSBundle mainBundle];
		} else {
			//We are running in the prefpane
			NSString * helperPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
			helperAppBundle = [NSBundle bundleWithPath:helperPath];
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

- (BOOL) startGrowlAtLogin {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSArray        *loginItems = [[defs persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"];

	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA      = [[NSBundle bundleForClass:[self class]] pathForResource:@"GrowlHelperApp" ofType:@"app"];
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
	NSString *pathToGHA      = [[NSBundle bundleForClass:[self class]] pathForResource:@"GrowlHelperApp" ofType:@"app"];
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
	NSMutableDictionary *loginWindowPrefs = [[[defs persistentDomainForName:@"loginwindow"] mutableCopy] autorelease];
	NSMutableArray      *loginItems = [[[loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy] autorelease];

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
		NSDictionary *launchDict = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithBool:NO], @"Hide",
			pathToGHA,                    @"Path",
			aliasDataToGHA,               @"AliasData",
			nil];
		[loginItems addObject:launchDict];
	}

	//save to disk.
	[loginWindowPrefs setObject:[NSArray arrayWithArray:loginItems] 
						 forKey:@"AutoLaunchedApplicationDictionary"];
	[defs setPersistentDomain:[NSDictionary dictionaryWithDictionary:loginWindowPrefs] 
					  forName:@"loginwindow"];
	[defs synchronize];
}

@end
