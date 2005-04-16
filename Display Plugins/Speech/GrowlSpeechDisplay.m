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
#import <GrowlDefinesInternal.h>
#import "GrowlController.h"

@implementation GrowlSpeechDisplay
- (void) dealloc {
	[prefPane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!prefPane) {
		prefPane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlSpeechPrefs class]]];
	}
	return prefPane;
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	NSString *voice = nil;
	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);
	if (voice) {
		[voice autorelease];
	} else {
		voice = [NSSpeechSynthesizer defaultVoice];
	}

	NSString *desc = [noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION];

	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
	[syn startSpeakingString:desc];

	if ([[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]) {
		GrowlController *growlController = [GrowlController standardController];
		NSString *path = [[[growlController screenshotsDirectory] stringByAppendingPathComponent:[growlController nextScreenshotName]] stringByAppendingPathExtension:@"aiff"];
		NSURL *URL = [NSURL fileURLWithPath:path];
		[syn startSpeakingString:desc toURL:URL];
	}

	[syn autorelease];
}
@end
