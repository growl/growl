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
}

- (IBAction)opacitySliderChanged:(id)sender;
- (IBAction) colorChanged:(id)sender;

@end
