//
//  GrowlPref.h
//  Growl
//
//  Created by Karl Adam on Wed Apr 21 2004.
//

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/PreferencePanes.h>

@interface GrowlPref : NSPreferencePane {
    IBOutlet NSButton *_startGrowlButton;
    IBOutlet NSButton *_startGrowlLoginButton;
}

- (IBAction)startGrowl:(id)sender;
- (IBAction)startGrowlAtLogin:(id)sender;
@end
