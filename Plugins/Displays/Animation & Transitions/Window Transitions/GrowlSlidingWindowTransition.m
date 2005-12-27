//
//  GrowlSlidingWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 21/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlSlidingWindowTransition.h"

@implementation GrowlSlidingWindowTransition

- (void) setFromOrigin:(NSPoint)startingOrigin toOrigin:(NSPoint)endingOrigin {
	startingPoint = startingOrigin;
	endingPoint = endingOrigin;
	xDistance = (endingOrigin.x - startingOrigin.x);
	yDistance = (endingOrigin.y - startingOrigin.y);
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)inProgress {
	NSPoint newOrigin;
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				newOrigin.x = startingPoint.x + (inProgress * xDistance);
				newOrigin.y = startingPoint.y + (inProgress * yDistance);

				[aWindow setFrameOrigin:newOrigin];
				break;

			case GrowlReverseTransition:
				newOrigin.x = endingPoint.x - (inProgress * xDistance);
				newOrigin.y = endingPoint.y - (inProgress * yDistance);

				[aWindow setFrameOrigin:newOrigin];
				break;
			default:
				break;
		}
	}
}

@end
