//
//  GrowlPref.h
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlPref : NSPreferencePane {
	NSDictionary *cachedGrowlHelperAppDescription;

    IBOutlet NSButton *_startGrowlButton;
    IBOutlet NSButton *_startGrowlLoginButton;
}

- (IBAction)startGrowl:(id)sender;
- (IBAction)startGrowlAtLogin:(id)sender;

- (NSDictionary *)growlHelperAppDescription;

@end
