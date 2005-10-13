//
//  GrowlMusicVideoDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlDisplayPlugin.h"

@class GrowlApplicationNotification;

@interface GrowlMusicVideoDisplay : GrowlDisplayPlugin {
	NSMutableArray		*notificationQueue;
}

- (void) displayNotification:(GrowlApplicationNotification *)notification;

@end
