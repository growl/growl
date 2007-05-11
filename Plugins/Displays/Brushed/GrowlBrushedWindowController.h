//
//  GrowlBrushedWindowController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@class GrowlApplicationNotification;

@interface GrowlBrushedWindowController : GrowlDisplayWindowController {
	unsigned	depth;
	unsigned	uid;
}

- (unsigned) depth;
- (void) setNotification: (GrowlApplicationNotification *) theNotification;

@end
