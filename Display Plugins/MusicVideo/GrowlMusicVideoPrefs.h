//
//  GrowlMusicVideoPrefs.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import "GrowlDefines.h"

#define MUSICVIDEO_OPACITY_PREF			@"MusicVideo - Opacity"
#define MUSICVIDEO_DEFAULT_OPACITY		60
#define MUSICVIDEO_TOP_HEIGHT			192.

@interface GrowlMusicVideoPrefs : NSPreferencePane {
	IBOutlet NSSlider		*slider_Opacity;
	IBOutlet NSTextField	*text_Opacity;
}

- (IBAction)preferenceChanged:(id)sender;

@end
