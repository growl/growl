//
//  GrowlPreferencesController.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Renamed from GrowlPreferences.m by Mac-arena the Bored Zo on 2005-06-27.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlPreferencesController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlPathUtilities.h"
#import "NSStringAdditions.h"
#include "CFURLAdditions.h"
#include "CFDictionaryAdditions.h"
#include "LoginItemsAE.h"
#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>

#define keychainServiceName "Growl"
#define keychainAccountName "Growl"

CFTypeRef GrowlPreferencesController_objectForKey(CFTypeRef key) {
	return [[GrowlPreferencesController sharedController] objectForKey:(id)key];
}

int GrowlPreferencesController_integerForKey(CFTypeRef key) {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppIntegerValue((CFStringRef)key, (CFStringRef)HelperAppBundleIdentifier, &keyExistsAndHasValidFormat);
}

Boolean GrowlPreferencesController_boolForKey(CFTypeRef key) {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppBooleanValue((CFStringRef)key, (CFStringRef)HelperAppBundleIdentifier, &keyExistsAndHasValidFormat);
}

@implementation GrowlPreferencesController

+ (GrowlPreferencesController *) sharedController {
	return [self sharedInstance];
}

- (id) initSingleton {
	if ((self = [super initSingleton])) {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(growlPreferencesChanged:)
																name:GrowlPreferencesChanged
															  object:nil];
	}
	return self;
}

- (void) destroy {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];

	[super destroy];
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

	int pid = getpid();
	CFNumberRef pidValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pid);
	CFStringRef pidKey = CFSTR("pid");
	CFDictionaryRef userInfo = CFDictionaryCreate(kCFAllocatorDefault, (const void **)&pidKey, (const void **)&pidValue, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(pidValue);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)GrowlPreferencesChanged,
										 /*object*/ key,
										 /*userInfo*/ userInfo,
										 /*deliverImmediately*/ false);
	CFRelease(userInfo);
}

- (BOOL) boolForKey:(NSString *)key {
	return GrowlPreferencesController_boolForKey((CFTypeRef)key);
}

- (void) setBool:(BOOL)value forKey:(NSString *)key {
	NSNumber *object = [[NSNumber alloc] initWithBool:value];
	[self setObject:object forKey:key];
	[object release];
}

- (int) integerForKey:(NSString *)key {
	return GrowlPreferencesController_integerForKey((CFTypeRef)key);
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
	OSStatus   status;
	Boolean    foundIt = false;
	CFArrayRef loginItems = NULL;

	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA      = [[NSBundle bundleWithIdentifier:GROWL_PREFPANE_BUNDLE_IDENTIFIER] pathForResource:@"GrowlHelperApp" ofType:@"app"];
	//get the file url to GHA.
	CFURLRef urlToGHA = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)pathToGHA, kCFURLPOSIXPathStyle, true);

	status = LIAECopyLoginItems(&loginItems);
	if (status == noErr) {
    CFIndex i, count;
		for (i=0, count=CFArrayGetCount(loginItems); i<count; ++i) {
			CFDictionaryRef loginItem = CFArrayGetValueAtIndex(loginItems, i);
			foundIt = CFEqual(CFDictionaryGetValue(loginItem, kLIAEURL), urlToGHA);
			if (foundIt)
				break;
		}
		CFRelease(loginItems);
	}

	CFRelease(urlToGHA);

	return foundIt;
}

- (void) setShouldStartGrowlAtLogin:(BOOL)flag {
	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA = [[NSBundle bundleWithIdentifier:GROWL_PREFPANE_BUNDLE_IDENTIFIER] pathForResource:@"GrowlHelperApp" ofType:@"app"];
	[self setStartAtLogin:pathToGHA enabled:flag];
}

- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled {
	OSStatus status;
	CFArrayRef loginItems = NULL;
	NSURL *url = [NSURL fileURLWithPath:path];
	int existingLoginItemIndex = -1;

	status = LIAECopyLoginItems(&loginItems);

	if (status == noErr) {
		NSEnumerator *enumerator = [(NSArray *)loginItems objectEnumerator];
		NSDictionary *loginItemDict;

		while ((loginItemDict = [enumerator nextObject])) {
			if ([[loginItemDict objectForKey:(NSString *)kLIAEURL] isEqual:url]) {
				existingLoginItemIndex = [(NSArray *)loginItems indexOfObjectIdenticalTo:loginItemDict];
				break;
			}
		}
	}

	if (enabled && (existingLoginItemIndex == -1))
		LIAEAddURLAtEnd((CFURLRef)url, false);
	else if (!enabled && (existingLoginItemIndex != -1))
		LIAERemove(existingLoginItemIndex);

	if(loginItems)
		CFRelease(loginItems);
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
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 CFSTR("GrowlMenuShutdown"),
										 /*object*/ NULL,
										 /*userInfo*/ NULL,
										 /*deliverImmediately*/ false);
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
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)GROWL_SHUTDOWN,
										 /*object*/ NULL,
										 /*userInfo*/ NULL,
										 /*deliverImmediately*/ false);
}

#pragma mark -
//Simplified accessors

#pragma mark UI

- (int)selectedPosition {
	return [self integerForKey:GROWL_POSITION_PREFERENCE_KEY];
}

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

- (NSNumber*) idleThreshold {
	return [NSNumber numberWithInt:[self integerForKey:GrowlStickyIdleThresholdKey]];
}

- (void) setIdleThreshold:(NSNumber*)value {
	[self setInteger:[value intValue] forKey:GrowlStickyIdleThresholdKey];
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
	return [self boolForKey:GrowlLoggingEnabledKey];
}

- (void) setLoggingEnabled:(BOOL)flag {
	[self setBool:flag forKey:GrowlLoggingEnabledKey];
}

- (BOOL) isGrowlServerEnabled {
	return [self boolForKey:GrowlStartServerKey];
}

- (void) setGrowlServerEnabled:(BOOL)enabled {
	[self setBool:enabled forKey:GrowlStartServerKey];
}

#pragma mark Remote Growling

- (BOOL) isRemoteRegistrationAllowed {
	return [self boolForKey:GrowlRemoteRegistrationKey];
}

- (void) setRemoteRegistrationAllowed:(BOOL)flag {
	[self setBool:flag forKey:GrowlRemoteRegistrationKey];
}

- (NSString *) remotePassword {
	unsigned char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword(NULL,
											strlen(keychainServiceName), keychainServiceName,
											strlen(keychainAccountName), keychainAccountName,
											&passwordLength, (void **)&password, NULL);

	NSString *passwordString;
	if (status == noErr) {
		passwordString = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault, password, passwordLength, kCFStringEncodingUTF8, false);
		[passwordString autorelease];
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
	return [self integerForKey:GrowlUDPPortKey];
}
- (void) setUDPPort:(int)value {
	[self setInteger:value forKey:GrowlUDPPortKey];
}

- (BOOL) isForwardingEnabled {
	return [self boolForKey:GrowlEnableForwardKey];
}
- (void) setForwardingEnabled:(BOOL)enabled {
	[self setBool:enabled forKey:GrowlEnableForwardKey];
}

#pragma mark -
/*
 * @brief Growl preferences changed
 *
 * Synchronize our NSUserDefaults to immediately get any changes from the disk
 */
- (void) growlPreferencesChanged:(NSNotification *)notification {
	NSString *object = [notification object];
//	NSLog(@"%s: %@\n", __func__, object);
	SYNCHRONIZE_GROWL_PREFS();
	if (!object || [object isEqualToString:GrowlDisplayPluginKey]) {
		[self willChangeValueForKey:@"defaultDisplayPluginName"];
		[self didChangeValueForKey:@"defaultDisplayPluginName"];
	}
	if (!object || [object isEqualToString:GrowlSquelchModeKey]) {
		[self willChangeValueForKey:@"squelchMode"];
		[self didChangeValueForKey:@"squelchMode"];
	}
	if (!object || [object isEqualToString:GrowlMenuExtraKey]) {
		[self willChangeValueForKey:@"growlMenuEnabled"];
		[self didChangeValueForKey:@"growlMenuEnabled"];
	}
	if (!object || [object isEqualToString:GrowlEnableForwardKey]) {
		[self willChangeValueForKey:@"forwardingEnabled"];
		[self didChangeValueForKey:@"forwardingEnabled"];
	}
	if (!object || [object isEqualToString:GrowlUpdateCheckKey]) {
		[self willChangeValueForKey:@"backgroundUpdateCheckEnabled"];
		[self didChangeValueForKey:@"backgroundUpdateCheckEnabled"];
	}
	if (!object || [object isEqualToString:GrowlStickyWhenAwayKey]) {
		[self willChangeValueForKey:@"stickyWhenAway"];
		[self didChangeValueForKey:@"stickyWhenAway"];
	}
	if (!object || [object isEqualToString:GrowlStickyIdleThresholdKey]) {
		[self willChangeValueForKey:@"idleThreshold"];
		[self didChangeValueForKey:@"idleThreshold"];
	}
	if (!object || [object isEqualToString:GrowlRemoteRegistrationKey]) {
		[self willChangeValueForKey:@"remoteRegistrationAllowed"];
		[self didChangeValueForKey:@"remoteRegistrationAllowed"];
	}
}

@end
