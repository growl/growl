//
//  GrowlNanoDisplay.h
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005Ð2011, The Growl Project. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "GrowlDisplayPlugin.h"

@class GrowlApplicationNotification;

@interface GrowlNanoDisplay : GrowlDisplayPlugin {
}

- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge;

@end
