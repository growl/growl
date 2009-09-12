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
//  GrowlMailPreferences.m
//  GrowlMail
//
//  Created by Ingmar Stein on 30.10.04.
//

#import "GrowlMailPreferences.h"
#import "GrowlMailPreferencesModule.h"
#import "GrowlMail.h"
#import "GrowlMailNotifier.h"

#import <objc/objc-runtime.h>

static void GMExchangeMethodImplementations(Method a, Method b);

@interface NSPreferences (GMSwizzleSticks)

+ (id) sharedPreferencesForGrowlMail;
+ (id) sharedPreferencesFromAppKitSwizzledByGrowlMail;

@end

@implementation GrowlMailPreferences

//As of Mac OS X 10.5.6, Mail creates the +sharedPreferences object lazily, so the simplest way to install our prefpane is to swizzle the +sharedPreferences method.
//We used to install our prefpane by posing as NSPreferences, but class-posing doesn't exist in 64-bit, and seemed to cause at least one crash on PowerPC machines in GrowlMail 1.1.5b1.
+ (void) load {
	Class NSPreferencesClass = NSClassFromString(@"NSPreferences");
	if (!NSPreferencesClass)
		GMShutDownGrowlMailAndWarn(@"Couldn't install GrowlMail prefpane: NSPreferences class missing");
	else {
		//+[NSPreferences sharedPreferences]
		Method sharedPreferencesFromAppKit = class_getClassMethod(NSPreferencesClass, @selector(sharedPreferences));
		if (!sharedPreferencesFromAppKit)
			GMShutDownGrowlMailAndWarn(@"Couldn't install GrowlMail prefpane: +[NSPreferences sharedPreferences] method missing");
		else {
			//+[GrowlMailPreferences sharedPreferencesFromAppKitSwizzledByGrowlMail]
			Method sharedPreferencesFromAppKitFromGrowlMail = class_getClassMethod(self, @selector(sharedPreferencesFromAppKitSwizzledByGrowlMail));
			//+[GrowlMailPreferences sharedPreferencesForGrowlMail]
			Method sharedPreferencesForGrowlMail = class_getClassMethod(self, @selector(sharedPreferencesForGrowlMail));

			//Follow the lady!
			GMExchangeMethodImplementations(sharedPreferencesFromAppKit, sharedPreferencesFromAppKitFromGrowlMail);
			GMExchangeMethodImplementations(sharedPreferencesFromAppKit, sharedPreferencesForGrowlMail);
			/*Results of the swizzling:
			 *
			 *+[NSPreferences sharedPreferences]
			 *	implemented by former +[NSPreferences sharedPreferencesForGrowlMail]
			 *
			 *+[NSPreferences sharedPreferencesForGrowlMail]
			 *	implemented by former +[NSPreferences sharedPreferencesFromAppKitSwizzledByGrowlMail] (the stub)
			 *
			 *+[NSPreferences sharedPreferencesFromAppKitSwizzledByGrowlMail]
			 *	implemented by former +[NSPreferences sharedPreferences]
			 */
		}
	}
}

@end

@implementation NSPreferences (GMSwizzleSticks)

+ (id) sharedPreferencesForGrowlMail {
	static BOOL	added = NO;
	id preferences = [self sharedPreferencesFromAppKitSwizzledByGrowlMail];

	if (preferences && !added) {
		added = YES;
		[preferences addPreferenceNamed:[GrowlMail preferencesPanelName] owner:[GrowlMailPreferencesModule sharedInstance]];
	}

	return preferences;
}
+ (id) sharedPreferencesFromAppKitSwizzledByGrowlMail {
	//Stub implementation to swizzle out.
	return nil;
}

@end

static void GMExchangeMethodImplementations(Method a, Method b)
{
	method_exchangeImplementations(a, b);
}
