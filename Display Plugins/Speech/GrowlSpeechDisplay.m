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

#define SPEECH_AUTHOR      @"Ingmar Stein"
#define SPEECH_NAME        @"Speech"
#define SPEECH_VERSION     @"0.6"
#define SPEECH_DESCRIPTION @"Speak notifications."

@implementation GrowlSpeechDisplay
- (id) init {
	if ( (self = [super init] ) ) {
		prefPane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlSpeechPrefs class]]];
	}
	return self;
}

- (void) dealloc {
	[prefPane release];
	[super dealloc];
}

- (NSString *) author {
	return SPEECH_AUTHOR;
}

- (NSString *) name {
	return SPEECH_NAME;
}

- (NSString *) userDescription {
	return SPEECH_DESCRIPTION;
}

- (NSString *) version {
	return SPEECH_VERSION;
}

- (NSDictionary *) pluginInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		SPEECH_NAME,		@"Name",
		SPEECH_AUTHOR,		@"Author",
		SPEECH_VERSION,		@"Version",
		SPEECH_DESCRIPTION,	@"Description",
		nil];
}

- (NSPreferencePane *) preferencePane {
	return prefPane;
}

- (void) loadPlugin {
}

- (void) unloadPlugin {
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	NSString *voice = [NSSpeechSynthesizer defaultVoice];

	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);

	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
	[syn startSpeakingString:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]];
	[syn autorelease];
}
@end
