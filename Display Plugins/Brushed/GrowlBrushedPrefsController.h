//
//  GrowlBrushedPrefsController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlBrushedPrefsController : NSPreferencePane {
	float					duration;
	BOOL					floatingIcon;
	BOOL					limit;
	BOOL					aqua;

	IBOutlet NSComboBox		*combo_screen;

	IBOutlet NSColorWell	*text_veryLow;
	IBOutlet NSColorWell	*text_moderate;
	IBOutlet NSColorWell	*text_normal;
	IBOutlet NSColorWell	*text_high;
	IBOutlet NSColorWell	*text_emergency;
}

- (float) getDuration;
- (void) setDuration:(float)value;
- (BOOL) isFloatingIcon;
- (void) setFloatingIcon:(BOOL)value;
- (BOOL) isLimit;
- (void) setLimit:(BOOL)value;
- (BOOL) isAqua;
- (void) setAqua:(BOOL)value;
- (IBAction) textColorChanged:(id)sender;
- (IBAction) setScreen:(id)sender;

@end
