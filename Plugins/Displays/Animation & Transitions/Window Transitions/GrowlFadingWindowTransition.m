//
//  GrowlFadingWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlFadingWindowTransition.h"

@implementation GrowlFadingWindowTransition

#pragma mark -

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)inProgress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				[aWindow setAlphaValue:inProgress];
				break;
			case GrowlReverseTransition:
				[aWindow setAlphaValue:(1.0 - inProgress)];
				break;
			default:
				break;
		}
	}
}

@end
