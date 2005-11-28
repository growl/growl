//
//  GrowlNotificationView.m
//  Growl
//
//  Created by Jamie Kirkpatrick on 27/11/05.
//  Copyright 2005  Jamie Kirkpatrick. All rights reserved.
//

#import "GrowlNotificationView.h"


@implementation GrowlNotificationView

- (id) delegate {	
    return delegate; 
}

- (void) setDelegate: (id) theDelegate {
	delegate = theDelegate;
}

#pragma mark -

- (id) target {
	return target;
}

- (void) setTarget:(id) object {
	target = object;
}

#pragma mark -

- (SEL) action {
	return action;
}

- (void) setAction:(SEL) selector {
	action = selector;
}

#pragma mark -

- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *)theEvent {
#pragma unused(theEvent)
	[NSApp preventWindowOrdering];
	return YES;
}

- (BOOL) mouseOver {
	return mouseOver;
}

- (void) setCloseOnMouseExit:(BOOL)flag {
	closeOnMouseExit = flag;
}

- (BOOL) acceptsFirstMouse:(NSEvent *) theEvent {
#pragma unused(theEvent)
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
#pragma unused(theEvent)
	mouseOver = YES;
	[self setNeedsDisplay:YES];
}

- (void) mouseExited:(NSEvent *)theEvent {
#pragma unused(theEvent)
	mouseOver = NO;
	[self setNeedsDisplay:YES];
	if (closeOnMouseExit && [delegate respondsToSelector:@selector(mouseExitedNotificationView:)])
		[delegate performSelector:@selector(mouseExitedNotificationView:) withObject:self];
}

- (void) mouseDown:(NSEvent *) event {
#pragma unused(event)
	mouseOver = NO;
	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];
}

@end
