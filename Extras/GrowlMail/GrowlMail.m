/*
 Copyright (c) The Growl Project, 2004-2005
 All rights reserved.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 OF THE POSSIBILITY OF SUCH DAMAGE.
*/
//
//  GrowlMail.m
//  GrowlMail
//
//  Created by Adam Iser on Mon Jul 26 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMail.h"
#import <Growl/Growl.h>

static Class growlApplicationBridge;

@implementation GrowlMail

+ (NSBundle *) bundle {
	return [NSBundle bundleForClass:[GrowlMail class]];
}

+ (NSString *) bundleVersion {
	return [[[GrowlMail bundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

+ (void) initialize {
	[super initialize];

	// this image is leaked
	NSImage *image = [[NSImage alloc] initByReferencingFile:[[GrowlMail bundle] pathForImageResource:@"GrowlMail"]];
	[image setName:@"GrowlMail"];

	[GrowlMail registerBundle];

	NSNumber *enabled = [[NSNumber alloc] initWithBool:YES];
	NSNumber *automatic = [[NSNumber alloc] initWithInt:0];
	NSDictionary *defaultsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
		enabled,   @"GMEnableGrowlMailBundle",
		enabled,   @"GMIgnoreJunk",
		automatic, @"GMSummaryMode",
		nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
	[defaultsDictionary release];
	[automatic release];
	[enabled release];

	NSLog( @"Loaded GrowlMail %@", [GrowlMail bundleVersion] );
}

+ (Class) growlApplicationBridge {
	return growlApplicationBridge;
}

+ (BOOL) hasPreferencesPanel {
	return YES;
}

+ (NSString *) preferencesOwnerClassName {
	return @"GrowlMailPreferencesModule";
}

+ (NSString *) preferencesPanelName {
	return @"GrowlMail";
}

- (id) init {
	if ((self = [super init])) {
		NSString *growlPath = [[[GrowlMail bundle] privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
		NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
		growlApplicationBridge = [growlBundle classNamed:@"GrowlApplicationBridge"];

		if ([growlApplicationBridge isGrowlInstalled]) {
			// Register ourselves as a Growl delegate
			[growlApplicationBridge setGrowlDelegate:self];
		} else {
			NSLog( @"Growl not installed, GrowlMail disabled" );
		}
	}

	return self;
}

#pragma mark GrowlApplicationBridge delegate methods

- (NSString *) applicationNameForGrowl {
	return @"GrowlMail";
}

- (NSData *) applicationIconDataForGrowl {
	return [[NSImage imageNamed:@"NSApplicationIcon"] TIFFRepresentation];
}

- (void) growlNotificationWasClicked:(id)clickContext {
#pragma unused(clickContext)
	// TODO: open a specific message if not in summary mode
	[NSApp activateIgnoringOtherApps:YES];
}

- (NSDictionary *) registrationDictionaryForGrowl {
	// Register our ticket with Growl
	NSArray *allowedNotifications = [[NSArray alloc] initWithObjects:NSLocalizedStringFromTableInBundle(@"New mail", nil, [GrowlMail bundle], @""), nil];
	NSDictionary *ticket = [NSDictionary dictionaryWithObjectsAndKeys:
		allowedNotifications, GROWL_NOTIFICATIONS_ALL,
		allowedNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	[allowedNotifications release];

	return ticket;
}

#pragma mark Preferences

+ (BOOL) isEnabled {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GMEnableGrowlMailBundle"];
}

+ (BOOL)isIgnoreJunk {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GMIgnoreJunk"];
}

- (BOOL) isAccountEnabled:(NSString *)path {
	NSDictionary *accountSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"GMAccounts"];
	NSNumber *isEnabled = [accountSettings objectForKey:path];
	return isEnabled ? [isEnabled boolValue] : YES;
}

- (void) setAccountEnabled:(BOOL)yesOrNo path:(NSString *)path {
	NSDictionary *accountSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"GMAccounts"];
	NSMutableDictionary *newSettings;
	if (accountSettings) {
		newSettings = [accountSettings mutableCopy];
	} else {
		newSettings = [[NSMutableDictionary alloc] initWithCapacity:1U];
	}
	NSNumber *value = [[NSNumber alloc] initWithBool:yesOrNo];
	[newSettings setObject:value forKey:path];
	[value release];
	[[NSUserDefaults standardUserDefaults] setObject:newSettings forKey:@"GMAccounts"];
	[newSettings release];
}

+ (int) summaryMode {
	return [[NSUserDefaults standardUserDefaults] integerForKey:@"GMSummaryMode"];
}

@end
