//
//  GrowlSmokeDisplay.h
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayPlugin.h"

@class NSPreferencePane;

@interface GrowlSmokeDisplay : GrowlDisplayPlugin {
	NSPreferencePane	*preferencePane;
}

- (void) displayNotification:(GrowlApplicationNotification *)notification;

@end
