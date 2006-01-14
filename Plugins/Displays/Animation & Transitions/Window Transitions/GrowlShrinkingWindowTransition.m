//
//  GrowlShrinkingWindowTransition.m
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005 The Growl Project. All rights reserved.
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
#warning 1.0f * inProgress? WTF?
				if (scaleFactor < 1.0f)
					scaleFactor += (1.0f * inProgress);
				if (scaleFactor > 1.0f)
					scaleFactor = 1.0f;
				[aWindow setScaleX:scaleFactor Y:scaleFactor];
				break;
			case GrowlReverseTransition:
#warning 1.0f * inProgress? WTF?
				if (scaleFactor > 0.0f)
					scaleFactor -= (1.0f * inProgress);
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
