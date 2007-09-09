//
//  GrowlSlidingWindowTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 21/08/05.
//  Copyright 2005-2006 Ofri Wolfus. All rights reserved.
//

#import "GrowlWindowTransition.h"

@interface GrowlSlidingWindowTransition : GrowlWindowTransition {
	NSPoint	startingPoint;
	NSPoint endingPoint;
	float	xDistance;
	float	yDistance;
}

- (void) setFromOrigin:(NSPoint)startingOrigin toOrigin:(NSPoint)endingOrigin;
- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)progress;

@end
