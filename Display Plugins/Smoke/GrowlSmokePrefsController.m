//
//  GrowlSmokePrefsController.m
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlSmokePrefsController.h"
#import "GrowlSmokeDefines.h"
#import "GrowlDefines.h"


@implementation GrowlSmokePrefsController

- (NSString *) mainNibName {
	return @"SmokePrefs";
}


- (void) mainViewDidLoad {  
  float alphaPref = GrowlSmokeAlphaPrefDefault;
  READ_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, GrowlSmokePrefDomain, &alphaPref);
  [opacitySlider setMinValue:0.05];
  [opacitySlider setFloatValue:alphaPref];
  [text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floor(alphaPref * 100.)]];
}


- (IBAction) opacitySliderChanged:(id)sender {
  float newValue = [opacitySlider floatValue];
  WRITE_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, newValue, GrowlSmokePrefDomain);
  [text_Opacity setStringValue:[NSString stringWithFormat:@"%d%%",(int)floor(newValue * 100.)]];
  UPDATE_GROWL_PREFS();
}

@end
