//
//  GrowlShrinkingWindowTransition.m
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlShrinkingWindowTransition.h>


@implementation GrowlShrinkingWindowTransition

- (id) initWithWindow:(NSWindow *)inWindow {
	if((self = [super initWithWindow:inWindow])){
		[[inWindow contentView] setWantsLayer:YES];
	}
	return self;
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(NSAnimationProgress)inProgress {
	if (aWindow) {
		switch (direction) {
			case GrowlForwardTransition:
				if (scaleFactor < 1.0)
					scaleFactor += inProgress;
				if (scaleFactor > 1.0)
					scaleFactor = 1.0;
				//[aWindow setScaleX:scaleFactor Y:scaleFactor];
				break;
			case GrowlReverseTransition:
				if (scaleFactor > 0.0)
					scaleFactor -= inProgress;
				if (scaleFactor < 0.0)
					scaleFactor = 0.0;
				//[aWindow setScaleX:scaleFactor Y:scaleFactor];
				break;
			default:
				break;
		}
		inProgress = direction == GrowlForwardTransition ? inProgress : 1.0f - inProgress;
		if(inProgress > 1.0f)
			inProgress = 1.0f;
		if(inProgress <= 0.0f)
			inProgress = 0.01f;
		CATransform3D scale = CATransform3DMakeScale(inProgress, inProgress, 1.0f);
		[[[[self window] contentView] layer] setTransform:scale];
	}
}

@end
