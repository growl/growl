//
//  GrowlMusicVideoPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoPrefs.h"


@implementation GrowlMusicVideoPrefs

- (NSString *)mainNibName {
	return @"GrowlMusicVideoPrefs";
}

- (void)mainViewDidLoad {
	int		opacityPref = MUSICVIDEO_DEFAULT_OPACITY;
	int		sizePref = 0;
	
	[slider_Opacity setAltIncrementValue:5];
	
	READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, @"com.Growl.MusicVideo", &opacityPref);
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, @"com.Growl.MusicVideo", &sizePref);
	
	[radio_Size selectCellAtRow:sizePref column:0];
	[slider_Opacity setIntValue:opacityPref];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",opacityPref]];
}

- (void)didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

- (IBAction)preferenceChanged:(id)sender {
	int		opacityPref;
	int		sizePref;
	
	if (sender == slider_Opacity) {
		opacityPref = [slider_Opacity intValue];
		[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",opacityPref]];
		WRITE_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, opacityPref, @"com.Growl.MusicVideo");
	} else if (sender == radio_Size) {
		sizePref = [radio_Size selectedRow];
		WRITE_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, sizePref, @"com.Growl.MusicVideo");
	}

	UPDATE_GROWL_PREFS();
}

@end
