//
//  GrowlMail.m
//  GrowlMail
//
//  Created by Adam Iser on Mon Jul 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMail.h"
#import <GrowlAppBridge/GrowlApplicationBridge.h>
#import "GrowlDefines.h"

@implementation GrowlMail

+ (NSString *)bundleVersion
{
	return( [[[NSBundle bundleForClass:self] infoDictionary] objectForKey:@"CFBundleVersion"] );
}

+ (void)initialize
{
	[super initialize];
	[self registerBundle];

	NSNumber *enabled = [[NSNumber alloc] initWithBool:YES];
	NSDictionary *defaultsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
		enabled, @"GMEnableGrowlMailBundle",
		enabled, @"GMIgnoreJunk",
		nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
	[defaultsDictionary release];
	[enabled release];

	NSLog( @"Loaded GrowlMail %@", [self bundleVersion] );
}

+ (BOOL)hasPreferencesPanel
{
	return( YES );
}

+ (NSString *)preferencesOwnerClassName
{
	return( @"GrowlMailPreferencesModule" );
}

+ (NSString *)preferencesPanelName
{
	return( @"GrowlMail" );
}

- (id)init
{
	if( self = [super init] ) {
		if( ![GrowlAppBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(gabResponse:) context:nil] ) {
			NSLog( @"Growl not installed, GrowlMail disabled" );
		}
	}

	return( self );
}

- (void)gabResponse:(id)context
{
	// Register our ticket with Growl
	NSArray *allowedNotifications = [NSArray arrayWithObject:@"New mail"];
	NSDictionary *ticket = [NSDictionary dictionaryWithObjectsAndKeys:
		@"GrowlMail", GROWL_APP_NAME,
		allowedNotifications, GROWL_NOTIFICATIONS_ALL,
		allowedNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION
																   object:nil
																 userInfo:ticket];
}

// preferences

- (BOOL)isEnabled
{
	return( [[NSUserDefaults standardUserDefaults] boolForKey:@"GMEnableGrowlMailBundle"] );
}

- (void)setEnabled:(BOOL)yesOrNo
{
	[[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:@"GMEnableGrowlMailBundle"];
}

- (BOOL)isIgnoreJunk
{
	return( [[NSUserDefaults standardUserDefaults] boolForKey:@"GMIgnoreJunk"] );
}

- (void)setIgnoreJunk:(BOOL)yesOrNo
{
	[[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:@"GMIgnoreJunk"];
}

@end
