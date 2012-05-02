//
//  GrowlFlippingWindowTransition.m
//  Growl
//
//  Created by Jamie Kirkpatrick on 04/12/2005.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlFlippingWindowTransition.h>
#import <QuartzCore/QuartzCore.h>

@implementation GrowlFlippingWindowTransition

- (id) initWithWindow:(NSWindow *)inWindow {
	if ((self = [super initWithWindow:inWindow])) {
		[[[self window] contentView] setWantsLayer:YES];
		flipsX = NO;
		flipsY = NO;
	}

	return self;
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)inProgress {
	if (aWindow) {
		CGFloat xScale = 1.0f;
		CGFloat yScale = 1.0f;
		switch (direction) {
			case GrowlForwardTransition:
				//[aWindow setScaleX:(flipsX ? inProgress : 1.0) Y:(flipsY ? inProgress : 1.0)];
				xScale = (flipsX ? inProgress : 1.0);
				yScale = (flipsY ? inProgress : 1.0);
				break;
			case GrowlReverseTransition:
				//[aWindow setScaleX:(flipsX ? 1.0 - inProgress : 1.0) Y:(flipsY ? 1.0 - inProgress : 1.0)];
				xScale = (flipsX ? 1.0 - inProgress : 1.0);
				yScale = (flipsY ? 1.0 - inProgress : 1.0);
				break;
			default:
				break;
		}
		if(xScale > 1.0f) xScale = 1.0f;
		if(xScale <= 0.0f) xScale = .01f;
		
		if(yScale > 1.0f) yScale = 1.0f;
		if(yScale <= 0.0f) yScale = .01f;
		
		CATransform3D flip = CATransform3DMakeScale(xScale, yScale, 1.0f);
		[[[[self window] contentView] layer] setTransform:flip];
	}
}

#pragma mark -

- (void) startAnimation {
	if (!flipsX && !flipsY )
		return;

	[super startAnimation];
}

- (void) stopAnimation {
	if (!flipsX && !flipsY )
		return;

	//[super stopAnimation];
}

#pragma mark -
#pragma mark accessors

- (BOOL) flipsX {
    return flipsX;
}

- (void) setFlipsX: (BOOL) flag {
    flipsX = flag;
}

- (BOOL) flipsY {
    return flipsY;
}

- (void) setFlipsY: (BOOL) flag {
    flipsY = flag;
}


@end
