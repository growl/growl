//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import <GrowlDefines.h>

static NSString *author = @"Ingmar Stein";
static NSString *name = @"Speech";
static NSString *version = @"0.6";
static NSString *description = @"Speak notifications.";

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

- (NSString *)author
{
	return author;
}

- (NSString *)name
{
	return name;
}

- (NSString *)userDescription
{
	return description;
}

- (NSString *)version
{
	return version;
}

- (NSDictionary *)pluginInfo
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		name,        @"Name",
		author,      @"Author",
		version,     @"Version",
		description, @"Description",
		nil];
}

- (NSPreferencePane *) preferencePane
{
	return prefPane;
}

- (void) loadPlugin
{
}

- (void) unloadPlugin
{
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict
{
	NSString *voice;

	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);

	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
	[syn startSpeakingString:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]];
	[syn autorelease];
}
@end
