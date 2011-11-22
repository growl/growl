//
//  GrowlBezelWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@interface GrowlBezelWindowController : GrowlDisplayWindowController {

	int						priority;
	BOOL					flipIn;
	BOOL					flipOut;
	BOOL					shrinkEnabled;
	BOOL					flipEnabled;
}

- (NSPoint) idealOriginInRect:(NSRect)rect forRect:(NSRect)viewFrame;

@end
