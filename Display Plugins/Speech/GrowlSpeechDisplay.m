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
- (id) init {
	if ((self = [super init])) {
		bundle = [[NSBundle bundleForClass:[GrowlSpeechPrefs class]] retain];
		prefPane = [[GrowlSpeechPrefs alloc] initWithBundle:bundle];
	}
	return self;
}

- (void) dealloc {
	[prefPane release];
	[bundle   release];
	[super dealloc];
}

- (NSDictionary *) pluginInfo {
	return [bundle infoDictionary];
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
