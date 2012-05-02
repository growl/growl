//
//  GrowlSpeechPrefs.h
//  Display Plugins
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlPluginPreferencePane.h>

@class SRRecorderControl;

@interface GrowlSpeechPrefs : GrowlPluginPreferencePane {
	IBOutlet NSPopUpButton	*voiceList;
	NSArray					*voices;
	NSSpeechSynthesizer		*lastPreview;
}
- (void) updateVoiceList;
- (IBAction) previewVoice:(id)sender;
- (IBAction) voiceClicked:(id)sender;

@property (nonatomic, assign) IBOutlet SRRecorderControl *pauseShortcut;
@property (nonatomic, assign) IBOutlet SRRecorderControl *skipShortcut;
@property (nonatomic, assign) IBOutlet SRRecorderControl *clickShortcut;

@property (nonatomic, retain) NSString *voiceLabel;
@property (nonatomic, retain) NSString *nameColumnLabel;
@property (nonatomic, retain) NSArray *voices;

@property (nonatomic, assign) BOOL useLimit;
@property (nonatomic, assign) NSUInteger characterLimit;
@property (nonatomic, assign) BOOL useRate;
@property (nonatomic, assign) float rate;
@property (nonatomic, assign) BOOL useVolume;
@property (nonatomic, assign) NSUInteger volume;

@end
