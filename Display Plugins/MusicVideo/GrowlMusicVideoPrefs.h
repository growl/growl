//
//  GrowlMusicVideoPrefs.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

#define MusicVideoPrefDomain			@"com.Growl.MusicVideo"

#define MUSICVIDEO_SCREEN_PREF			@"Screen"

#define MUSICVIDEO_OPACITY_PREF			@"Opacity"
#define MUSICVIDEO_DEFAULT_OPACITY		60.0f

#define MUSICVIDEO_DURATION_PREF		@"Duration"
#define MUSICVIDEO_DEFAULT_DURATION		4.0f

#define MUSICVIDEO_SIZE_PREF			@"Size"
#define MUSICVIDEO_SIZE_NORMAL			0
#define MUSICVIDEO_SIZE_HUGE			1

#define MUSICVIDEO_EFFECT_PREF			@"Transition effect"
#define MUSICVIDEO_EFFECT_SLIDE			0
#define MUSICVIDEO_EFFECT_WIPE			1

@interface GrowlMusicVideoPrefs : NSPreferencePane {
	float					duration;
	float					opacity;
	IBOutlet NSMatrix		*radio_size;
	IBOutlet NSSlider		*slider_opacity;
	IBOutlet NSComboBox		*combo_screen;
}

- (float) getDuration;
- (void) setDuration:(float)value;
- (float) getOpacity;
- (void) setOpacity:(float)value;
- (IBAction) takeSizeFrom:(id)sender;
- (IBAction) takeScreenAsIntValueFrom:(id)sender;

@end
