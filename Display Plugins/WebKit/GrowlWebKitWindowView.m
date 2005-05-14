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
#import "GrowlImageAdditions.h"

/* to get the limit pref */
#import "GrowlWebKitPrefsController.h"

@implementation GrowlWebKitWindowView
- (id) initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName {
	if ((self = [super initWithFrame:frameRect frameName:frameName groupName:groupName])) {
		[self setUIDelegate:self];
	}
	return self;
}

- (void) dealloc {
	[self setUIDelegate:nil];
	[super dealloc];
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

- (void) sizeToFit {
	NSRect rect = [[[[self mainFrame] frameView] documentView] frame];

	// resize the window so that it contains the tracking rect
	NSRect windowRect = [[self window] frame];
	windowRect.size = rect.size;
	[[self window] setFrame:windowRect display:YES];

	if (trackingRectTag) {
		[self removeTrackingRect:trackingRectTag];
	}
	trackingRectTag = [self addTrackingRect:rect owner:self userData:NULL assumeInside:NO];
}

#pragma mark -

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
	mouseOver = YES;
	[self setNeedsDisplay:YES];
}

- (void) mouseExited:(NSEvent *)theEvent {
#pragma unused(theEvent)
	mouseOver = NO;
	[self setNeedsDisplay:YES];

	// abuse the target object
	if (closeOnMouseExit && [target respondsToSelector:@selector(startFadeOut)]) {
		[target performSelector:@selector(startFadeOut)];
	}
}

- (void) webView:(WebView *)sender makeFirstResponder:(NSResponder *)responder {
#pragma unused(sender, responder)
	mouseOver = NO;
	if (target && action && [target respondsToSelector:action]) {
		[target performSelector:action withObject:self];
	}
}

- (NSArray *) webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
#pragma unused(sender, element, defaultMenuItems)
	// disable context menu
	return nil;
}

@end
