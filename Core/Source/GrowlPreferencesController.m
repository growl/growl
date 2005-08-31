//
//  GrowlPreferencesController.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Renamed from GrowlPreferences.m by Mac-arena the Bored Zo on 2005-06-27.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlPreferencesController.h"
#import "NSURLAdditions.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlPathUtilities.h"
#import "NSStringAdditions.h"
#import <Security/SecKeychain.h>
#import <Security/SecKeychainItem.h>
#include <Carbon/Carbon.h>

#define keychainServiceName "Growl"
#define keychainAccountName "Growl"

@implementation GrowlPreferencesController

+ (GrowlPreferencesController *) sharedController {
	static GrowlPreferencesController *sharedPreferences = nil;

	if (!sharedPreferences)
		sharedPreferences = [[GrowlPreferencesController alloc] init];

	return sharedPreferences;
}

- (id) init {
	if ((self = [super init])) {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(growlPreferencesChanged:)
																name:GrowlPreferencesChanged
															  object:nil];		
	}
	return self;
}

- (void) dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

#pragma mark -

- (void) registerDefaults:(NSDictionary *)inDefaults {
	NSUserDefaults *helperAppDefaults = [[NSUserDefaults alloc] init];
	[helperAppDefaults addSuiteNamed:HelperAppBundleIdentifier];
	NSDictionary *existing = [helperAppDefaults persistentDomainForName:HelperAppBundleIdentifier];
	if (existing) {
		NSMutableDictionary *domain = [inDefaults mutableCopy];
		[domain addEntriesFromDictionary:existing];
		[helperAppDefaults setPersistentDomain:domain forName:HelperAppBundleIdentifier];
		[domain release];
	} else {
		[helperAppDefaults setPersistentDomain:inDefaults forName:HelperAppBundleIdentifier];
	}
	[helperAppDefaults release];
	SYNCHRONIZE_GROWL_PREFS();
}

- (id) objectForKey:(NSString *)key {
	id value = (id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)HelperAppBundleIdentifier);
	return [value autorelease];
}

- (void) setObject:(id)object forKey:(NSString *)key {
	CFPreferencesSetAppValue((CFStringRef)key,
							 (CFPropertyListRef)object,
							 (CFStringRef)HelperAppBundleIdentifier);

	SYNCHRONIZE_GROWL_PREFS();

	NSNumber *pid = [[NSNumber alloc] initWithInt:[[NSProcessInfo processInfo] processIdentifier]];
	NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:pid, @"pid", nil];
	[pid release];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged
																   object:key
																 userInfo:userInfo];
	[userInfo release];
}

- (BOOL) boolForKey:(NSString *)key {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppBooleanValue((CFStringRef)key, (CFStringRef)HelperAppBundleIdentifier, &keyExistsAndHasValidFormat);
}

- (void) setBool:(BOOL)value forKey:(NSString *)key {
	NSNumber *object = [[NSNumber alloc] initWithBool:value];
	[self setObject:object forKey:key];
	[object release];
}

- (int) integerForKey:(NSString *)key {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppIntegerValue((CFStringRef)key, (CFStringRef)HelperAppBundleIdentifier, &keyExistsAndHasValidFormat);
}

- (void) setInteger:(int)value forKey:(NSString *)key {
	NSNumber *object = [[NSNumber alloc] initWithInt:value];
	[self setObject:object forKey:key];
	[object release];
}

- (void) synchronize {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -
#pragma mark Start-at-login control

- (BOOL) shouldStartGrowlAtLogin {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSArray        *loginItems = [[defs persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"];

	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA      = [[NSBundle bundleWithIdentifier:@"com.growl.prefpanel"] pathForResource:@"GrowlHelperApp" ofType:@"app"];
	//get an Alias (as in Alias Manager) representation of same.
	NSURL    *urlToGHA       = [[NSURL alloc] initFileURLWithPath:pathToGHA];

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
			foundIt = [thisURL isEqual:urlToGHA];
		} else {
			//nope, not the same alias. try comparing by path.
			NSString *thisPath = [[item objectForKey:@"Path"] stringByExpandingTildeInPath];
			foundIt = (thisPath && [thisPath isEqualToString:pathToGHA]);
		}

		if (foundIt)
			break;
	}
	[urlToGHA release];

	return foundIt;
}

- (void) setShouldStartGrowlAtLogin:(BOOL)flag {
	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA = [[NSBundle bundleWithIdentifier:@"com.growl.prefpanel"] pathForResource:@"GrowlHelperApp" ofType:@"app"];
	[self setStartAtLogin:pathToGHA enabled:flag];
}

- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)flag {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

	//get an Alias (as in Alias Manager) representation of same.
	NSURL    *url       = [[NSURL alloc] initFileURLWithPath:path];
	NSData   *aliasData = [url aliasData];

	/*the start-at-login pref is an array of dictionaries, like so:
	 *	{
	 *		AliasData = <...>
	 *		Hide = Boolean (maps to kLSLaunchAndHide)
	 *		Path = POSIX path to the bundle, file, or folder (in that order of
	 *			preference)
	 *	}
	 */
	NSMutableDictionary *loginWindowPrefs = [[defs persistentDomainForName:@"loginwindow"] mutableCopy];
	if (!loginWindowPrefs)
		loginWindowPrefs = [[NSMutableDictionary alloc] initWithCapacity:1U];

	NSMutableArray      *loginItems = [[loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"] mutableCopy];
	if (!loginItems)
		loginItems = [[NSMutableArray alloc] initWithCapacity:1U];

	/*remove any previous mentions of this GHA in the start-at-login array.
	 *note that other GHAs are ignored.
	 */
	BOOL			foundOne = NO;
	
	for (unsigned i = 0U; i < [loginItems count];) {
		NSDictionary	*item = [loginItems objectAtIndex:i];
		BOOL			thisIsUs = NO;		
		
		/*first compare by alias.
		*we do this by converting to URL and comparing those.
		*/
		NSString *thisPath = [[item objectForKey:@"Path"] stringByExpandingTildeInPath];
		NSData *thisAliasData = [item objectForKey:@"AliasData"];
		if (thisAliasData) {
			NSURL *thisURL = [NSURL fileURLWithAliasData:thisAliasData];
			thisIsUs = [thisURL isEqual:url];
		} else {
			//nope, not the same alias. try comparing by path.
			/*NSString **/thisPath = [[item objectForKey:@"Path"] stringByExpandingTildeInPath];
			thisIsUs = (thisPath && [thisPath isEqualToString:path]);
		}
		
		if (thisIsUs) {
			if ((!flag) || (foundOne))
				[loginItems removeObjectAtIndex:i];
			else {
				foundOne = YES;
				++i;
			}
		} else {
			++i;
		}
	}
	[url release];
	
	if (flag && !foundOne) {
		/*we were called with YES, and we weren't already in the start-at-login  
		*      array, so add ourselves at the beginning.  
		*/ 
		
		NSNumber *hide = [[NSNumber alloc] initWithBool:NO];
		NSDictionary *launchDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			hide,      @"Hide",
			path,      @"Path",
			aliasData, @"AliasData",
			nil];
		[hide release];
		[loginItems insertObject:launchDict atIndex:0U];
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
#pragma mark GrowlMenu running state

- (void) enableGrowlMenu {
	NSBundle *bundle = [NSBundle bundleForClass:[GrowlPreferencesController class]];
	NSString *growlMenuPath = [bundle pathForResource:@"GrowlMenu" ofType:@"app"];
	NSURL *growlMenuURL = [NSURL fileURLWithPath:growlMenuPath];
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:growlMenuURL]
	                withAppBundleIdentifier:nil
	                                options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync
	         additionalEventParamDescriptor:nil
	                      launchIdentifiers:NULL];
}

- (void) disableGrowlMenu {
	// Ask GrowlMenu to shutdown via the DNC
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"GrowlMenuShutdown" object:nil];
}

#pragma mark -
#pragma mark Growl running state

- (void) setGrowlRunning:(BOOL)flag noMatterWhat:(BOOL)nmw {
	// Store the desired running-state of the helper app for use by GHA.
	[self setBool:flag forKey:GrowlEnabledKey];

	//now launch or terminate as appropriate.
	if (flag)
		[self launchGrowl:nmw];
	else
		[self terminateGrowl];
}

- (BOOL) isRunning:(NSString *)theBundleIdentifier {
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };

	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		NSString *bundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
		isRunning = bundleID && [bundleID isEqualToString:theBundleIdentifier];
		[infoDict release];

		if (isRunning)
			break;
	}

	return isRunning;
}

- (BOOL) isGrowlRunning {
	return [self isRunning:@"com.Growl.GrowlHelperApp"];
}

- (void) launchGrowl:(BOOL)noMatterWhat {
	NSString *helperPath = [[GrowlPathUtilities helperAppBundle] bundlePath];
	NSURL *helperURL = [NSURL fileURLWithPath:helperPath];

	unsigned options = NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync;
	if (noMatterWhat)
		options |= NSWorkspaceLaunchNewInstance;
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:helperURL]
	                withAppBundleIdentifier:nil
	                                options:options
	         additionalEventParamDescriptor:nil
	                      launchIdentifiers:NULL];
}

- (void) terminateGrowl {
	// Ask the Growl Helper App to shutdown via the DNC
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_SHUTDOWN object:nil];
}

#pragma mark -
//Simplified accessors

#pragma mark UI

- (BOOL) isBackgroundUpdateCheckEnabled {
	return [self boolForKey:GrowlUpdateCheckKey];
}
- (void) setIsBackgroundUpdateCheckEnabled:(BOOL)flag {
	[self setBool:flag forKey:GrowlUpdateCheckKey];
}

- (NSString *) defaultDisplayPluginName {
	return [self objectForKey:GrowlDisplayPluginKey];
}
- (void) setDefaultDisplayPluginName:(NSString *)name {
	[self setObject:name forKey:GrowlDisplayPluginKey];
}

- (BOOL) squelchMode {
	return [self boolForKey:GrowlSquelchModeKey];
}
- (void) setSquelchMode:(BOOL)flag {
	[self setBool:flag forKey:GrowlSquelchModeKey];
}

- (BOOL) stickyWhenAway {
	return [self boolForKey:GrowlStickyWhenAwayKey];
}
- (void) setStickyWhenAway:(BOOL)flag {
	[self setBool:flag forKey:GrowlStickyWhenAwayKey];
}

#pragma mark Status Item

- (BOOL) isGrowlMenuEnabled {
	return [self boolForKey:GrowlMenuExtraKey];
}

- (void) setGrowlMenuEnabled:(BOOL)state {
	if (state != [self isGrowlMenuEnabled]) {
		[self setBool:state forKey:GrowlMenuExtraKey];
		if (state)
			[self enableGrowlMenu];
		else
			[self disableGrowlMenu];
	}
}

#pragma mark Logging

- (BOOL) loggingEnabled {
	return [[GrowlPreferencesController sharedController] boolForKey:GrowlLoggingEnabledKey];
}

- (void) setLoggingEnabled:(BOOL)flag {
	[[GrowlPreferencesController sharedController] setBool:flag forKey:GrowlLoggingEnabledKey];
}


- (BOOL) isGrowlServerEnabled {
	return [[GrowlPreferencesController sharedController] boolForKey:GrowlStartServerKey];
}

- (void) setGrowlServerEnabled:(BOOL)enabled {
	[[GrowlPreferencesController sharedController] setBool:enabled forKey:GrowlStartServerKey];
}

#pragma mark Remote Growling

- (BOOL) isRemoteRegistrationAllowed {
	return [[GrowlPreferencesController sharedController] boolForKey:GrowlRemoteRegistrationKey];
}

- (void) setRemoteRegistrationAllowed:(BOOL)flag {
	[[GrowlPreferencesController sharedController] setBool:flag forKey:GrowlRemoteRegistrationKey];
}

- (NSString *) remotePassword {
	char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword(NULL,
											strlen(keychainServiceName), keychainServiceName,
											strlen(keychainAccountName), keychainAccountName,
											&passwordLength, (void **)&password, NULL);

	NSString *passwordString;
	if (status == noErr) {
		passwordString = [NSString stringWithUTF8String:password length:passwordLength];
		SecKeychainItemFreeContent(NULL, password);
	} else {
		if (status != errSecItemNotFound)
			NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
		passwordString = @"";
	}

	return passwordString;
}

- (void) setRemotePassword:(NSString *)value {
	const char *password = value ? [value UTF8String] : "";
	unsigned length = strlen(password);
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword(NULL,
											strlen(keychainServiceName), keychainServiceName,
											strlen(keychainAccountName), keychainAccountName,
											NULL, NULL, &itemRef);
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword(NULL,
											   strlen(keychainServiceName), keychainServiceName,
											   strlen(keychainAccountName), keychainAccountName,
											   length, password, NULL);
		if (status)
			NSLog(@"Failed to add password to keychain.");
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
			{ kSecAccountItemAttr, strlen(keychainAccountName), (char *)keychainAccountName },
			{ kSecServiceItemAttr, strlen(keychainServiceName), (char *)keychainServiceName }
		};
		const SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
		status = SecKeychainItemModifyAttributesAndData(itemRef,		// the item reference
														&attributes,	// no change to attributes
														length,			// length of password
														password		// pointer to password data
														);
		if (itemRef)
			CFRelease(itemRef);
		if (status)
			NSLog(@"Failed to change password in keychain.");
	}
}

- (int) UDPPort {
	return [[GrowlPreferencesController sharedController] integerForKey:GrowlUDPPortKey];
}
- (void) setUDPPort:(int)value {
	[[GrowlPreferencesController sharedController] setInteger:value forKey:GrowlUDPPortKey];
}

- (BOOL) isForwardingEnabled {
	return [[GrowlPreferencesController sharedController] boolForKey:GrowlEnableForwardKey];
}
- (void) setForwardingEnabled:(BOOL)enabled {
	[[GrowlPreferencesController sharedController] setBool:enabled forKey:GrowlEnableForwardKey];
}

#pragma mark -
/*
 * @brief Growl preferences changed
 *
 * Synchronize our NSUserDefaults to immediately get any changes from the disk
 */
- (void) growlPreferencesChanged:(NSNotification *)notification {
#pragma unused(notification)
	[self synchronize];	
}

@end
