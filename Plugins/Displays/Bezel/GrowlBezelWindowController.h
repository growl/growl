//
//  GrowlBezelWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"

@class GrowlBezelWindowView, GrowlAnimation;

@interface GrowlBezelWindowController : GrowlDisplayWindowController {

	int						priority;
	BOOL					flipIn;
	BOOL					flipOut;
	BOOL					shrinkEnabled;
	BOOL					flipEnabled;
	NSString				*identifier;
}

- (void) growlAnimationDidEnd:(GrowlAnimation *)animation;


- (NSString *) identifier;
- (int) priority;
- (void) setPriority:(int)newPriority;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;
- (void) setIcon:(NSImage *)icon;

- (void) setFlipIn:(BOOL)flag;
- (void) setFlipOut:(BOOL)flag;

@end
