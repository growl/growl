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
	
	[slider_Opacity setAltIncrementValue:5];
	
	READ_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, @"com.Growl.MusicVideo", &opacityPref);
	
	[slider_Opacity setIntValue:opacityPref];
	[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",opacityPref]];
}

- (void)didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

- (IBAction)preferenceChanged:(id)sender {
	int		opacityPref;
	
	if (sender == slider_Opacity) {
		opacityPref = [slider_Opacity intValue];
		[text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",opacityPref]];
		WRITE_GROWL_PREF_INT(MUSICVIDEO_OPACITY_PREF, opacityPref, @"com.Growl.MusicVideo");
	}

	UPDATE_GROWL_PREFS();
}

@end
