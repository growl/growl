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
  [opacitySlider setFloatValue:alphaPref];
}


- (IBAction) opacitySliderChanged:(id)sender {
  float newValue = [opacitySlider floatValue];
  WRITE_GROWL_PREF_FLOAT(GrowlSmokeAlphaPref, newValue, GrowlSmokePrefDomain);
  UPDATE_GROWL_PREFS();
}

@end
