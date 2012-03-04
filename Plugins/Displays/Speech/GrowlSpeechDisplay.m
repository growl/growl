//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotification.h>
#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlSpeechDisplay
@synthesize speech_queue;
@synthesize syn;

- (id) init {
    if((self = [super init])) {
        self.speech_queue = [NSMutableArray array];
        self.syn = [[[NSSpeechSynthesizer alloc] initWithVoice:nil] autorelease];
        syn.delegate = self;
		 self.prefDomain = GrowlSpeechPrefDomain;
    }
    return self;
}

- (void) dealloc {
	[speech_queue release];
	[syn release];
	[preferencePane release];
	[super dealloc];
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.growl.Speech"]];

	return preferencePane;
}

- (void)dispatchNotification:(NSDictionary*)noteDict withConfiguration:(NSDictionary*)configuration {
	NSString *title = [noteDict valueForKey:GROWL_NOTIFICATION_TITLE];
	NSString *desc = [noteDict valueForKey:GROWL_NOTIFICATION_DESCRIPTION];
	
	NSString *summary = [NSString stringWithFormat:@"%@\n\n%@", title, desc];
	NSString *voice = [configuration valueForKey:GrowlSpeechVoicePref];
	NSDictionary *queueDict = [NSDictionary dictionaryWithObjectsAndKeys:summary, @"summary", voice, GrowlSpeechVoicePref, nil];
	
	[speech_queue addObject:queueDict];
	if(![syn isSpeaking])
	{
		[self speakNotification:summary withVoice:voice];
	}
	
	if ([[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]) {
		NSString *path = [[[GrowlPathUtilities screenshotsDirectory] stringByAppendingPathComponent:[GrowlPathUtilities nextScreenshotName]] stringByAppendingPathExtension:@"aiff"];
		NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
		[syn startSpeakingString:summary toURL:url];
		[url release];
	}
}

- (void)speakNotification:(NSString*)notificationToSpeak withVoice:(NSString*)voice
{
	if (voice) {
		//[voice autorelease];
	} else {
		//Leaving the voice set to nil means we get the default voice the speech rate selected in the Speech preferences pane.
	}
	if([voice isEqualToString:GrowlSpeechSystemVoice])
		voice = nil;
	
	syn.voice = voice;
	[syn startSpeakingString:notificationToSpeak];
	
}
#pragma mark -
#pragma mark NSSpeechSynthesizerDelegate
#pragma mark -

- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
	if([sender isEqualTo:syn])
	{
		[speech_queue removeObjectAtIndex:0U];
		if([speech_queue count])
		{
			//insert a slight delay
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0f]];
			NSDictionary *speechDict = [speech_queue objectAtIndex:0U];
			[self speakNotification:[speechDict valueForKey:@"summary"] withVoice:[speechDict valueForKey:GrowlSpeechVoicePref]];
		}
	}
	else
		NSLog(@"something else");
}

@end
