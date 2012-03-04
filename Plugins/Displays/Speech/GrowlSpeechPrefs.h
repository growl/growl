//
//  GrowlSpeechPrefs.h
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import "GrowlPluginPreferencePane.h"

@interface GrowlSpeechPrefs : GrowlPluginPreferencePane {
	IBOutlet NSTableView	*voiceList;
	NSArray					*voices;
	NSSpeechSynthesizer		*lastPreview;
}
- (void) updateVoiceList;
- (IBAction) previewVoice:(id)sender;
- (IBAction) voiceClicked:(id)sender;

@property (nonatomic, retain) NSString *voiceLabel;
@property (nonatomic, retain) NSString *nameColumnLabel;
@property (nonatomic, retain) NSArray *voices;

@end
