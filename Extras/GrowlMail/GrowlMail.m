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

+ (NSBundle *)bundle {
	return [NSBundle bundleForClass:self];
}

+ (NSString *)bundleVersion {
	return [[[GrowlMail bundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

+ (void)initialize {
	NSBundle *myBundle;

	[super initialize];

	myBundle = [self bundle];
	[(NSImage *)[[NSImage alloc] initByReferencingFile:[myBundle pathForImageResource:@"GrowlMail"]] setName:@"GrowlMail"];

	[self registerBundle];

	NSNumber *enabled = [[NSNumber alloc] initWithBool:YES];
	NSNumber *disabled = [[NSNumber alloc] initWithBool:NO];
	NSDictionary *defaultsDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
		enabled, @"GMEnableGrowlMailBundle",
		enabled, @"GMIgnoreJunk",
		disabled, @"GMShowSummary",
		nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDictionary];
	[defaultsDictionary release];
	[disabled release];
	[enabled release];

	NSLog( @"Loaded GrowlMail %@", [GrowlMail bundleVersion] );
}

+ (Class)growlApplicationBridge {
	return growlApplicationBridge;
}

+ (BOOL)hasPreferencesPanel {
	return YES;
}

+ (NSString *)preferencesOwnerClassName {
	return @"GrowlMailPreferencesModule";
}

+ (NSString *)preferencesPanelName {
	return @"GrowlMail";
}

- (id)init {
	if ( (self = [super init]) ) {
		NSString *growlPath = [[[GrowlMail bundle] privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
		NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
		growlApplicationBridge = [growlBundle classNamed:@"GrowlApplicationBridge"];

		if ( [growlApplicationBridge isGrowlInstalled] ) {
			// Register ourselves as a Growl delegate
			[growlApplicationBridge setGrowlDelegate:self];
		} else {
			NSLog( @"Growl not installed, GrowlMail disabled" );
		}
	}

	return self;
}

- (NSString *) applicationNameForGrowl {
	return @"GrowlMail";
}

- (NSData *) applicationIconDataForGrowl {
	return [[NSImage imageNamed:@"NSApplicationIcon"] TIFFRepresentation];
}

- (void) growlNotificationWasClicked:(id)clickContext {
	// TODO: open a specific message if not in summary mode
	[NSApp activateIgnoringOtherApps:YES];
}

- (NSDictionary *) registrationDictionaryForGrowl {
	// Register our ticket with Growl
	NSArray *allowedNotifications = [NSArray arrayWithObject:NSLocalizedStringFromTableInBundle(@"New mail", nil, [GrowlMail bundle], @"")];
	NSDictionary *ticket = [NSDictionary dictionaryWithObjectsAndKeys:
		allowedNotifications, GROWL_NOTIFICATIONS_ALL,
		allowedNotifications, GROWL_NOTIFICATIONS_DEFAULT,
		nil];

	return ticket;
}

// preferences

- (BOOL)isEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GMEnableGrowlMailBundle"];
}

- (void)setEnabled:(BOOL)yesOrNo
{
	[[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:@"GMEnableGrowlMailBundle"];
}

- (BOOL)isIgnoreJunk {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GMIgnoreJunk"];
}

- (void)setIgnoreJunk:(BOOL)yesOrNo {
	[[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:@"GMIgnoreJunk"];
}

- (BOOL)isAccountEnabled:(NSString *)path {
	NSDictionary *accountSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"GMAccounts"];
	NSNumber *isEnabled = (NSNumber *)[accountSettings objectForKey:path];
	return isEnabled ? [isEnabled boolValue] : YES;
}

- (void)setAccountEnabled:(BOOL)yesOrNo path:(NSString *)path {
	NSDictionary *accountSettings = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"GMAccounts"];
	NSMutableDictionary *newSettings;
	if ( accountSettings ) {
		newSettings = [accountSettings mutableCopy];
	} else {
		newSettings = [[NSMutableDictionary alloc] initWithCapacity:1];
	}
	[newSettings setObject: [NSNumber numberWithBool:yesOrNo] forKey:path];
	[[NSUserDefaults standardUserDefaults] setObject:newSettings forKey:@"GMAccounts"];
	[newSettings release];
}

- (BOOL)showSummary {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"GMShowSummary"];
}

- (void)setShowSummary:(BOOL)yesOrNo {
	[[NSUserDefaults standardUserDefaults] setBool:yesOrNo forKey:@"GMShowSummary"];
}

@end
