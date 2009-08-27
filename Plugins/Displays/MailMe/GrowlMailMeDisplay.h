//
//  GrowlMailMeDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Peter Hosey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlMailMeDisplay: GrowlDisplayPlugin {
}

- (void) displayNotification:(GrowlApplicationNotification *)notification;

@end
