//
//  GrowlWipeWindowTransition.h
//  Growl
//
//  Created by rudy on 12/10/05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlWindowTransition.h"

@interface GrowlWipeWindowTransition : GrowlWindowTransition {
NSPoint	startingPoint;
NSPoint endingPoint;
float	xDistance;
float	yDistance;

CGContextRef context;

}

- (id) initWithWindow:(NSWindow *)inWindow;
- (void) setFromOrigin:(NSPoint)from toOrigin:(NSPoint)to;
- (void) drawTransitionWithWindow:(NSWindow *)aWindow progress:(GrowlAnimationProgress)progress;
@end
