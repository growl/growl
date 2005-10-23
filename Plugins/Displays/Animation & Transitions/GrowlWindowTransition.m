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

//Only start if we have a window
- (void) startAnimation {
	if (!window)
		NSLog(@"Trying to start window transition with no window. Transition: %@", self);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlWindowTransitionWillStart
															object:self];
	[super startAnimation];
}

- (void) stopAnimation {
	if (!window)
		NSLog(@"Trying to stop window transition with no window. Transition: %@", self);
	
	[super stopAnimation];
	
	if (!FLOAT_EQ([self currentProgress], 1.0f))
		[[NSNotificationCenter defaultCenter] postNotificationName:GrowlWindowTransitionDidEnd
															object:self];
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
	[self setDelegate:nil];	//Remove the delegate from the notification center
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

- (void) setDelegate:(id)newDelegate {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	id oldDelegate = [self delegate];
	
	if (oldDelegate) {
		[nc removeObserver:oldDelegate
					  name:GrowlWindowTransitionWillStart
					object:self];
		[nc removeObserver:oldDelegate
					  name:GrowlWindowTransitionDidEnd
					object:self];
	}
	
	if (newDelegate) {
		[nc addObserver:newDelegate
			   selector:@selector(windowTransitionWillStart:)
				   name:GrowlWindowTransitionWillStart
				 object:self];
		[nc addObserver:newDelegate
			   selector:@selector(windowTransitionDidEnd:)
				   name:GrowlWindowTransitionDidEnd
				 object:self];
	}
	
	[super setDelegate:newDelegate];
}

@end

#pragma mark -
@implementation NSObject (GrowlWindowTransitionDelegate)
- (void) windowTransitionWillStart:(GrowlWindowTransition *)windowTransition {
#pragma unused(windowTransition)
}

- (void) windowTransitionDidEnd:(GrowlWindowTransition *)windowTransition {
#pragma unused(windowTransition)
}
@end
