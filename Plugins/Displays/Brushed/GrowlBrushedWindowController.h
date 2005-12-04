//
//  GrowlBrushedWindowController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@class GrowlApplicationNotification, GrowlAnimation;

@interface GrowlBrushedWindowController : GrowlDisplayWindowController {
	unsigned	depth;
	NSString	*identifier;
	unsigned	uid;
}

- (id) initWithNotification:(GrowlApplicationNotification *)noteDict depth:(unsigned)depth;
- (void) growlAnimationDidEnd:(GrowlAnimation *)animation;
- (unsigned) depth;
@end
