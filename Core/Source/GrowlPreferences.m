//
//  GrowlPreferences.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlPreferences.h"

NSString * HelperAppBundleIdentifier	= @"com.Growl.GrowlHelperApp";
NSString * GrowlPreferencesChanged		= @"GrowlPreferencesChanged";
NSString * GrowlDisplayPluginKey		= @"GrowlDisplayPluginName";
NSString * GrowlUserDefaultsKey			= @"GrowlUserDefaults";
NSString * GrowlStartServerKey			= @"GrowlStartServer";
NSString * GrowlRemoteRegistrationKey	= @"GrowlRemoteRegistration";
NSString * GrowlEnableForwardKey		= @"GrowlEnableForward";
NSString * GrowlForwardDestinationsKey	= @"GrowlForwardDestinations";

static GrowlPreferences * sharedPreferences;

@implementation GrowlPreferences

+ (GrowlPreferences *) preferences {
	if (!sharedPreferences) {
		sharedPreferences = [[GrowlPreferences alloc] init];
	}
	return sharedPreferences;
}

- (id) init {
	if((self = [super init])) {
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
	
	while ( (key = [e nextObject]) ) {
		if ( ![domain objectForKey:key] ) {
			[domain setObject:[inDefaults objectForKey:key] forKey:key];
		}
	}
	
	[helperAppDefaults setPersistentDomain:domain forName:HelperAppBundleIdentifier];
	
	[domain release];
}

- (id) objectForKey:(NSString *)key {
	[helperAppDefaults synchronize];
	id obj = [helperAppDefaults objectForKey:key];
	return obj;
}

- (void) setObject:(id)object forKey:(NSString *) key {
	CFPreferencesSetAppValue( (CFStringRef)key			/* key */,
							  (CFPropertyListRef)object /* value */,
							  (CFStringRef)HelperAppBundleIdentifier) /* application ID */;\
								  
	CFPreferencesAppSynchronize( (CFStringRef)HelperAppBundleIdentifier );
							  
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GrowlPreferencesChanged object:key];
}

- (void) synchronize {
	[helperAppDefaults synchronize];
	SYNCHRONIZE_GROWL_PREFS();
}

- (NSBundle *) helperAppBundle {
	if ( !helperAppBundle ) {
		if ( [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:HelperAppBundleIdentifier] ) {
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
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSUserDomainMask, /* expandTilde */ YES );
	
	supportDir = [searchPath objectAtIndex:0U];
	supportDir = [supportDir stringByAppendingPathComponent:@"Application Support"];
	supportDir = [supportDir stringByAppendingPathComponent:@"Growl"];
	
	return supportDir;
}

#pragma mark -

- (BOOL) startGrowlAtLogin {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSArray *autoLaunchArray = [[defs persistentDomainForName:@"loginwindow"] objectForKey:@"AutoLaunchedApplicationDictionary"];
	NSString *appPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
	BOOL foundIt = NO;

	NSEnumerator *e = [autoLaunchArray objectEnumerator];
	NSDictionary *item;
	while ( (item = [e nextObject] ) ) {
		if ([[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString:appPath]) {
			foundIt = YES;
			break;
		}
	}

	return foundIt;
}

- (void) setStartGrowlAtLogin:(BOOL)flag {
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *appPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
	NSMutableDictionary *loginWindowPrefs = [[[defs persistentDomainForName:@"loginwindow"] mutableCopy] autorelease];
	NSArray *loginItems = [loginWindowPrefs objectForKey:@"AutoLaunchedApplicationDictionary"];
	NSMutableArray *mutableLoginItems = [[loginItems mutableCopy] autorelease];
	NSEnumerator *e = [loginItems objectEnumerator];
	NSDictionary *item;
	while ( (item = [e nextObject] ) ) {
		if ([[[item objectForKey:@"Path"] stringByExpandingTildeInPath] isEqualToString:appPath]) {
			[mutableLoginItems removeObject:item];
		}
	}
	
	if ( flag ) {
		NSMutableDictionary *launchDict = [NSMutableDictionary dictionary];
		[launchDict setObject:[NSNumber numberWithBool:NO] forKey:@"Hide"];
		[launchDict setObject:appPath forKey:@"Path"];
		[mutableLoginItems addObject:launchDict];
	}
	
	[loginWindowPrefs setObject:[NSArray arrayWithArray:mutableLoginItems] 
						 forKey:@"AutoLaunchedApplicationDictionary"];
	[defs setPersistentDomain:[NSDictionary dictionaryWithDictionary:loginWindowPrefs] 
					  forName:@"loginwindow"];
	[defs synchronize];
}

@end
