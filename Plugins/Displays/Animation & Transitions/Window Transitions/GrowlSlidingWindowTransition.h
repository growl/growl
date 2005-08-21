//
//  GrowlSlidingWindowTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 21/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlWindowTransition.h"

@interface GrowlSlidingWindowTransition : GrowlWindowTransition {
	NSPoint	startingPoint;
	float	xDistance;
	float	yDistance;
}

- (void) slideFromOrigin:(NSPoint)startingOrigin toOrigin:(NSPoint)endingOrigin;
- (void) slideToOrigin:(NSPoint)endingOrigin;

@end
