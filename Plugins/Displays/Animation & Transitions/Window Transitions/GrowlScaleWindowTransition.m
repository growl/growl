//
//  GrowlScaleWindowTransition.m
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlScaleWindowTransition.h"

#include <float.h>

@implementation GrowlScaleWindowTransition

- (id) initWithDuration:(NSTimeInterval)duration animationCurve:(GrowlAnimationCurve)curve {
	if((self = [self initWithDuration:duration animationCurve:curve])) {
		[self setFrameRate:(1.0 / duration)];
	}
	return self;
}

- (void) setFromOrigin:(NSPoint)from toOrigin:(NSPoint)to {
	startingPoint = from;
	endingPoint   = to;
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)inProgress {
	if (aWindow) {
		NSRect newFrame = [aWindow frame];
		if (inProgress < FLT_EPSILON) 
			[self setFrameRate:(1.0 / [aWindow animationResizeTime:newFrame])];

		float deltaX = inProgress * (endingPoint.x - startingPoint.x);
		float deltaY = inProgress * (endingPoint.y - startingPoint.y);

		switch (direction) {
			default:
			case GrowlForwardTransition:
				newFrame.size.width  = startingPoint.x + deltaX;
				newFrame.size.height = startingPoint.y + deltaY;
				break;
			case GrowlReverseTransition:
				newFrame.size.width  = endingPoint.x - deltaX;
				newFrame.size.height = endingPoint.y - deltaY;
				break;
		}

		[aWindow setFrame:newFrame display:YES animate:YES];
		[aWindow setViewsNeedDisplay:YES];
	}
}

@end
