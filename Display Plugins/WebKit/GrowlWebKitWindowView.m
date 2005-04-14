//
//  GrowlWebKitWindowView.m
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowView.m by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlWebKitWindowView.h"
#import "GrowlDefinesInternal.h"
#import "GrowlWebKitDefines.h"
#import "GrowlImageAdditions.h"

/* to get the limit pref */
#import "GrowlWebKitPrefsController.h"

@implementation GrowlWebKitWindowView
- (id)initWithFrame:(NSRect)frameRect frameName:(NSString *)frameName groupName:(NSString *)groupName {
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
	[[self window] setFrame:windowRect display:NO];

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
	return YES;
}

- (void) mouseEntered:(NSEvent *)theEvent {
	mouseOver = YES;
	[self setNeedsDisplay:YES];
}

- (void) mouseExited:(NSEvent *)theEvent {
	mouseOver = NO;
	[self setNeedsDisplay:YES];

	// abuse the target object
	if (closeOnMouseExit && [target respondsToSelector:@selector(startFadeOut)]) {
		[target performSelector:@selector(startFadeOut)];
	}
}

- (void) webView:(WebView *)sender makeFirstResponder:(NSResponder *)responder {
	mouseOver = NO;
	if (target && action && [target respondsToSelector:action]) {
		[target performSelector:action withObject:self];
	}
}
@end
