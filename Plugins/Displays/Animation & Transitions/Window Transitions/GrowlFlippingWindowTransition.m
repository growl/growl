//
//  GrowlFlippingWindowTransition.m
//  Growl
//
//  Created by Jamie Kirkpatrick on 04/12/2005.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlFlippingWindowTransition.h"

@implementation GrowlFlippingWindowTransition

- (id) initWithWindow:(NSWindow *)inWindow {
	if ((self = [super initWithWindow:inWindow])) {
		flipsX = NO;
		flipsY = NO;
	}

	return self;
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)inProgress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				//[aWindow setScaleX:(flipsX ? inProgress : 1.0) Y:(flipsY ? inProgress : 1.0)];
				break;
			case GrowlReverseTransition:
				//[aWindow setScaleX:(flipsX ? 1.0 - inProgress : 1.0) Y:(flipsY ? 1.0 - inProgress : 1.0)];
				break;
			default:
				break;
		}
	}
}

#pragma mark -

- (void) startAnimation {
	if (!flipsX && !flipsY )
		return;

	[super startAnimation];
}

- (void) stopAnimation {
	if (!flipsX && !flipsY )
		return;

	[super stopAnimation];
}

#pragma mark -
#pragma mark accessors

- (BOOL) flipsX {
    return flipsX;
}

- (void) setFlipsX: (BOOL) flag {
    flipsX = flag;
}

- (BOOL) flipsY {
    return flipsY;
}

- (void) setFlipsY: (BOOL) flag {
    flipsY = flag;
}


@end
