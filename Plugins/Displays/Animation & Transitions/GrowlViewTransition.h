//
//  GrowlViewTransition.h
//  Growl
//
//  Created by Ofri Wolfus on 01/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlAnimation.h"


@interface GrowlViewTransition : GrowlAnimation {
	NSView	*view;
}

- (id) initWithView:(NSView *)aView;

- (NSView *) view;
- (void) setView:(NSView *)aView;

	//Override this in your subclass in order to draw your animation.
- (void) drawTransitionWithView:(NSView *)aView progress:(GrowlAnimationProgress)progress;

@end
