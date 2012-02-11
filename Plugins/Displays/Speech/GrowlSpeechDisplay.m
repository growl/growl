//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefinesInternal.h"
#import "GrowlNotification.h"

@implementation GrowlSpeechDisplay
@synthesize speech_queue;
@synthesize syn;

- (id) init {
    if((self = [super init])) {
        self.speech_queue = [NSMutableArray array];
        self.syn = [[[NSSpeechSynthesizer alloc] initWithVoice:nil] autorelease];
        syn.delegate = self;

    }
    return self;
}

- (void) dealloc {
    [speech_queue release];
    [syn release];
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.growl.Speech"]];

	return preferencePane;
}

- (void) displayNotification:(GrowlNotification *)notification {
    
	NSString *title = [notification title];
	NSString *desc = [notification notificationDescription];
	
	NSString *summary = [NSString stringWithFormat:@"%@\n\n%@", title, desc];
	
    
    [speech_queue addObject:summary];
    if(![syn isSpeaking])
    {
        [self speakNotification:summary];
    }
            
    NSDictionary *noteDict = [notification dictionaryRepresentation];
    if ([[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]) {
        NSString *path = [[[GrowlPathUtilities screenshotsDirectory] stringByAppendingPathComponent:[GrowlPathUtilities nextScreenshotName]] stringByAppendingPathExtension:@"aiff"];
        NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
        [syn startSpeakingString:summary toURL:url];
        [url release];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_TIMED_OUT object:notification userInfo:nil];
}

- (BOOL)requiresPositioning {
	return NO;
}

- (void)speakNotification:(NSString*)notificationToSpeak
{
    NSString *voice = nil;
	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);
	if (voice) {
		CFMakeCollectable(voice);
		[voice autorelease];
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
            [self speakNotification:[speech_queue objectAtIndex:0U]];
        }
    }
    else
        NSLog(@"something else");
}

@end
