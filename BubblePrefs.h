//
//  BubblePrefsController.h
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

#define KALimitPref @"Bubbles - Limit"

@interface BubblePrefs : NSPreferencePane {
	IBOutlet NSButton *limitCheck;
}
- (IBAction) setLimit:(id)sender;
@end
