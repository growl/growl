//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import <GrowlDefinesInternal.h>

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
	NSString *voice = [NSSpeechSynthesizer defaultVoice];

	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);

	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
	[syn startSpeakingString:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]];
	[syn autorelease];
}
@end
