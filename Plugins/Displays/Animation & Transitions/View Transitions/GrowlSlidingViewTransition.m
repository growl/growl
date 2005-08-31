//
//  GrowlSlidingViewTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 01/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlSlidingViewTransition.h"


@implementation GrowlSlidingViewTransition

- (void) slideFrom:(NSPoint)start to:(NSPoint)end {
	startingPoint = start;
	xDistance = (end.x - start.x);
	yDistance = (end.y - start.y);
	
	//Since we override -startAnimation to do nothing, we need to call super's implementation.
	[super startAnimation];
}

- (void) startAnimation {
	//Do nothing if called directly
}

- (void) drawTransitionWithView:(NSView *)aView progress:(GrowlAnimationProgress)progress {
	NSPoint newOrigion;
	
	newOrigion.x = startingPoint.x + (progress * xDistance);
	newOrigion.y = startingPoint.y + (progress * yDistance);
	
	[aView setBoundsOrigin:newOrigion];
}

@end
