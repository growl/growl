//
//  GrowlSmokePrefsController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlSmokePrefsController : NSPreferencePane {
  IBOutlet NSSlider *opacitySlider;
  IBOutlet NSTextField *text_Opacity;

  IBOutlet NSColorWell    *color_veryLow;
  IBOutlet NSColorWell    *color_moderate;
  IBOutlet NSColorWell    *color_normal;
  IBOutlet NSColorWell    *color_high;
  IBOutlet NSColorWell    *color_emergency;
  
  IBOutlet NSColorWell    *text_veryLow;
  IBOutlet NSColorWell    *text_moderate;
  IBOutlet NSColorWell    *text_normal;
  IBOutlet NSColorWell    *text_high;
  IBOutlet NSColorWell    *text_emergency;

  IBOutlet NSButton *floatIconSwitch;
  IBOutlet NSButton *limitCheck;
}

- (IBAction)opacitySliderChanged:(id)sender;
- (IBAction)colorChanged:(id)sender;
- (IBAction)textColorChanged:(id)sender;
- (IBAction)floatIconSwitchChanged:(id)sender;
- (IBAction)setLimit:(id)sender;

@end
