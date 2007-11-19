//
//  GrowlWebKitWindowView.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlWebKitWindowView.h"
#import "GrowlDefinesInternal.h"
#import "GrowlWebKitDefines.h"
#import "GrowlNotificationView.h"

@interface NSView (MouseOver)
- (void) _updateMouseoverWithFakeEvent;
@end

@implementation GrowlWebKitWindowView
- (id) initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName {
	if ((self = [super initWithFrame:frameRect frameName:frameName groupName:groupName])) {
		[self setUIDelegate:self];
		closeButtonRect = NSZeroRect;
		// we need a minor delay to allow the window frame to be properly set before testing
		[self performSelector:@selector(testInitialMouseLocation) withObject:nil afterDelay:0.2];
	}
	return self;
}

- (void) dealloc {
	[self setUIDelegate:nil];
	[super dealloc];
}

- (NSView *) hitTest:(NSPoint)aPoint {
	if (realHitTest)
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
- (void) updateFocusState {
	realHitTest = YES;
	[[[[self mainFrame] frameView] documentView] _updateMouseoverWithFakeEvent];
	realHitTest = NO;
}

- (void) sizeToFit {
	NSRect rect = [[[[self mainFrame] frameView] documentView] frame];

	// resize the window so that it contains the tracking rect
	NSWindow *window = 	[self window];
	NSRect windowRect = [window frame];
	windowRect.origin.y -= rect.size.height - windowRect.size.height;
	windowRect.size = rect.size;
	[window setFrame:windowRect display:YES animate:YES];

	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	BOOL mouseInside = NSPointInRect([self convertPoint:[window convertScreenToBase:[NSEvent mouseLocation]] fromView:self],
									 rect);
	trackingRectTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:mouseInside];
	if (mouseInside)
		[self updateFocusState];
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

- (BOOL) showsCloseBox {
	return YES;
}

- (void) clickedCloseBox:(id)sender {
#pragma unused(sender)
	mouseOver = NO;
	
	if ([[[self window] windowController] respondsToSelector:@selector(clickedClose)])
		[[[self window] windowController] performSelector:@selector(clickedClose)];

	if (([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) != 0) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_CLOSE_ALL_NOTIFICATIONS
															object:nil];
	}
}

- (void) setCloseBoxVisible:(BOOL)flag {
	if ([self showsCloseBox]) {
	    NSButton *gCloseButton = [GrowlNotificationView closeButton];
		// locate the close button in the upper-left corner as do other notification views
#pragma mark Display style close box positioning override goes HERE.
// This is where the location modification can be inserted with minimal effort, by reading values in from the display style and adjusting as needed.
	    [gCloseButton setFrame:NSMakeRect([self bounds].origin.x, 
										  [self bounds].size.height - [gCloseButton frame].size.height,
										  [gCloseButton frame].size.width,
										  [gCloseButton frame].size.height)];
	    [gCloseButton setTarget:self];
	    [gCloseButton setAction:@selector(clickedCloseBox:)];
        if (flag) {
            [self addSubview:gCloseButton];
			closeButtonRect = [gCloseButton frame];

        } else {
			[gCloseButton removeFromSuperview];
			[gCloseButton setFrame:NSMakeRect(0,0,30,30)]; // restore the default frame
			closeButtonRect = NSZeroRect;
		}
	}
}

- (void)testInitialMouseLocation
{
	if(NSPointInRect([NSEvent mouseLocation], [[self window] frame]))
			[self mouseEntered:nil];
}

- (BOOL) acceptsFirstMouse:(NSEvent *) event {
#pragma unused(event)
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
#pragma unused(theEvent)
	[self updateFocusState];
	[self setCloseBoxVisible:YES];
	mouseOver = YES;
	[self setNeedsDisplay:YES];
	
	if ([[[self window] windowController] respondsToSelector:@selector(mouseEnteredNotificationView:)])
		[[[self window] windowController] performSelector:@selector(mouseEnteredNotificationView:)
											   withObject:self];	
}

- (void) mouseExited:(NSEvent *)theEvent {
#pragma unused(theEvent)
	[self updateFocusState];
    [self setCloseBoxVisible:NO];
	mouseOver = NO;
	[self setNeedsDisplay:YES];

	// abuse the target object
	if (closeOnMouseExit) {
		if ([[[self window] windowController] respondsToSelector:@selector(stopDisplay)])
			[[[self window] windowController] performSelector:@selector(stopDisplay)];
	}
	
	if ([[[self window] windowController] respondsToSelector:@selector(mouseExitedNotificationView:)])
		[[[self window] windowController] performSelector:@selector(mouseExitedNotificationView:)
											   withObject:self];
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
	mouseOver = NO;

	if (NSPointInRect([event locationInWindow], closeButtonRect)) {
		[[GrowlNotificationView closeButton] mouseDown:event];

	} else {
		if (target && action && [target respondsToSelector:action])
			[target performSelector:action withObject:self];
	}
}

- (NSArray *) webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
#pragma unused(sender, element, defaultMenuItems)
	// disable context menu
	return nil;
}

@end
