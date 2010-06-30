//
//  GrowlSpeechPrefs.h
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlSpeechPrefs : NSPreferencePane {
	IBOutlet NSTableView	*voiceList;
	NSArray					*voices;
	NSSpeechSynthesizer		*lastPreview;
}
- (IBAction) previewVoice:(id)sender;
- (IBAction) voiceClicked:(id)sender;

@property (nonatomic, retain) NSArray *voices;

@end
