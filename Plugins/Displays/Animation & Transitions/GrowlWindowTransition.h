//
//  GrowlWindowTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlAnimation.h"


/*!
 * @class GrowlWindowTransition
 * @abstract Base class for window transitions.
 */
@interface GrowlWindowTransition : GrowlAnimation {
	NSWindow *window;
}

/*!
 * @method initWithWindow:
 * @abstract Designated initializer.
 * @param inWindow The window for this transition.
 * @result An initialized GrowlWindowTransition instance.
 */
- (id) initWithWindow:(NSWindow *)inWindow;

/*!
 * @method window
 * @abstract Returns the window of the receiver.
 */
- (NSWindow *) window;

/*!
 * @method setWindow:
 * @abstract Sets the window of the receiver.
 */
- (void) setWindow:(NSWindow *)inWindow;

	//Override this in your subclass in order to draw your animation.
/*!
 * @method drawTransitionWithWindow:
 * @abstract Overridden by subclasses to draw the receiver’s transition.
 * @discussion This method is called for each frame update.
 * You should override it in your subclass to draw your transition.
 */
- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress;

@end
