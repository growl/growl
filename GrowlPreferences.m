//
//  GrowlPreferences.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlPreferences.h"

NSString * HelperAppBundleIdentifier	= @"com.Growl.GrowlHelperApp";
NSString * GrowlPreferencesChanged		= @"GrowlPreferencesChanged";
NSString * GrowlDisplayPluginKey		= @"GrowlDisplayPluginName";


static GrowlPreferences * sharedPreferences;

@implementation GrowlPreferences

+ (GrowlPreferences *) preferences {
	if(!sharedPreferences)
		sharedPreferences = [[GrowlPreferences alloc] init];
	return sharedPreferences;
}

- (id) init {
	
	helperAppDefaults = [[NSUserDefaults alloc] init];
	[helperAppDefaults addSuiteNamed:HelperAppBundleIdentifier];
	
	return self;
}

#pragma mark -

- (void) registerDefaults:(NSDictionary *)inDefaults {
	NSMutableDictionary * domain = [[helperAppDefaults persistentDomainForName:HelperAppBundleIdentifier] mutableCopy];
	if(!domain) domain = [[NSMutableDictionary alloc] init];

	NSEnumerator		* e = [inDefaults keyEnumerator];
	NSString			* key;
	
	while ( key = [e nextObject] ) {
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

- (NSBundle *) helperAppBundle {
	if ( !helperAppBundle ) {
		if ( [[[NSBundle mainBundle] bundleIdentifier] isEqualToString:HelperAppBundleIdentifier] ) {
			//We are running in the GAH bundle
			helperAppBundle = [NSBundle mainBundle];
		} else {
			//We are running in the prefpane
			NSString * helperPath = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"GrowlHelperApp.app"];
			helperAppBundle = [NSBundle bundleWithPath:helperPath];
		}
	}
	return helperAppBundle;
}

- (void) dealloc {
	[helperAppDefaults release];
	
	[super dealloc];
}

@end
