//
//  GrowlBrushedPrefsController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlBrushedPrefsController : NSPreferencePane {
	IBOutlet NSSlider		*slider_duration;
	IBOutlet NSTextField	*text_duration;
	
	IBOutlet NSColorWell	*text_veryLow;
	IBOutlet NSColorWell	*text_moderate;
	IBOutlet NSColorWell	*text_normal;
	IBOutlet NSColorWell	*text_high;
	IBOutlet NSColorWell	*text_emergency;

	IBOutlet NSButton		*floatIconSwitch;
	IBOutlet NSButton		*limitCheck;
	IBOutlet NSButton		*aquaCheck;
}

- (IBAction) durationChanged:(id)sender;
- (IBAction) textColorChanged:(id)sender;
- (IBAction) floatIconSwitchChanged:(id)sender;
- (IBAction) setLimit:(id)sender;
- (IBAction) setAqua:(id)sender;

@end
