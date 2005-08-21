//
//  GrowlAnimation.h
//  Growl
//
//  Created by Ofri Wolfus on 25/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define FLOAT_EQ(x,y) (((y - FLT_EPSILON) < x) && (x < (y + FLT_EPSILON)))

typedef float GrowlAnimationProgress;

typedef enum {
	GrowlAnimationEaseInOut,
	GrowlAnimationEaseIn,
	GrowlAnimationEaseOut,
	GrowlAnimationLinear
} GrowlAnimationCurve;


@interface GrowlAnimation : NSObject {
	@private
	NSTimer						*animationTimer;
	NSTimeInterval				animationDuration;	//Default to 1 second
	float						frameRate;			//Default to 36 frames per second
	GrowlAnimationProgress		progress;
	unsigned					framesPassed;
	GrowlAnimationCurve			animationCurve;		//Default to GrowlAnimationEaseInOut
	id							delegate;
	BOOL						repeats;
	
	/* Linked Animations */
	GrowlAnimation				*startAnimation;
	GrowlAnimationProgress		startAnimationProgress;
	GrowlAnimation				*stopAnimation;
	GrowlAnimationProgress		stopAnimationProgress;
}

- (id) initWithDuration:(NSTimeInterval)duration animationCurve:(GrowlAnimationCurve)curve;

- (void) startAnimation;
- (void) startWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)startProgress;

- (void) stopAnimation;
- (void) stopWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)stopProgress;

- (BOOL) isAnimating;

- (void) drawFrame:(GrowlAnimationProgress)progress;	//Override this in your subclass in order to draw your animation.

- (BOOL) repeats;
- (void) setRepeats:(BOOL)value;

- (GrowlAnimationProgress) currentProgress;
- (void) setCurrentProgress:(GrowlAnimationProgress)value;

- (GrowlAnimationCurve) animationCurve;
- (void) setAnimationCurve:(GrowlAnimationCurve)curve;

- (NSTimeInterval) duration;
- (void) setDuration:(NSTimeInterval)duration;

- (float) frameRate;
- (void) setFrameRate:(float)value;

- (id) delegate;
- (void) setDelegate:(id)newDelegate;

@end

@interface NSObject (GrowlAnimationDelegate)
- (BOOL) growlAnimationShouldStart:(GrowlAnimation *)animation;
- (void) growlAnimationDidStop:(GrowlAnimation *)animation;
- (void) growlAnimationDidEnd:(GrowlAnimation *)animation;
- (float) growlAnimation:(GrowlAnimation *)animation valueForProgress:(GrowlAnimationProgress)progress;
@end
