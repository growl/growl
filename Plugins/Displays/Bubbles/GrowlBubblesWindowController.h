//
//  GrowlBubblesWindowController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"

@class GrowlApplicationNotification;

@interface GrowlBubblesWindowController : GrowlDisplayFadingWindowController {
	unsigned	depth;
	NSString	*identifier;
}

- (id) initWithNotification:(GrowlApplicationNotification *)noteDict;

@end
