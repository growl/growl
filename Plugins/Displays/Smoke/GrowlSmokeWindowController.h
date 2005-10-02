//
//  GrowlSmokeWindowController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"

@class GrowlApplicationNotification;

@interface GrowlSmokeWindowController : GrowlDisplayFadingWindowController {
	unsigned	depth;
	NSString	*identifier;
	unsigned	uid;
	id			plugin; // the GrowlSmokeDisplay object which created us
}

- (id) initWithNotification:(GrowlApplicationNotification *)notification depth:(unsigned)depth;
- (unsigned) depth;
- (void) setProgress:(NSNumber *)value;
@end
