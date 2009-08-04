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
//  Copyright (c) 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlMail.h"

#import "GrowlMailNotifier.h"

@implementation GMMVMailBundle
+(void)initialize
{
	Class mvMailBundleClass = NSClassFromString(@"MVMailBundle");
	if(mvMailBundleClass)
		class_setSuperclass([self class], mvMailBundleClass);
}

@end

NSBundle *GMGetGrowlMailBundle(void) {
	return [NSBundle bundleForClass:[GrowlMail class]];
}

@implementation GrowlMail

#pragma mark Boring bookkeeping stuff

+ (void) initialize {
	[super initialize];

	NSLog(@"Class: %@", NSStringFromClass(NSClassFromString(@"Message")));
	// this image is leaked
	NSImage *image = [[NSImage alloc] initByReferencingFile:[GMGetGrowlMailBundle() pathForImageResource:@"GrowlMail"]];
	[image setName:@"GrowlMail"];

	[GrowlMail registerBundle];

	NSLog(@"Loaded GrowlMail %@", [GMGetGrowlMailBundle() objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]);
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
		NSString *privateFrameworksPath = [GMGetGrowlMailBundle() privateFrameworksPath];
		NSString *growlBundlePath = [privateFrameworksPath stringByAppendingPathComponent:@"Growl.framework"];

		NSBundle *growlBundle = [NSBundle bundleWithPath:growlBundlePath];
		if (growlBundle) {
			if ([growlBundle load]) {
				if ([GrowlApplicationBridge respondsToSelector:@selector(frameworkInfoDictionary)]) {
					//Create or obtain our singleton notifier instance.
					notifier = [[GrowlMailNotifier alloc] init];
					if (!notifier)
						NSLog(@"Could not initialize GrowlMail notifier object");

					NSDictionary *infoDictionary = [GrowlApplicationBridge frameworkInfoDictionary];
					NSLog(@"Using Growl.framework %@ (%@)",
						  [infoDictionary objectForKey:@"CFBundleShortVersionString"],
						  [infoDictionary objectForKey:(NSString *)kCFBundleVersionKey]);
				} else {
					NSLog(@"Using a version of Growl.framework older than 1.1. One of the other installed Mail plugins should be updated to Growl.framework 1.1 or later.");
				}
			}
		} else {
			NSLog(@"Could not load Growl.framework, GrowlMail disabled");
		}
	}

	return self;
}

- (void) dealloc {
	[notifier release];

	[super dealloc];
}

@end
