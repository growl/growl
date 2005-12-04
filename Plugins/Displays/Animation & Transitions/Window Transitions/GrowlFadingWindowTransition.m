//
//  GrowlFadingWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlFadingWindowTransition.h"

@implementation GrowlFadingWindowTransition

- (void) reset {
	[[self window] setAlphaValue:1.0];
}

#pragma mark -

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				[aWindow setAlphaValue:progress];
				break;
			case GrowlReverseTransition:
				[aWindow setAlphaValue:(1.0 - progress)];
				break;
			default:
				break;
		}
	}
}

@end
