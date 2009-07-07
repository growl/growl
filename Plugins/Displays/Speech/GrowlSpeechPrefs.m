//
//  GrowlSpeechPrefs.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import <AppKit/NSSpeechSynthesizer.h>

@implementation GrowlSpeechPrefs
- (NSString *) mainNibName {
	return @"GrowlSpeechPrefs";
}

- (void) awakeFromNib {
	NSArray *availableVoices = [NSSpeechSynthesizer availableVoices];
	NSEnumerator *voiceEnum = [availableVoices objectEnumerator];
	NSMutableArray *voiceAttributes = [[NSMutableArray alloc] initWithCapacity:[availableVoices count]];
	NSString *voiceIdentifier;
	while ((voiceIdentifier=[voiceEnum nextObject])) {
		[voiceAttributes addObject:[NSSpeechSynthesizer attributesForVoice:voiceIdentifier]];
	}
	[self setVoices:voiceAttributes];
	[voiceAttributes release];

	NSString *voice = nil;
	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);
	NSUInteger row = NSNotFound;
	if (voice) {
		row = [availableVoices indexOfObject:voice];
		[voice release];
    }

	if (row == NSNotFound)
		row = [availableVoices indexOfObject:[NSSpeechSynthesizer defaultVoice]];

    if ((row == NSNotFound) && ([availableVoices count]))
        row = 1;

    if (row != NSNotFound) {
	   [voiceList selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	   [voiceList scrollRowToVisible:row];
    }
	[voiceList setDoubleAction:@selector(previewVoice:)];
}

- (NSArray *) voices {
	return voices;
}

- (void) setVoices:(NSArray *)theVoices {
	[voices release];
	voices = [theVoices retain];
}

- (void) dealloc {
	[voices release];
	[super dealloc];
}

- (IBAction) previewVoice:(id)sender {
	
	NSInteger row = [sender selectedRow];
	
	if (row != -1) {
		if(lastPreview != nil && [lastPreview isSpeaking]) {
			[lastPreview stopSpeaking];
		}
		NSString *voice = [[voices objectAtIndex:row] objectForKey:NSVoiceIdentifier];
		NSSpeechSynthesizer *quickVoice = [[NSSpeechSynthesizer alloc] initWithVoice:voice];
		[quickVoice startSpeakingString:[NSString stringWithFormat:NSLocalizedString(@"This is a preview of the %@ voice.", nil), [[voices objectAtIndex:row] objectForKey:NSVoiceName]]];
		lastPreview = quickVoice;
	}
}

- (IBAction) voiceClicked:(id)sender {
	NSInteger row = [sender selectedRow];

	if (row != -1) {
		NSString *voice = [[voices objectAtIndex:row] objectForKey:NSVoiceIdentifier];
		WRITE_GROWL_PREF_VALUE(GrowlSpeechVoicePref, voice, GrowlSpeechPrefDomain);
		UPDATE_GROWL_PREFS();
	}
}

@end
