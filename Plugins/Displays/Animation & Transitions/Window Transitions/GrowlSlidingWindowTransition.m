//
//  GrowlSlidingWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 21/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlSlidingWindowTransition.h"

@implementation GrowlSlidingWindowTransition

- (void) slideFromOrigin:(NSPoint)startingOrigin toOrigin:(NSPoint)endingOrigin {
	startingPoint = startingOrigin;
	xDistance = (endingOrigin.x - startingOrigin.x);
	yDistance = (endingOrigin.y - startingOrigin.y);
	
	//Since we override -startAnimation to do nothing, we need to call super's implementation.
	[super startAnimation];
}

- (void) slideToOrigin:(NSPoint)endingOrigin {
	[self slideFromOrigin:[[self window] frame].origin toOrigin:endingOrigin];
}

- (void) startAnimation {
	//Do nothing if called directly
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress {
	NSPoint newOrigion;
	
	newOrigion.x = startingPoint.x + (progress * xDistance);
	newOrigion.y = startingPoint.y + (progress * yDistance);
	
	[aWindow setFrameOrigin:newOrigion];
}

@end
