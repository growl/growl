//
//  GrowlSpeechPrefs.m
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "GrowlSpeechPrefs.h"
#import "GrowlSpeechDefines.h"
#import "AppKit/NSSpeechSynthesizer.h"

@implementation GrowlSpeechPrefs
- (NSString *) mainNibName
{
	return @"GrowlSpeechPrefs";
}

- (void) awakeFromNib
{
	voices = [[NSSpeechSynthesizer availableVoices] retain];
	[voiceList reloadData];
}

- (void) dealloc
{
	[voices release];
	[super dealloc];
}

- (int) numberOfRowsInTableView:(NSTableView *)theTableView
{
	return [voices count];
}

- (id) tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(int)rowIndex
{
	NSDictionary *attributes = [NSSpeechSynthesizer attributesForVoice:[voices objectAtIndex:rowIndex]];
	return [attributes objectForKey:NSVoiceName];
}

- (IBAction) voiceClicked:(id)sender
{
	int row = [sender selectedRow];

	if ( -1 != row ) {
		NSString *voice = [voices objectAtIndex:row];
		WRITE_GROWL_PREF_VALUE(GrowlSpeechVoicePref, (CFStringRef)voice, GrowlSpeechPrefDomain );
		SYNCHRONIZE_GROWL_PREFS();
		UPDATE_GROWL_PREFS();
	}
}

@end
