//
//  GrowlSmokePrefsController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlSmokePrefsController : NSPreferencePane {
  IBOutlet NSSlider		*slider_opacity;
  IBOutlet NSTextField	*text_opacity;
  IBOutlet NSSlider		*slider_duration;
  IBOutlet NSTextField	*text_duration;
  IBOutlet NSComboBox	*combo_screen;

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

  IBOutlet NSButton		*floatIconSwitch;
  IBOutlet NSButton		*limitCheck;
}

- (IBAction) opacityChanged:(id)sender;
- (IBAction) durationChanged:(id)sender;
- (IBAction) colorChanged:(id)sender;
- (IBAction) textColorChanged:(id)sender;
- (IBAction) floatIconSwitchChanged:(id)sender;
- (IBAction) setLimit:(id)sender;
- (IBAction) setScreen:(id)sender;

@end
