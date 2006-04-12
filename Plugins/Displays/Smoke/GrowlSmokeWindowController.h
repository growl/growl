//
//  GrowlSmokeWindowController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@class GrowlApplicationNotification;

@interface GrowlSmokeWindowController : GrowlDisplayWindowController {
	NSString	*identifier;
	unsigned	uid;
}

@end
