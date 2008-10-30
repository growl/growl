//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlBezelDisplay : GrowlDisplayPlugin {
}

- (id) init;
- (void) dealloc;
- (NSPreferencePane *) preferencePane;

@end
