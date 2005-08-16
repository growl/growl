//
//  GrowlWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWindowTransition.h"

@implementation GrowlWindowTransition

- (id) initWithWindow:(NSWindow *)inWindow {
	if ((self = [super init])) {
		[self setWindow:inWindow];
	}

	return self;
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
	[window release];
	[super dealloc];
}

- (void) drawFrame:(GrowlAnimationProgress)progress {
	[self drawTransitionWithWindow:window progress:progress];
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress {
#pragma unused(aWindow, progress)
	//
}

@end
