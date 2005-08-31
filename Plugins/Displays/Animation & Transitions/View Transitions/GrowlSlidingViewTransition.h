//
//  GrowlSlidingViewTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 01/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlViewTransition.h"


@interface GrowlSlidingViewTransition : GrowlViewTransition {
	NSPoint	startingPoint;
	float	xDistance;
	float	yDistance;
}

- (void) slideFrom:(NSPoint)start to:(NSPoint)end;

@end
