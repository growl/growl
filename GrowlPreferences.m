//
//  GrowlPreferences.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlPreferences.h"

NSString * GrowlPreferencesChanged		= @"GrowlPreferencesChanged";
NSString * GrowlDisplayPluginKey		= @"GrowlDisplayPluginName";
NSString * GrowlUserDefaultsKey			= @"GrowlUserDefaults";


static GrowlPreferences * sharedPreferences;

@implementation GrowlPreferences

+ (GrowlPreferences *) preferences {
	if ( ! sharedPreferences )
		sharedPreferences = [[self alloc] init];
	
	return sharedPreferences;
}

- (id) init {
	if ( self = [super init] ) {
		_realPrefs = [[NSUserDefaults standardUserDefaults] retain];
	}
	
	return self;
}

- (void) dealloc {
	[_realPrefs release];
	
	_realPrefs = nil;
	
	[super dealloc];
}

#pragma mark -

- (void) registerDefaults:(NSDictionary *)inDict {
	[_realPrefs registerDefaults:inDict];
}

- (id) objectForKey:(NSString *)inKey {
	[_realPrefs objectForKey:inKey];
}

- (void) setObject:(id)inObject forKey:(NSString *)inKey {
	[_realPrefs setObject:inObject forKey:inKey];
}

- (BOOL) synchronize {
	return [_realPrefs synchronize];
}

#pragma mark -

- (NSString *) growlSupportDir {
	NSString *supportDir;
	NSArray *searchPath = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, 
															   NSUserDomainMask, 
															   YES /* expandTilde */ );
	
	supportDir = [searchPath objectAtIndex:0];
	supportDir = [supportDir stringByAppendingPathComponent:@"Application Support"];
	supportDir = [supportDir stringByAppendingPathComponent:@"Growl"];
	
	return supportDir;
}

@end
