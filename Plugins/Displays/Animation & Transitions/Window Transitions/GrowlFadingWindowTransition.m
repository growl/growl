//
//  GrowlFadingWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlFadingWindowTransition.h"

@implementation GrowlFadingWindowTransition

- (id) init {
	self = [super init];

	if (self) {
		fadeAction = GrowlNoFadeAction;	//We don't animate if someone simply sends us -startAnimation
	}

	return self;
}

- (id) initWithWindow:(NSWindow *)inWindow action:(GrowlFadeAction)action {
	self = [super initWithWindow:inWindow];

	if (self) {
		fadeAction = action;
	}

	return self;
}

#pragma mark -

- (void) startAnimation {
	if (fadeAction == GrowlNoFadeAction)
		return;

	[super startAnimation];
}

- (void) stopAnimation {
	if (fadeAction == GrowlNoFadeAction)
		return;
	
	[super stopAnimation];
}

- (void) reset {
	[[self window] setAlphaValue:1.0];
}

#pragma mark -

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress {
	if (aWindow) {
		switch (fadeAction) {
			case GrowlFadeIn:
				[aWindow setAlphaValue:progress];
				break;
			case GrowlFadeOut:
				[aWindow setAlphaValue:(1.0 - progress)];
				break;
			default:
				break;
		}
	}
}

#pragma mark -

- (GrowlFadeAction) fadeAction
{
    return fadeAction;
}

- (void) setFadeAction: (GrowlFadeAction) theFadeAction
{
	fadeAction = theFadeAction;
}

@end
