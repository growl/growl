//
//  GrowlRipplingWindowTransition.m
//  Growl
//
//  Created by rudy on 1/14/07.
//
 
#import "GrowlRipplingWindowTransition.h"
#import "AWRippler.h"

@implementation GrowlRipplingWindowTransition

- (id) initWithWindow:(NSWindow *)inWindow {
	if((self = [super initWithWindow:inWindow])) {
		rippler = [[AWRippler alloc] init];
		win = inWindow;	
	}
	return self;
}

- (void) animationDidStart {
	[super animationDidStart];
	
	if ([self currentProgress] < 1.0f) {
		[rippler rippleWindow:win];
		[rippler release]; rippler = nil;
	}
	[self setCurrentProgress:1.0f];
	//[self stopAnimation];
		
}

- (void) setFromOrigin:(NSPoint)startingOrigin toOrigin:(NSPoint)endingOrigin {
#pragma unused(startingOrigin, endingOrigin)
}

- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)inProgress {
#pragma unused(aWindow, inProgress)
NSLog(@"%s", __FUNCTION__);	
}

@end
