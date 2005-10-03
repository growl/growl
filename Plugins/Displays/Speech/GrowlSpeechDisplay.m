//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefinesInternal.h"
#import "GrowlApplicationNotification.h"
#include "CFDictionaryAdditions.h"

@implementation GrowlSpeechDisplay
- (void) dealloc {
	[prefPane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!prefPane)
		prefPane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.growl.Speech"]];
	return prefPane;
}

- (void) displayNotification:(GrowlApplicationNotification *)notification {
	NSString *voice = nil;
	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);
	if (voice)
		[voice autorelease];
	else
		voice = [NSSpeechSynthesizer defaultVoice];

	NSString *desc = [notification description];

	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
	[syn startSpeakingString:desc];

	NSDictionary *noteDict = [notification dictionaryRepresentation];
	if (getBooleanForKey(noteDict, GROWL_SCREENSHOT_MODE)) {
		NSString *path = [[[GrowlPathUtilities screenshotsDirectory] stringByAppendingPathComponent:[GrowlPathUtilities nextScreenshotName]] stringByAppendingPathExtension:@"aiff"];
		NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
		[syn startSpeakingString:desc toURL:url];
		[url release];
	}

	[syn autorelease];

	id clickContext = getObjectForKey(noteDict, GROWL_NOTIFICATION_CLICK_CONTEXT);
	if (clickContext) {
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			getObjectForKey(noteDict, @"ClickHandlerEnabled"), @"ClickHandlerEnabled",
			clickContext,                                      GROWL_KEY_CLICKED_CONTEXT,
			getObjectForKey(noteDict, GROWL_APP_PID),          GROWL_APP_PID,
			nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_TIMED_OUT
															object:[notification applicationName]
														  userInfo:userInfo];
		[userInfo release];
	}
}
@end
