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

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress {
	NSPoint newOrigin;
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				newOrigin.x = startingPoint.x + (progress * xDistance);
				newOrigin.y = startingPoint.y + (progress * yDistance);

				[aWindow setFrameOrigin:newOrigin];
				break;
				
			case GrowlReverseTransition:
				newOrigin.x = endingPoint.x - (progress * xDistance);
				newOrigin.y = endingPoint.y - (progress * yDistance);

				[aWindow setFrameOrigin:newOrigin];
				break;
			default:
				break;
		}
	}
}

@end
