//
//  GrowlSmokePrefsController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlSmokePrefsController : NSPreferencePane {
	float					duration;
	float					opacity;
	BOOL					limit;
	BOOL					floatingIcon;

	IBOutlet NSSlider		*slider_opacity;
	IBOutlet NSComboBox		*combo_screen;

	IBOutlet NSColorWell	*color_veryLow;
	IBOutlet NSColorWell	*color_moderate;
	IBOutlet NSColorWell	*color_normal;
	IBOutlet NSColorWell	*color_high;
	IBOutlet NSColorWell	*color_emergency;

	IBOutlet NSColorWell	*text_veryLow;
	IBOutlet NSColorWell	*text_moderate;
	IBOutlet NSColorWell	*text_normal;
	IBOutlet NSColorWell	*text_high;
	IBOutlet NSColorWell	*text_emergency;
}

- (float) getDuration;
- (void) setDuration:(float)value;
- (float) getOpacity;
- (void) setOpacity:(float)value;
- (BOOL) getLimit;
- (void) setLimit:(BOOL)value;
- (BOOL) isFloatingIcon;
- (void) setFloatingIcon:(BOOL)value;
- (IBAction) colorChanged:(id)sender;
- (IBAction) textColorChanged:(id)sender;
- (IBAction) setScreen:(id)sender;

@end
