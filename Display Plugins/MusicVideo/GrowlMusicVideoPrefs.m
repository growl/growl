//
//  GrowlMusicVideoPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoPrefs.h"
#import <GrowlDefinesInternal.h>

@implementation GrowlMusicVideoPrefs

- (NSString *)mainNibName {
	return @"GrowlMusicVideoPrefs";
}

- (void)mainViewDidLoad {
	int		opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
	int		sizePref = 0;
	float	durationPref = MUSICVIDEO_DEFAULT_DURATION;

	[slider_Opacity setAltIncrementValue:5.0];

	READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, MusicVideoPrefDomain, &opacityPref);
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, MusicVideoPrefDomain, &durationPref);

	[radio_Size selectCellAtRow:sizePref column:0];
	[slider_Opacity setIntValue:opacityPref];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%", opacityPref]];
	[slider_Duration setFloatValue:durationPref];
	[text_Duration setStringValue:[NSString stringWithFormat:@"%.2f s", durationPref]];

	// screen number
	int screenNumber = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, MusicVideoPrefDomain, &screenNumber);
	[combo_screen setIntValue:screenNumber];
}

- (void)didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

- (IBAction)preferenceChanged:(id)sender {
	int		opacityPref;
	int		sizePref;
	float	durationPref;
	
	if (sender == slider_Opacity) {
		opacityPref = [slider_Opacity intValue];
		[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%", opacityPref]];
		WRITE_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, opacityPref, MusicVideoPrefDomain);
	} else if (sender == radio_Size) {
		sizePref = [radio_Size selectedRow];
		WRITE_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, sizePref, MusicVideoPrefDomain);
	} else if (sender == slider_Duration) {
		durationPref = [slider_Duration floatValue];
		[text_Duration setStringValue:[NSString stringWithFormat:@"%.2f s", durationPref]];
		WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, durationPref, MusicVideoPrefDomain);
	}

	UPDATE_GROWL_PREFS();
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox {
	return [[NSScreen screens] count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)idx {
	return [NSNumber numberWithInt:idx];
}

- (IBAction) takeScreenAsIntValueFrom:(id)sender {
	int pref = [sender intValue];
	WRITE_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, pref, MusicVideoPrefDomain);	
	UPDATE_GROWL_PREFS();
}

@end
