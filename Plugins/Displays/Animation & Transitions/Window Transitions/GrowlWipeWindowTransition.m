//
//  GrowlWipeWindowTransition.m
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWipeWindowTransition.h"


@implementation GrowlWipeWindowTransition

- (id) initWithWindow:(NSWindow *)inWindow {
	self = [super initWithWindow:inWindow];
	if (!self)
		return nil;
	return self;
}

- (void) setFromOrigin:(NSPoint)from toOrigin:(NSPoint)to {
	startingPoint = from;
	endingPoint = to;
	xDistance = (to.x - from.x);
	yDistance = (to.y - from.y);
	
	NSLog(@"%f %f\n", xDistance, yDistance);
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress {
	NSSize newSize;
	NSRect newFrame = [aWindow frame];
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				newSize.width = startingPoint.x + (progress * xDistance);
				newSize.height = startingPoint.y + (progress * yDistance);
				
				break;
			case GrowlReverseTransition:
				newSize.width = endingPoint.x - (progress * xDistance);
				newSize.height = endingPoint.y - (progress * yDistance);

				break;
			default:
				break;
		}
		newFrame.size.height = newSize.height;
		newFrame.size.width = newSize.width;
		
		[aWindow setFrame:newFrame display:YES];
		[aWindow setViewsNeedDisplay:YES];
	}
}

@end
