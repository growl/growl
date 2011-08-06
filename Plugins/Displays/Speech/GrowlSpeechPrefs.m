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
@synthesize voices;

- (NSString *) mainNibName {
	return @"GrowlSpeechPrefs";
}

- (void) awakeFromNib {
	NSArray *availableVoices = [NSArray arrayWithObject:GrowlSpeechSystemVoice];
	NSMutableArray *voiceAttributes = [NSMutableArray array];
	
    NSMutableDictionary *defaultChoice = [NSMutableDictionary dictionary];
    [defaultChoice setObject:GrowlSpeechSystemVoice forKey:NSVoiceIdentifier];
    [defaultChoice setObject:NSLocalizedString(@"System Default", @"The voice chosen as the system voice in the Speech preference pane") forKey:NSVoiceName];
    [voiceAttributes addObject:defaultChoice];
    
	for (NSString *voiceIdentifier in [NSSpeechSynthesizer availableVoices]) {
		[voiceAttributes addObject:[NSSpeechSynthesizer attributesForVoice:voiceIdentifier]];
	}
    availableVoices = [availableVoices arrayByAddingObjectsFromArray:[NSSpeechSynthesizer availableVoices]];
	[self setVoices:voiceAttributes];

	NSString *voice = nil;
	READ_GROWL_PREF_VALUE(GrowlSpeechVoicePref, GrowlSpeechPrefDomain, NSString *, &voice);
	NSUInteger row = NSNotFound;
	if (voice) {
		CFMakeCollectable(voice);
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
		if([voice isEqualToString:GrowlSpeechSystemVoice])
            voice = nil;
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
