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

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				break;
				
			case GrowlReverseTransition:
				break;
			default:
				break;
		}
	}
}

@end
