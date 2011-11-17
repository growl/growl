//
//  GrowlWipeWindowTransition.m
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlWipeWindowTransition.h"


@implementation GrowlWipeWindowTransition

- (void) setFromOrigin:(NSPoint)from toOrigin:(NSPoint)to {
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)progress {
	if (aWindow) {
		switch (direction) {
			default:
			case GrowlForwardTransition:
				break;
			case GrowlReverseTransition:
				break;
		}
	}
}

@end
