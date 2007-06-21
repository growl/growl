//
//  GrowlNanoPrefs.h
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005-2006, The Growl Project. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

#define GrowlNanoPrefDomain			@"com.Growl.Nano"

#define Nano_SCREEN_PREF			@"Screen"

#define Nano_OPACITY_PREF			@"Opacity"
#define Nano_DEFAULT_OPACITY		60.0f

#define Nano_DURATION_PREF		@"Duration"
#define GrowlNanoDurationPrefDefault		4.0f

#define Nano_SIZE_PREF			@"Size"
typedef enum {
	Nano_SIZE_NORMAL = 0,
	Nano_SIZE_HUGE = 1
} NanoSize;

#define Nano_EFFECT_PREF			@"Transition effect"
typedef enum {
	Nano_EFFECT_SLIDE = 0,
	Nano_EFFECT_WIPE,
	Nano_EFFECT_FADE
} NanoEffectType;

#define GrowlNanoVeryLowBackgroundColor	@"Nano-Priority-VeryLow-Color"
#define GrowlNanoModerateBackgroundColor	@"Nano-Priority-Moderate-Color"
#define GrowlNanoNormalBackgroundColor	@"Nano-Priority-Normal-Color"
#define GrowlNanoHighBackgroundColor		@"Nano-Priority-High-Color"
#define GrowlNanoEmergencyBackgroundColor	@"Nano-Priority-Emergency-Color"

#define GrowlNanoVeryLowTextColor			@"Nano-Priority-VeryLow-Text-Color"
#define GrowlNanoModerateTextColor		@"Nano-Priority-Moderate-Text-Color"
#define GrowlNanoNormalTextColor			@"Nano-Priority-Normal-Text-Color"
#define GrowlNanoHighTextColor			@"Nano-Priority-High-Text-Color"
#define GrowlNanoEmergencyTextColor		@"Nano-Priority-Emergency-Text-Color"

@interface GrowlNanoPrefs : NSPreferencePane {
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

- (NSColor *) textColorVeryLow;
- (void) setTextColorVeryLow:(NSColor *)value;
- (NSColor *) textColorModerate;
- (void) setTextColorModerate:(NSColor *)value;
- (NSColor *) textColorNormal;
- (void) setTextColorNormal:(NSColor *)value;
- (NSColor *) textColorHigh;
- (void) setTextColorHigh:(NSColor *)value;
- (NSColor *) textColorEmergency;
- (void) setTextColorEmergency:(NSColor *)value;

- (NSColor *) backgroundColorVeryLow;
- (void) setBackgroundColorVeryLow:(NSColor *)value;
- (NSColor *) backgroundColorModerate;
- (void) setBackgroundColorModerate:(NSColor *)value;
- (NSColor *) backgroundColorNormal;
- (void) setBackgroundColorNormal:(NSColor *)value;
- (NSColor *) backgroundColorHigh;
- (void) setBackgroundColorHigh:(NSColor *)value;
- (NSColor *) backgroundColorEmergency;
- (void) setBackgroundColorEmergency:(NSColor *)value;

@end
