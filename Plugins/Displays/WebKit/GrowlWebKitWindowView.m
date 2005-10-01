//
//  GrowlWebKitWindowView.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlWebKitWindowView.h"
#import "GrowlDefinesInternal.h"
#import "GrowlWebKitDefines.h"

@implementation GrowlWebKitWindowView
- (id) initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName {
	if ((self = [super initWithFrame:frameRect frameName:frameName groupName:groupName])) {
		[self setUIDelegate:self];
	}
	return self;
}

- (void) dealloc {
	[self stopTrackingMouse];
	[self setUIDelegate:nil];
	[super dealloc];
}

// forward mouseMoved events to subviews but catch all other events here
- (NSView *) hitTest:(NSPoint)aPoint {
	if ([[[self window] currentEvent] type] == NSMouseMoved)
		return [super hitTest:aPoint];

	if ([[self superview] mouse:aPoint inRect:[self frame]])
		return self;

	return nil;
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
static void mouseMovedCallback(CFRunLoopTimerRef timer, void *info) {
#pragma unused(timer)
	NSView   *view = (NSView *)info;
	NSPoint  mouseLocation = [NSEvent mouseLocation];
	NSWindow *window = [view window];

	if ([window isVisible] && NSPointInRect([window convertScreenToBase:mouseLocation], [[window contentView] convertRect:[view frame] fromView:[view superview]])) {
		NSEvent *mouseMovedEvent = [NSEvent mouseEventWithType:NSMouseMoved location:mouseLocation modifierFlags:0U timestamp:CFAbsoluteTimeGetCurrent() windowNumber:[window windowNumber] context:[NSGraphicsContext currentContext] eventNumber:0 clickCount:0 pressure:0.0f];
//		[NSApp postEvent:mouseMovedEvent atStart:YES];
		[NSApp sendEvent:mouseMovedEvent];
	}
}

- (void) startTrackingMouse {
	if (!mouseMovedTimer) {
		CFRunLoopTimerContext context = { 0, self, NULL, NULL, NULL };
		mouseMovedTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent(), 0.05, 0, 0, mouseMovedCallback, &context);
		CFRunLoopAddTimer(CFRunLoopGetCurrent(), mouseMovedTimer, kCFRunLoopDefaultMode);
	}
}

- (void) stopTrackingMouse {
	if (mouseMovedTimer) {
		CFRunLoopTimerInvalidate(mouseMovedTimer);
		CFRelease(mouseMovedTimer);
		mouseMovedTimer = NULL;
	}
}

- (void) sizeToFit {
	NSRect rect = [[[[self mainFrame] frameView] documentView] frame];

	// resize the window so that it contains the tracking rect
	NSWindow *window = 	[self window];
	NSRect windowRect = [window frame];
	windowRect.origin.y -= rect.size.height - windowRect.size.height;
	windowRect.size = rect.size;
	[[self window] setFrame:windowRect display:NO];

	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	BOOL mouseInside = NSPointInRect([self convertPoint:[window convertScreenToBase:[NSEvent mouseLocation]] fromView:self],
									 rect);
	trackingRectTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:mouseInside];
	if (mouseInside)
		[self startTrackingMouse];
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

- (BOOL) acceptsFirstMouse:(NSEvent *) event {
#pragma unused(event)
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
#pragma unused(theEvent)
	[self startTrackingMouse];
	mouseOver = YES;
	[self setNeedsDisplay:YES];
}

- (void) mouseExited:(NSEvent *)theEvent {
#pragma unused(theEvent)
	[self stopTrackingMouse];
	mouseOver = NO;
	[self setNeedsDisplay:YES];
	
	// abuse the target object
	if (closeOnMouseExit && [target respondsToSelector:@selector(startFadeOut)])
		[target performSelector:@selector(startFadeOut)];
}

- (unsigned) webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo {
#pragma unused(sender, draggingInfo)
	return 0U; //WebDragDestinationActionNone;
}

- (unsigned) webView:(WebView *)sender dragSourceActionMaskForPoint:(NSPoint)point {
#pragma unused(sender, point)
	return 0U; //WebDragSourceActionNone;
}

- (void) mouseDown:(NSEvent *)event {
#pragma unused(event)
	mouseOver = NO;
	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];
}

- (NSArray *) webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
#pragma unused(sender, element, defaultMenuItems)
	// disable context menu
	return nil;
}

@end
