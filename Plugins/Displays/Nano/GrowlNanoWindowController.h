//
//  GrowlNanoWindowController.h
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005-2006, The Growl Project. All rights reserved.
//


#import "GrowlDisplayWindowController.h"

@class GrowlNanoWindowView;

@interface GrowlNanoWindowController : GrowlDisplayWindowController {
	float						frameHeight;
	float						frameY;
	int							priority;
	bool						doFadeIn;
}

- (void) setDisplayMode:(BOOL)mode;
@end
