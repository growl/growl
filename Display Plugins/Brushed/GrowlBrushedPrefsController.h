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

	IBOutlet NSComboBox		*combo_screen;

	IBOutlet NSColorWell	*text_veryLow;
	IBOutlet NSColorWell	*text_moderate;
	IBOutlet NSColorWell	*text_normal;
	IBOutlet NSColorWell	*text_high;
	IBOutlet NSColorWell	*text_emergency;

	IBOutlet NSButton		*floatIconSwitch;
	IBOutlet NSButton		*limitCheck;
	IBOutlet NSButton		*aquaCheck;
}

- (float) getDuration;
- (void) setDuration:(float)value;
- (IBAction) textColorChanged:(id)sender;
- (IBAction) floatIconSwitchChanged:(id)sender;
- (IBAction) setLimit:(id)sender;
- (IBAction) setAqua:(id)sender;
- (IBAction) setScreen:(id)sender;

@end
