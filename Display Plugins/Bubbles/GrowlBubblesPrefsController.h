//
//  GrowlBubblesPrefsController.h
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Name changed from KABubblePrefsController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

#define KALimitPref @"Bubbles - Limit"

@interface GrowlBubblesPrefsController : NSPreferencePane {
	IBOutlet NSButton *limitCheck;
	IBOutlet NSColorWell *color_veryLow;
	IBOutlet NSColorWell *color_moderate;
	IBOutlet NSColorWell *color_normal;
	IBOutlet NSColorWell *color_high;
	IBOutlet NSColorWell *color_emergency;

}
- (IBAction) setLimit:(id)sender;
- (IBAction) colorChanged:(id)sender;

@end
