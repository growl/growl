//
//  GrowlSpeechPrefs.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import <AppKit/NSSpeechSynthesizer.h>

@implementation GrowlSpeechPrefs
@synthesize voices;
@synthesize voiceLabel;
@synthesize nameColumnLabel;

- (id)initWithBundle:(NSBundle *)bundle {
   if((self = [super initWithBundle:bundle])){
      self.voiceLabel = NSLocalizedString(@"Voice:", @"Label for table with voices");
      self.nameColumnLabel = NSLocalizedString(@"Name", @"Column title for the name of voice");
   }
   return self;
}

- (NSString *) mainNibName {
	return @"GrowlSpeechPrefs";
}

- (void) awakeFromNib {
	[self updateVoiceList];
	[voiceList setDoubleAction:@selector(previewVoice:)];
}

- (void) dealloc {
	[voices release];
   [voiceLabel release];
   [nameColumnLabel release];
	[super dealloc];
}

-(void)updateVoiceList {
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
}

-(void)updateConfigurationValues {
	[self updateVoiceList];
	NSString *voice = [self.configuration valueForKey:GrowlSpeechVoicePref];
	NSArray *availableVoices = [voices valueForKey:NSVoiceIdentifier];
	NSUInteger row = NSNotFound;
	if (voice) {
		row = [availableVoices indexOfObject:voice];
	}
	
	if (row == NSNotFound)
		row = [availableVoices indexOfObject:[NSSpeechSynthesizer defaultVoice]];
	
	if ((row == NSNotFound) && ([availableVoices count]))
		row = 1;
	
	if (row != NSNotFound && [voices count] > 0) {
	   [voiceList selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	   [voiceList scrollRowToVisible:row];
	}
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
		[self setConfigurationValue:voice forKey:GrowlSpeechVoicePref];
	}
}

@end
