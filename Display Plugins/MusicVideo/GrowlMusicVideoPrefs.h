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
	IBOutlet NSSlider *slider_opacity;
}

- (float) duration;
- (void) setDuration:(float)value;
- (unsigned) effect;
- (void) setEffect:(unsigned)newEffect;
- (float) opacity;
- (void) setOpacity:(float)value;
- (int) size;
- (void) setSize:(int)value;
- (int) screen;
- (void) setScreen:(int)value;

@end
