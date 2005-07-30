//
//  GrowlAnimation.m
//  Growl
//
//  Created by Ofri Wolfus on 25/07/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlAnimation.h"

@interface GrowlAnimation (private)
- (void) _doAnimationStep;

- (void) _setStartAnimation:(GrowlAnimation *)animation;
- (void) _setStartAnimationProgress:(GrowlAnimationProgress)animationProgress;

- (void) _setStopAnimation:(GrowlAnimation *)animation;
- (void) _setStopAnimationProgress:(GrowlAnimationProgress)animationProgress;
@end

@implementation GrowlAnimation

- (id) init {
	self = [super init];
	
	if (self) {
		animationTimer = nil;
		animationDuration = 1.0;
		frameRate = 36.0;
		progress = 0.0;
		framesPassed = 0.0;
		animationCurve = GrowlAnimationEaseInOut;
		delegate = nil;
		startAnimation = nil;
		startAnimationProgress = -1.0;
		stopAnimation = nil;
		stopAnimationProgress = -1.0;
		repeats = NO;
	}
	
	return self;
}

- (id) initWithDuration:(NSTimeInterval)duration animationCurve:(GrowlAnimationCurve)curve {
	self = [self init];
	
	if (self) {
		animationDuration = duration;
		animationCurve = curve;
	}
	
	return self;
}

- (void) drawFrame:(GrowlAnimationProgress)progress {
#pragma unused(progress)
	//Override this in your subclass in order to draw your animation.
}

#pragma mark -

- (void) startAnimation {
	BOOL shouldStart = YES;
	
	//Ask for permission to start from our delegate
	if (delegate)
		shouldStart = [delegate growlAnimationShouldStart:self];
	
	if (shouldStart) {
		//Clear any running timers
		[self stopAnimation];
		
		//Reset our progress
		progress = 0.0;
		framesPassed = 0;
		
		//Create a new timer
		animationTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0/frameRate)
														  target:self
														selector:@selector(_doAnimationStep)
														userInfo:nil
														 repeats:YES];
	}
}

- (void) startWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)startProgress {
	//It's their job to let us know when to start!
	[animation _setStartAnimation:self];
	[animation _setStartAnimationProgress:startProgress];
}

#pragma mark -

- (void) stopAnimation {
	if ([self isAnimating]) {
		[animationTimer invalidate];
		animationTimer = nil;
		
		//Let our delegate know what's going on
		if (progress < 1.0)
			[delegate growlAnimationDidStop:self];
		else {
			[delegate growlAnimationDidEnd:self];
			if (repeats)
				[self startAnimation];
		}
	}
}

- (void) stopWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)stopProgress {
	//They will let us know when to stop when time comes...
	[animation _setStopAnimation:self];
	[animation _setStopAnimationProgress:stopProgress];
}

#pragma mark -

- (BOOL) isAnimating {
	return (animationTimer && [animationTimer isValid]);
}

//===============================================================================//
//===============================================================================//
//===============================================================================//
#pragma mark -
#pragma mark Accessors

- (GrowlAnimationProgress) currentProgress {
	return progress;
}

- (void) setCurrentProgress:(GrowlAnimationProgress)value {
	if (value < 0.0)
		progress = 0.0;
	else if (value > 1.0)
		progress = 1.0;
	else
		progress = value;
}

#pragma mark -

- (GrowlAnimationCurve) animationCurve {
	return animationCurve;
}

- (void )setAnimationCurve:(GrowlAnimationCurve)curve {
	animationCurve = curve;
}

#pragma mark -

- (NSTimeInterval) duration {
	return animationDuration;
}

- (void) setDuration:(NSTimeInterval)duration {
	animationDuration = duration;
}

#pragma mark -

- (float) frameRate {
	return frameRate;
}

- (void) setFrameRate:(float)value {
	frameRate = value;
}

#pragma mark -

- (id) delegate {
	return delegate;
}

- (void) setDelegate:(id)newDelegate {
	delegate = newDelegate;
}

#pragma mark -

- (BOOL) repeats {
	return repeats;
}

- (void) setRepeats:(BOOL)value {
	repeats = value;
}

//===============================================================================//
//===============================================================================//
//===============================================================================//
#pragma mark -
#pragma mark Private

- (void) _setStartAnimation:(GrowlAnimation *)animation {
	startAnimation = animation;
}

- (void) _setStartAnimationProgress:(GrowlAnimationProgress)animationProgress {
	startAnimationProgress = animationProgress;
}

#pragma mark -

- (void) _setStopAnimation:(GrowlAnimation *)animation {
	stopAnimation = animation;
}

- (void) _setStopAnimationProgress:(GrowlAnimationProgress)animationProgress {
	stopAnimationProgress = animationProgress;
}

#pragma mark -

- (void) _doAnimationStep {
	//The delegate may want to change our progress
	if (delegate)
		progress = [delegate growlAnimation:self valueForProgress:progress];
	
	//Draw the animation
	[self drawFrame:progress];
	
	//Support for linked animations
	if (startAnimation && progress == startAnimationProgress)
		[startAnimation startAnimation];
	
	if (stopAnimation && progress == stopAnimationProgress)
		[stopAnimation stopAnimation];
	
	//Update our progress
	if (progress >= 1.0) {
		progress = 1.0;
		[self stopAnimation];
	} else {
		float completedPercentage;
		
		++framesPassed;
		
		completedPercentage = (framesPassed / (frameRate*animationDuration));
		
		switch (animationCurve) {
			case GrowlAnimationLinear:
				progress = completedPercentage;
				break;
			case GrowlAnimationEaseInOut:
				//y=sin(x*pi)
				progress = sinf(completedPercentage * M_PI);
				break;
			case GrowlAnimationEaseOut:
				//y=x^2
				progress = powf(completedPercentage, 2.0);
				break;
			case GrowlAnimationEaseIn:
				//y=-x^2+2x
				progress = -powf(completedPercentage, 2.0);
				progress += 2.0 * completedPercentage;
				break;
			default:
				break;
		}
	}
}

@end

#pragma mark -

@implementation NSObject (GrowlAnimationDelegate)

- (BOOL) growlAnimationShouldStart:(GrowlAnimation *)animation {
#pragma unused(animation)
	return YES;
}

- (void) growlAnimationDidStop:(GrowlAnimation *)animation {
#pragma unused(animation)
}

- (void) growlAnimationDidEnd:(GrowlAnimation *)animation {
#pragma unused(animation)
}

- (float) growlAnimation:(GrowlAnimation *)animation valueForProgress:(GrowlAnimationProgress)progress {
#pragma unused(animation)
	return progress;
}

@end
