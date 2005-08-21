//
//  GrowlFadingWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlFadingWindowTransition.h"

#define FLOAT_EQ(x,y) (((y - FLT_EPSILON) < x) && (x < (y + FLT_EPSILON)))

@implementation GrowlFadingWindowTransition

- (id) init {
	self = [super init];
	
	if (self) {
		fadeAction = GrowlNoFadeAction;	//We don't animate if someone simply sends us -startAnimation
		defaultAction = GrowlNoFadeAction;
	}
	
	return self;
}

- (id) initWithWindow:(NSWindow *)inWindow defaultAction:(GrowlFadeAction)action {
	self = [super initWithWindow:inWindow];
	
	if (self) {
		fadeAction = GrowlNoFadeAction;
		defaultAction = action;
	}
	
	return self;
}

- (void) dealloc {
	[self setDelegate:nil];	//Remove the delegate from the notification center
	[super dealloc];
}

#pragma mark -

- (void) startAnimation {
	switch (defaultAction) {
		case GrowlFadeIn:
			[self startFadeIn];
			break;
		case GrowlFadeOut:
			[self startFadeOut];
			break;
		default:
			break;
	}
}
			

- (void) startFadeIn {
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlFadeInWindowTransitionWillStart
														object:self];
	fadeAction = GrowlFadeIn;
	[super startAnimation];
}

- (void) startFadeOut {
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlFadeOutWindowTransitionWillStart
														object:self];
	fadeAction = GrowlFadeOut;
	[super startAnimation];
}

- (void) stopAnimation {
	[super stopAnimation];
	
	//Notify our delegate
	if (FLOAT_EQ([self currentProgress], 1.0f)) {
		switch (fadeAction) {
			case GrowlFadeIn:
				[[NSNotificationCenter defaultCenter] postNotificationName:GrowlFadeInWindowTransitionDidEnd
																	object:self];
				break;
			case GrowlFadeOut:
				[[NSNotificationCenter defaultCenter] postNotificationName:GrowlFadeOutWindowTransitionDidEnd
																	object:self];
				break;
			default:
				break;
		}
	}
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

- (void) setDelegate:(id)newDelegate {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	id oldDelegate = [self delegate];
	
	if (oldDelegate) {
		[nc removeObserver:oldDelegate
					  name:GrowlFadeInWindowTransitionWillStart
					object:self];
		[nc removeObserver:oldDelegate
					  name:GrowlFadeInWindowTransitionDidEnd
					object:self];
		[nc removeObserver:oldDelegate
					  name:GrowlFadeOutWindowTransitionWillStart
					object:self];
		[nc removeObserver:oldDelegate
					  name:GrowlFadeOutWindowTransitionDidEnd
					object:self];
	}
	
	if (newDelegate) {
		[nc addObserver:newDelegate
			   selector:@selector(fadeInWindowTransitionWillStart:)
				   name:GrowlFadeInWindowTransitionWillStart
				 object:self];
		[nc addObserver:newDelegate
			   selector:@selector(fadeInWindowTransitionDidEnd:)
				   name:GrowlFadeInWindowTransitionDidEnd
				 object:self];
		[nc addObserver:newDelegate
			   selector:@selector(fadeOutWindowTransitionWillStart:)
				   name:GrowlFadeOutWindowTransitionWillStart
				 object:self];
		[nc addObserver:newDelegate
			   selector:@selector(fadeOutWindowTransitionDidEnd:)
				   name:GrowlFadeOutWindowTransitionDidEnd
				 object:self];
	}
	
	[super setDelegate:newDelegate];
}

#pragma mark -

- (GrowlFadeAction) defaultAction {
	return defaultAction;
}

- (void) setDefaultAction:(GrowlFadeAction)action {
	defaultAction = action;
}

@end

#pragma mark -
@implementation NSObject (GrowlFadingWindowTransitionDelegate)
- (void) fadeInWindowTransitionWillStart:(GrowlFadingWindowTransition *)fadingWindowTransition {
#pragma unused(fadingWindowTransition)
}

- (void) fadeInWindowTransitionDidEnd:(GrowlFadingWindowTransition *)fadingWindowTransition {
#pragma unused(fadingWindowTransition)
}

- (void) fadeOutWindowTransitionWillStart:(GrowlFadingWindowTransition *)fadingWindowTransition {
#pragma unused(fadingWindowTransition)
}

- (void) fadeOutWindowTransitionDidEnd:(GrowlFadingWindowTransition *)fadingWindowTransition {
#pragma unused(fadingWindowTransition)
}
@end
