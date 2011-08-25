//
//  GrowlSpeechDisplay.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlSpeechDisplay.h"
#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefinesInternal.h"
#import "GrowlNotification.h"

@implementation GrowlSpeechDisplay

- (id) init {
    if((self = [super init])) {
        speech_queue = dispatch_queue_create("com.Growl.Speech", NULL);
    }
    return self;
}

- (void) dealloc {
	[preferencePane release];
	[super dealloc];
}

- (NSPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlSpeechPrefs alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.growl.Speech"]];

	return preferencePane;
}

- (void) displayNotification:(GrowlNotification *)notification {
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
    
	NSString *title = [notification title];
	NSString *desc = [notification notificationDescription];
	
	NSString *summary = [NSString stringWithFormat:@"%@\n\n%@", title, desc];
	
	NSSpeechSynthesizer *syn = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
	
    dispatch_async(speech_queue, ^(void) {
        while([NSSpeechSynthesizer isAnyApplicationSpeaking])
        {
        }
        [syn startSpeakingString:summary];
        
        NSDictionary *noteDict = [notification dictionaryRepresentation];
        if ([[noteDict objectForKey:GROWL_SCREENSHOT_MODE] boolValue]) {
            NSString *path = [[[GrowlPathUtilities screenshotsDirectory] stringByAppendingPathComponent:[GrowlPathUtilities nextScreenshotName]] stringByAppendingPathExtension:@"aiff"];
            NSURL *url = [[NSURL alloc] initFileURLWithPath:path];
            [syn startSpeakingString:summary toURL:url];
            [url release];
        }
        
        [syn autorelease];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_TIMED_OUT object:notification userInfo:nil];
    });
}

- (BOOL)requiresPositioning {
	return NO;
}

@end
