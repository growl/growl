//
//  GrowlMailMePrefs.h
//  Display Plugins
//
//  Copyright 2004 Peter Hosey. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface GrowlMailMePrefs: NSPreferencePane {
}

- (NSString *) getDestAddress;
- (void) setDestAddress:(NSString *)value;

@end
