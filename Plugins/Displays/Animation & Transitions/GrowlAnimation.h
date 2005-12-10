//
//  GrowlAnimation.h
//  Growl
//
//  Created by Ofri Wolfus on 25/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!
 * @header GrowlAnimation
 * GrowlAnimation manages the timing and progress of animations.
 * @copyright Created by Ofri Wolfus on 31/08/05. Copyright 2004-2005 The Growl Project. All rights reserved.
 * @updated 2005-10-1
 * @version 0.8
 */


/*!
 * @definded FLOAT_EQ(x,y)
 * @abstract Compares two floats.
 */
#define FLOAT_EQ(x,y) (((y - FLT_EPSILON) < x) && (x < (y + FLT_EPSILON)))

/*!
 * @typedef GrowlAnimationProgress
 * @abstract GrowlAnimationProgress represents the progress of GrowlAnimation.
 */
typedef float GrowlAnimationProgress;

/*!
 * @typedef GrowlAnimationCurve
 * @abstract GrowlAnimationCurve is analogous to NSAnimationCurve. Please refer to NSAnimationCurve docs for more information.
 * @constant GrowlAnimationEaseInOut Analogous to NSAnimationEaseInOut. GrowlAnimationEaseInOut is the default curve of GrowlAnimation.
 * @constant GrowlAnimationEaseIn Analogous to NSAAnimationEaseIn.
 * @constant GrowlAnimationEaseOut Analogous to NSAnimationEaseOut.
 * @constant GrowlAnimationLinear Analogous to NSAnimationLinear.
 */
typedef enum {
	GrowlAnimationEaseInOut,
	GrowlAnimationEaseIn,
	GrowlAnimationEaseOut,
	GrowlAnimationLinear
} GrowlAnimationCurve;


/*!
 * @class GrowlAnimation
 * @abstract GrowlAnimation manages the timing and progress of animations.
 *
 * @disscussion GrowlAnimation manages the timing and progress of animations.
 * GrowlAnimation also lets you link together multiple animations so that when one animation ends another one starts.
 * Unlike NSAnimation, GrowlAnimation does provide a method that subclass should override in order to draw.
 * GrowlAnimation will be replaced with NSAnimation when 10.3 support is dropped.
 */
@interface GrowlAnimation : NSObject {
	@private
	CFRunLoopTimerRef			animationTimer;
	NSTimeInterval				animationDuration;	//Default to 1 second
	float						frameRate;			//Default to 36 frames per second
	GrowlAnimationProgress		progress;
	unsigned					framesPassed;
	GrowlAnimationCurve			animationCurve;		//Default to GrowlAnimationEaseInOut
	id							delegate;
	BOOL						repeats;
	BOOL						passedMiddleOfAnimation;

	/* Linked Animations */
	GrowlAnimation				*startAnimation;
	GrowlAnimationProgress		startAnimationProgress;
	GrowlAnimation				*stopAnimation;
	GrowlAnimationProgress		stopAnimationProgress;
}

/*!
 * @method initWithDuration:animationCurve:
 * @abstract Designated initializer for GrowlAnimation.
 * @param duration The duration of the animation.
 * @param curve The curve of the animation.
 * @result An initialized GrowlAnimation object.
 */
- (id) initWithDuration:(NSTimeInterval)duration animationCurve:(GrowlAnimationCurve)curve;

/*!
 * @method startAnimation
 * @abstract Starts the animation of the receiver.
 */
- (void) startAnimation;

/*!
 * @method startWhenAnimation:reachesProgress:
 * @abstract Make the receiver automatically start it's animation when animation reaches startProgress.
 * @param animation The animation to observe.
 * @param startProgress The progress of animation on which the receiver should start it's own animation.
 */
- (void) startWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)startProgress;


/*!
 * @method stopAnimation
 * @abstract Stops the animation of the receiver.
 */
- (void) stopAnimation;

/*!
 * @method stopWhenAnimation:reachesProgress:
 * @abstract Make the receiver automatically stop it's animation when animation reaches stopProgress.
 * @param animation The animation to observe.
 * @param stopProgress The progress of animation on which the receiver should stop it's own animation.
 */
- (void) stopWhenAnimation:(GrowlAnimation *)animation reachesProgress:(GrowlAnimationProgress)stopProgress;

/*!
 * @method isAnimating
 * @abstract Returns whether the receiver is animating or not.
 */
- (BOOL) isAnimating;

/*!
 * @method drawFrame:
 * @abstract Called for each frame update with the correct progress.
 * Subclasses should override this method in order to draw their custome animation.
 * @param progress The correct progress of the animation.
 */
- (void) drawFrame:(GrowlAnimationProgress)progress;


/*!
 * @method repeats
 * @abstract Returns whether the receiver repeats its animation or not.
 */
- (BOOL) repeats;

/*!
 * @method setRepeats:
 * @abstract Sets whether the receiver repeats its animation or not.
 */
- (void) setRepeats:(BOOL)value;


/*!
 * @method currentProgress
 * @abstract Returns the current progress of the animation of the receiver.
 */
- (GrowlAnimationProgress) currentProgress;

/*!
 * @method setCurrentProgress:
 * @abstract Sets the current progress of the animation of the receiver.
 */
- (void) setCurrentProgress:(GrowlAnimationProgress)value;


/*!
 * @method animationCurve
 * @abstract Returns the curve of the animation of the receiver.
 */
- (GrowlAnimationCurve) animationCurve;

/*!
 * @method setAnimationCurve:
 * @abstract Sets the curve of the animation of the receiver.
 */
- (void) setAnimationCurve:(GrowlAnimationCurve)curve;


/*!
 * @method duration
 * @abstract Returns the duration of the animation of the receiver.
 */
- (NSTimeInterval) duration;

/*!
 * @method setDuration:
 * @abstract Sets the duration of the animation of the receiver.
 */
- (void) setDuration:(NSTimeInterval)duration;


/*!
 * @method frameRate
 * @abstract Returns the frame rate (frames per second) of the animation of the receiver.
 */
- (float) frameRate;

/*!
 * @method setFrameRate:
 * @abstract Sets the frame rate (frames per second) of the animation of the receiver.
 */
- (void) setFrameRate:(float)value;


/*!
 * @method delegate
 * @abstract Returns the delegate of the receiver.
 */
- (id) delegate;

/*!
 * @method setDelegate:
 * @abstract Sets the delegate of the receiver.
 */
- (void) setDelegate:(id)newDelegate;

/*!
 * @method framesPassed
 * @abstract Returns the number of frames passed since the beginning of the animation.
 */
- (unsigned) framesPassed;

- (void) animationIsInMiddle;
- (void) animationDidStop;
- (void) animationDidEnd;

@end


/*!
 * @category NSObject (GrowlAnimationDelegate)
 * @abstract Defines the methods that delegates of GrowlAnimation can implement.
 */
@interface NSObject (GrowlAnimationDelegate)

/*!
 * @method growlAnimationShouldStart:
 * @abstract Called before the animation will start to request the delegate's permission to start.
 * @param animation The animation that is about to start.
 * @result YES is the animation may start, and NO if it may not.
 */
- (BOOL) growlAnimationShouldStart:(GrowlAnimation *)animation;

/*!
 * @method growlAnimationIsInMiddle:
 * @abstract Called when the animation completed its first half.
 */
- (void) growlAnimationIsInMiddle:(GrowlAnimation *)animation;

/*!
 * @method growlAnimationDidStop:
 * @abstract Called when the animation was stopped using -stopAnimation.
 * @param animation The animation that was stopped.
 */
- (void) growlAnimationDidStop:(GrowlAnimation *)animation;

/*!
 * @method growlAnimationDidEnd:
 * @abstract Called at the end of the animation.
 * @param animation The animation that ended.
 */
- (void) growlAnimationDidEnd:(GrowlAnimation *)animation;

/*!
 * @method growlAnimation:valueForProgress:
 * @abstract Called before each frame update to provide the delegate with the ability to change the progress of the animation.
 * @param animation The animation which is about to update its frame.
 * @param progress The default new progress of the animation.
 * @result The new progress of the animation.
 */
- (float) growlAnimation:(GrowlAnimation *)animation valueForProgress:(GrowlAnimationProgress)progress;

@end
