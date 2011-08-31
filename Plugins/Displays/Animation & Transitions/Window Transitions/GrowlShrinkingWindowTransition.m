//
//  GrowlShrinkingWindowTransition.m
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlShrinkingWindowTransition.h"


@implementation GrowlShrinkingWindowTransition

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)inProgress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				if (scaleFactor < 1.0)
					scaleFactor += inProgress;
				if (scaleFactor > 1.0)
					scaleFactor = 1.0;
				[aWindow setScaleX:scaleFactor Y:scaleFactor];
				break;
			case GrowlReverseTransition:
				if (scaleFactor > 0.0)
					scaleFactor -= inProgress;
				if (scaleFactor < 0.0)
					scaleFactor = 0.0;
				[aWindow setScaleX:scaleFactor Y:scaleFactor];
				break;
			default:
				break;
		}
	}
}

@end
