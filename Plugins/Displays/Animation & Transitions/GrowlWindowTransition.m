//
//  GrowlWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlWindowTransition.h"

@implementation GrowlWindowTransition

- (id) initWithWindow:(NSWindow *)inWindow {
	return [self initWithWindow:inWindow direction:GrowlForwardTransition];
}

- (id) initWithWindow:(NSWindow *)inWindow direction:(GrowlTransitionDirection)theDirection {
	if ((self = [self init])) {
		[self setWindow:inWindow];
		[self setDirection:theDirection];
		[self setDelegate:self];
	}

	return self;
}

//Only start if we have a window
- (void) startAnimation {
	if (!window)
		NSLog(@"Trying to start window transition with no window. Transition: %@", self);
	[super startAnimation];
}

- (void) stopAnimation {
	if (!window)
		NSLog(@"Trying to stop window transition with no window. Transition: %@", self);

	[super stopAnimation];
}

- (void) animationDidEnd:(NSAnimation *)animation {
	if (autoReverses) {
		[self retain];
		[self setDirection:![self direction]];
		didAutoReverse = !didAutoReverse;
		[self release];
	}
}

- (BOOL) autoReverses {
	return autoReverses;
}

- (void) setAutoReverses: (BOOL) flag {
	autoReverses = flag;
}

- (GrowlTransitionDirection) direction {
	return direction;
}

- (void) setDirection: (GrowlTransitionDirection) theDirection {
    direction = theDirection;
}

- (NSWindow *) window {
	return window;
}

- (void) setWindow:(NSWindow *)inWindow {
	if (inWindow != window) {
		[window release];
		window = [inWindow retain];
	}
}

- (void) dealloc {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self setDelegate:nil];	//Remove the delegate from the notification center
	[window release];
	[pool release];

	[super dealloc];
}

- (void) setCurrentProgress:(NSAnimationProgress)progress {
	[self drawTransitionWithWindow:window progress:progress];
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)progress {
#pragma unused(aWindow, progress)
	//
}

- (void) reset
{
	[self setCurrentProgress:0.0];
	
	//If we autoreversed, reset to our original direction
	if (autoReverses && didAutoReverse) {
		[self setDirection:![self direction]];
		didAutoReverse = NO;
	}
}

- (void) reverse
{
	[self setDirection:![self direction]];
	[self setCurrentProgress:(1.0 - [self currentProgress])];

	didAutoReverse = !didAutoReverse;
}

@end
