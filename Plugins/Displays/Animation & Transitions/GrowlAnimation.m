//
//  GrowlAnimation.m
//  Growl
//
//  Created by Ofri Wolfus on 25/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlAnimation.h"

extern CFRunLoopRef CFRunLoopGetMain(void);

@interface GrowlAnimation (private)
- (void) doAnimationStep;

- (void) setStartAnimation:(GrowlAnimation *)animation;
- (void) setStartAnimationProgress:(GrowlAnimationProgress)animationProgress;

- (void) setStopAnimation:(GrowlAnimation *)animation;
- (void) setStopAnimationProgress:(GrowlAnimationProgress)animationProgress;
@end

static void animationStep(CFRunLoopTimerRef timer, void *context) {
#pragma unused(timer)
	[(GrowlAnimation *)context doAnimationStep];
}

@implementation GrowlAnimation

- (id) init {
	if ((self = [super init])) {
		animationDuration = 1.0;
		frameRate = 36.0f;
		progress = 0.0f;
		framesPassed = 0U;
		animationCurve = GrowlAnimationEaseInOut;
		startAnimationProgress = -1.0f;
		stopAnimationProgress = -1.0f;
		repeats = NO;
		passedMiddleOfAnimation = NO;
	}

	return self;
}

- (id) initWithDuration:(NSTimeInterval)duration animationCurve:(GrowlAnimationCurve)curve {
	if ((self = [self init])) {
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
		progress = 0.0f;
		framesPassed = 0U;
		passedMiddleOfAnimation = NO;

		//Create a new timer
		CFRunLoopTimerContext context = {0, self, NULL, NULL, NULL};
		animationTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+(1.0f/frameRate), (1.0f/frameRate), 0, 0, &animationStep, &context);
		CFRunLoopAddTimer(CFRunLoopGetMain(), animationTimer, kCFRunLoopCommonModes);

		//animationTimer = CFRunLoopTimerCreate() [NSTimer scheduledTimerWithTimeInterval:(1.0f/frameRate)
		//												  target:self
		//												selector:@selector(doAnimationStep)
		//												userInfo:nil
		//												 repeats:YES];
	}
}

- (void) startWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)startProgress {
	//It's their job to let us know when to start!
	[animation setStartAnimation:self];
	[animation setStartAnimationProgress:startProgress];
}

#pragma mark -

- (void) stopAnimation {
	if ([self isAnimating]) {
		if (animationTimer) {
			CFRunLoopTimerInvalidate(animationTimer);
			CFRelease(animationTimer);
			animationTimer = NULL;
		}

		//Let our delegate know what's going on
		if (progress < 1.0f)
			[self animationDidStop];
		else {
			[self animationDidEnd];
			if (repeats)
				[self startAnimation];
		}
	}
}

- (void) stopWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)stopProgress {
	//They will let us know when to stop when time comes...
	[animation setStopAnimation:self];
	[animation setStopAnimationProgress:stopProgress];
}

#pragma mark -

- (BOOL) isAnimating {
	return (animationTimer && CFRunLoopTimerIsValid(animationTimer));
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
	if (value < 0.0f)
		progress = 0.0f;
	else if (value > 1.0f)
		progress = 1.0f;
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

#pragma mark -

- (unsigned) framesPassed {
	return framesPassed;
}

//===============================================================================//
//===============================================================================//
//===============================================================================//
#pragma mark -
#pragma mark Private

- (void) setStartAnimation:(GrowlAnimation *)animation {
	startAnimation = animation;
}

- (void) setStartAnimationProgress:(GrowlAnimationProgress)animationProgress {
	startAnimationProgress = animationProgress;
}

#pragma mark -

- (void) setStopAnimation:(GrowlAnimation *)animation {
	stopAnimation = animation;
}

- (void) setStopAnimationProgress:(GrowlAnimationProgress)animationProgress {
	stopAnimationProgress = animationProgress;
}

#pragma mark -

- (void) doAnimationStep {
	//The delegate may want to change our progress
	if (delegate)
		progress = [delegate growlAnimation:self valueForProgress:progress];

	//Draw the animation
	[self drawFrame:progress];

	//Support for linked animations
	if (startAnimation && FLOAT_EQ(progress, startAnimationProgress))
		[startAnimation startAnimation];

	if (stopAnimation && FLOAT_EQ(progress, stopAnimationProgress))
		[stopAnimation stopAnimation];

	//Update our progress
	if (FLOAT_EQ(progress, 1.0f)) {
		progress = 1.0f;
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
				progress = completedPercentage * completedPercentage;
				break;
			case GrowlAnimationEaseIn:
				//y=-x^2+2x
				progress = -(completedPercentage * completedPercentage);
				progress += 2.0f * completedPercentage;
				break;
			default:
				break;
		}

		//If we're in the middle we should notify our delegate about it
		if (!passedMiddleOfAnimation && (progress >= 0.5) && delegate) {
			[self animationIsInMiddle];
			passedMiddleOfAnimation = YES;
		}
	}
}

- (void) animationIsInMiddle {
	[delegate growlAnimationIsInMiddle:self];
}

- (void) animationDidStop {
	[delegate growlAnimationDidStop:self];
}

- (void) animationDidEnd {
	[delegate growlAnimationDidEnd:self];
}

@end

#pragma mark -

@implementation NSObject (GrowlAnimationDelegate)

- (BOOL) growlAnimationShouldStart:(GrowlAnimation *)animation {
#pragma unused(animation)
	return YES;
}

- (void) growlAnimationIsInMiddle:(GrowlAnimation *)animation {
#pragma unused(animation)
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
