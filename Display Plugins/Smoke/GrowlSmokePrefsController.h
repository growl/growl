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
}

- (IBAction)opacitySliderChanged:(id)sender;

@end
