//
//  GrowlMailMePrefs.h
//  Display Plugins
//
//  Copyright 2004 Mac-arena the Bored Zo. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>
#import "GrowlDefines.h"

@interface GrowlMailMePrefs: NSPreferencePane
{
	IBOutlet NSTextField	*destAddressField;
}

- (IBAction)preferenceChanged:(id)sender;

@end
