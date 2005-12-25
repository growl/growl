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

- (id) initWithWindow:(NSWindow *)inWindow {
	self = [super initWithWindow:inWindow];
	if (!self)
		return nil;
	
	scaleFactor = 0.0f;	
	return self;
}

- (void) reset {
	//scaleFactor = 1.0f;
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)inProgress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				if(scaleFactor < 1.0f) {
					scaleFactor += (1.0f * inProgress);
					[aWindow setScaleX:(scaleFactor < 1.0f ? scaleFactor : 1.0) Y:(scaleFactor < 1.0f ? scaleFactor : 1.0)];
				} else {
					scaleFactor = 1.0f;
					[aWindow setScaleX:scaleFactor Y:scaleFactor];
				}
				break;
			case GrowlReverseTransition:
				NSLog(@"%f\n", scaleFactor);
				if(scaleFactor > 0.0f) {
					scaleFactor -= (1.0f * inProgress);
					[aWindow setScaleX:(scaleFactor > 0.0f ? scaleFactor : 0.0) Y:(scaleFactor > 0.0f ? scaleFactor : 0.0)];
				} else {
					scaleFactor = 0.0f;
					[aWindow setScaleX:scaleFactor Y:scaleFactor];
				}
				break;
			default:
				break;
		}
	}
}

@end
