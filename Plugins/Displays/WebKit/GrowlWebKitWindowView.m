//
//  GrowlWebKitWindowView.m
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005–2011 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlNotificationView.h>
#import "GrowlWebKitWindowView.h"
#import "GrowlDefinesInternal.h"
#import "GrowlWebKitDefines.h"

@interface NSView (MouseOver)
- (void) _updateMouseoverWithFakeEvent;
@end

@implementation GrowlWebKitWindowView
@synthesize styleBundle;

- (id) initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName {
	if ((self = [super initWithFrame:frameRect frameName:frameName groupName:groupName])) {
		[self setUIDelegate:self];
		closeButtonRect = NSZeroRect;
		// we need a minor delay to allow the window frame to be properly set before testing
		[self performSelector:@selector(testInitialMouseLocation) 
					  withObject:nil 
					  afterDelay:0.2
						  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];
	}
	return self;
}

- (void) dealloc {
	[self setUIDelegate:nil];
	[styleBundle release];
	styleBundle = nil;
	[super dealloc];
}

- (NSView *) hitTest:(NSPoint)aPoint {
	if (realHitTest || ![self showsCloseBox])
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
	[window setFrame:windowRect display:YES animate:NO];

	if (trackingRectTag)
		[self removeTrackingRect:trackingRectTag];
	BOOL mouseInside = NSPointInRect([self convertPoint:[window convertScreenToBase:[NSEvent mouseLocation]] fromView:self],
									 rect);
	trackingRectTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:mouseInside];
	if (mouseInside)
		[self updateFocusState];
}

#pragma mark -

- (BOOL) mouseOver {
	return mouseOver;
}

- (void) setCloseOnMouseExit:(BOOL)flag {
	closeOnMouseExit = flag;
}

- (BOOL) showsCloseBox {
	NSDictionary *bundleDict = [styleBundle infoDictionary];
	if([bundleDict objectForKey:@"GrowlCloseButtonEnabled"])
		return [[bundleDict objectForKey:@"GrowCloseButtonEnabled"] boolValue];
	return YES;
}

- (void) clickedCloseBox:(id)sender {
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
		NSButton *gCloseButton = [GrowlNotificationView closeButtonForKey:[styleBundle bundleIdentifier]];
		if (flag) {
			NSDictionary *bundleDict = [styleBundle infoDictionary];
			CGFloat xOrig = [self bounds].origin.x;
			CGFloat yOrig = [self bounds].size.height - [gCloseButton frame].size.height;
			CGFloat width = [gCloseButton frame].size.width;
			CGFloat height = [gCloseButton frame].size.height;
			if([bundleDict objectForKey:@"GrowlCloseButtonXOrigin"])
				xOrig = [[bundleDict objectForKey:@"GrowlCloseButtonXOrigin"] floatValue];
			if([bundleDict objectForKey:@"GrowlCloseButtonYOrigin"])
				yOrig = yOrig - [[bundleDict objectForKey:@"GrowlCloseButtonYOrigin"] floatValue];
			if([bundleDict objectForKey:@"GrowlCloseButtonWidth"])
				width = [[bundleDict objectForKey:@"GrowlCloseButtonWidth"] floatValue];
			if([bundleDict objectForKey:@"GrowlCloseButtonHeight"])
				height = [[bundleDict objectForKey:@"GrowlCloseButtonHeight"] floatValue];
			
			[gCloseButton setFrame:NSMakeRect(xOrig, yOrig, width, height)];
			[gCloseButton setTarget:self];
			[gCloseButton setAction:@selector(clickedCloseBox:)];
			[[self superview] addSubview:gCloseButton];
			closeButtonRect = [gCloseButton frame];
			
		} else {
			[gCloseButton removeFromSuperview];
			[gCloseButton setFrame:NSMakeRect(0,0,30,30)]; // restore the default frame
			closeButtonRect = NSZeroRect;
		}
	}else {
		NSString *webScriptMethodName = nil;
		if(flag){
			webScriptMethodName = @"showCloseButton";
		}else{
			webScriptMethodName = @"hideCloseButton";
		}
		[[self windowScriptObject] callWebScriptMethod:webScriptMethodName withArguments:nil];
	}
}

- (void)testInitialMouseLocation
{
	if(NSPointInRect([NSEvent mouseLocation], [[self window] frame]))
			[self mouseEntered:nil];
}

- (BOOL) acceptsFirstMouse:(NSEvent *) event {
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
	[self updateFocusState];
	[self setCloseBoxVisible:YES];
	mouseOver = YES;
	[self setNeedsDisplay:YES];
	
	if ([[[self window] windowController] respondsToSelector:@selector(mouseEnteredNotificationView:)])
		[[[self window] windowController] performSelector:@selector(mouseEnteredNotificationView:)
											   withObject:self];	
}

- (void) mouseExited:(NSEvent *)theEvent {
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

- (NSUInteger) webView:(WebView *)sender dragDestinationActionMaskForDraggingInfo:(id <NSDraggingInfo>)draggingInfo {
	return 0U; //WebDragDestinationActionNone;
}

- (NSUInteger) webView:(WebView *)sender dragSourceActionMaskForPoint:(NSPoint)point {
	return 0U; //WebDragSourceActionNone;
}

- (void) mouseDown:(NSEvent *)event {
	mouseOver = NO;

	if (NSPointInRect([event locationInWindow], closeButtonRect)) {
		[[GrowlNotificationView closeButtonForKey:[styleBundle bundleIdentifier]] mouseDown:event];

	} else {
		if (target && action && [target respondsToSelector:action])
			[target performSelector:action withObject:self];
	}
}

- (NSArray *) webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
	// disable context menu
	return nil;
}

@end
