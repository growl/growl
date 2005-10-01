//
//  GrowlMailMeDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Mac-arena the Bored Zo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayPlugin.h"

@class NSPreferencePane;

@interface GrowlMailMeDisplay: GrowlDisplayPlugin
{
	NSPreferencePane	*prefPane;
}

- (void) displayNotification:(GrowlApplicationNotification *)notification;

@end
