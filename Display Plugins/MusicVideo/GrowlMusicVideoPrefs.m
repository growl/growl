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

	[slider_Opacity setAltIncrementValue:5.0];

	READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, MusicVideoPrefDomain, &opacityPref);
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);

	[radio_Size selectCellAtRow:sizePref column:0];
	[slider_Opacity setIntValue:opacityPref];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%", opacityPref]];

	// duration
	duration = MUSICVIDEO_DEFAULT_DURATION;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, MusicVideoPrefDomain, &duration);
	[self setDuration:duration];

	// screen number
	int screenNumber = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, MusicVideoPrefDomain, &screenNumber);
	[combo_screen setIntValue:screenNumber];
}

- (void)didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

- (float) getDuration {
	return duration;
}

- (void) setDuration:(float)value {
	if (duration != value) {
		WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, value, MusicVideoPrefDomain);
		UPDATE_GROWL_PREFS();
	}
	duration = value;
}

- (IBAction)preferenceChanged:(id)sender {
	int opacityPref;
	int sizePref;

	if (sender == slider_Opacity) {
		opacityPref = [slider_Opacity intValue];
		[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%", opacityPref]];
		WRITE_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, opacityPref, MusicVideoPrefDomain);
	} else if (sender == radio_Size) {
		sizePref = [radio_Size selectedRow];
		WRITE_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, sizePref, MusicVideoPrefDomain);
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
