//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlBezelDisplay : GrowlDisplayPlugin {
	NSMutableArray		*notificationQueue;
}

@end
