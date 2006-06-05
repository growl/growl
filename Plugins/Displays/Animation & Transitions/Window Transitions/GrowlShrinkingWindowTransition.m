//
//  GrowlShrinkingWindowTransition.m
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlShrinkingWindowTransition.h"
#import "NSWindow+Transforms.h"


@implementation GrowlShrinkingWindowTransition

- (void) reset {
	//scaleFactor = 1.0f;
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)inProgress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				if (scaleFactor < 1.0f)
					scaleFactor += inProgress;
				if (scaleFactor > 1.0f)
					scaleFactor = 1.0f;
				[aWindow setScaleX:scaleFactor Y:scaleFactor];
				break;
			case GrowlReverseTransition:
				if (scaleFactor > 0.0f)
					scaleFactor -= inProgress;
				if (scaleFactor < 0.0f)
					scaleFactor = 0.0f;
				[aWindow setScaleX:scaleFactor Y:scaleFactor];
				break;
			default:
				break;
		}
	}
}

@end
