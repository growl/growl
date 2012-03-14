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
		 speech_dispatch_queue = dispatch_queue_create("com.growl.Speech.speech_dispatch_queue", 0);
    }
    return self;
}

- (void) dealloc {
	dispatch_release(speech_dispatch_queue);
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
	__block GrowlSpeechDisplay *blockSelf = self;
	//We are called on a background concurrent queue, but we want access to our queue serialized to one thread/serial queue
	dispatch_async(speech_dispatch_queue, ^{
		NSString *title = [noteDict valueForKey:GROWL_NOTIFICATION_TITLE];
		NSString *desc = [noteDict valueForKey:GROWL_NOTIFICATION_DESCRIPTION];
		
		NSString *summary = [NSString stringWithFormat:@"%@\n\n%@", title, desc];
		NSString *voice = [configuration valueForKey:GrowlSpeechVoicePref];
		NSDictionary *queueDict = [NSDictionary dictionaryWithObjectsAndKeys:summary, @"summary", voice, GrowlSpeechVoicePref, nil];
		
		[blockSelf.speech_queue addObject:queueDict];
		if(![blockSelf.syn isSpeaking])
		{
			[blockSelf speakNotification:summary withVoice:voice];
		}
		
		if ([[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]) {
			NSString *path = [[[GrowlPathUtilities screenshotsDirectory] stringByAppendingPathComponent:[GrowlPathUtilities nextScreenshotName]] stringByAppendingPathExtension:@"aiff"];
			NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
			[blockSelf.syn startSpeakingString:summary toURL:url];
			[url release];
		}
	});
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
		if([speech_queue count]){
			[speech_queue removeObjectAtIndex:0U];
			if([speech_queue count])
			{
				//insert a slight delay
				__block GrowlSpeechDisplay *blockSelf = self;
				NSDictionary *speechDict = [speech_queue objectAtIndex:0U];
				double delayInSeconds = 1.0;
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
				dispatch_after(popTime, speech_dispatch_queue, ^(void){
					[blockSelf speakNotification:[speechDict valueForKey:@"summary"] withVoice:[speechDict valueForKey:GrowlSpeechVoicePref]];
				});
			}
		}
	}
	else
		NSLog(@"something else");
}

@end
