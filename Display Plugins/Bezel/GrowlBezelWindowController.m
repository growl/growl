//
//  GrowlBezelWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlBezelWindowController.h"
#import "GrowlBezelWindowView.h"
#import "NSGrowlAdditions.h"

@implementation GrowlBezelWindowController

#define MIN_DISPLAY_TIME 3.
#define GrowlBezelPadding 10.f

+ (GrowlBezelWindowController *)bezel {
	return [[[GrowlBezelWindowController alloc] init] autorelease];
}

+ (GrowlBezelWindowController *)bezelWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky {
	return [[[GrowlBezelWindowController alloc] initWithTitle:title text:text icon:icon priority:priority sticky:sticky] autorelease];
}

- (id)initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky {
	int sizePref = 0;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, BezelPrefDomain, &sizePref);
	NSRect sizeRect;
	sizeRect.origin.x = 0.f;
	sizeRect.origin.y = 0.f;
	if (sizePref == BEZEL_SIZE_NORMAL) {
		sizeRect.size.width = 211.f;
		sizeRect.size.height = 206.f;
	} else {
		sizeRect.size.width = 160.f;
		sizeRect.size.height = 160.f;
	}
	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:sizeRect
						styleMask:NSBorderlessWindowMask
						  backing:NSBackingStoreBuffered defer:NO] autorelease];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
	[panel setAlphaValue:0.f];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];
	
	GrowlBezelWindowView *view = [[[GrowlBezelWindowView alloc] initWithFrame:panelFrame] autorelease];
	
	[view setTarget:self];
	[view setAction:@selector(_bezelClicked:)]; // Not used for now
	[panel setContentView:view];
	
	[view setTitle:title];
	NSMutableString	*tempText = [[[NSMutableString alloc] init] autorelease];
	// Sanity check to unify line endings
	[tempText setString:text];
	[tempText replaceOccurrencesOfString:@"\r"
			withString:@"\n"
			options:nil
			range:NSMakeRange(0, [tempText length])];
	[view setText:tempText];
	
	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	
	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	NSPoint panelTopLeft;
	int positionPref = 0;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, BezelPrefDomain, &positionPref);
	switch (positionPref) {
		case BEZEL_POSITION_DEFAULT:
			panelTopLeft = NSMakePoint(ceil((NSWidth(screen)*0.5f) -(NSWidth(panelFrame)*0.5f)),
				140.0f + NSHeight(panelFrame));
		break;
		case BEZEL_POSITION_TOPRIGHT:
			panelTopLeft = NSMakePoint( NSWidth( screen ) - NSWidth( panelFrame ) - GrowlBezelPadding,
				NSMaxY ( screen ) - GrowlBezelPadding );
		break;
		case BEZEL_POSITION_BOTTOMRIGHT:
			panelTopLeft = NSMakePoint(NSWidth( screen ) - NSWidth( panelFrame ) - GrowlBezelPadding,
				GrowlBezelPadding + NSHeight(panelFrame));
		break;
		case BEZEL_POSITION_BOTTOMLEFT:
			panelTopLeft = NSMakePoint(GrowlBezelPadding,
				GrowlBezelPadding + NSHeight(panelFrame));
		break;
		case BEZEL_POSITION_TOPLEFT:
			panelTopLeft = NSMakePoint(GrowlBezelPadding,
				NSMaxY ( screen ) - GrowlBezelPadding );
		break;
	}
	[panel setFrameTopLeftPoint:panelTopLeft];

	if( (self = [super initWithWindow:panel] ) ) {
		_autoFadeOut = YES;	//!sticky
		_doFadeIn = NO;
		_delegate = nil;
		_target = nil;
		_representedObject = nil;
		_action = NULL;
		_displayTime = MIN_DISPLAY_TIME;
		_priority = priority;
	}

	return( self );
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_target release];
	[_representedObject release];
	
	[super dealloc];
}

- (void)_bezelClicked:(id)sender {
	if ( _target && _action && [_target respondsToSelector:_action] ) {
		[_target performSelector:_action withObject:self];
	}
	[self startFadeOut];
}

- (id)target {
	return _target;
}

- (void)setTarget:(id)object {
	[_target autorelease];
	_target = [object retain];
}

- (SEL)action {
	return _action;
}

- (void)setAction:(SEL)selector {
	_action = selector;
}

- (id)representedObject {
	return _representedObject;
}

- (void) setRepresentedObject:(id) object {
	[_representedObject autorelease];
	_representedObject = [object retain];
}

- (int)priority {
	return _priority;
}

- (void)setPriority:(int)newPriority {
	_priority = newPriority;
}

- (BOOL) respondsToSelector:(SEL) selector {
	BOOL contentViewRespondsToSelector = [[[self window] contentView] respondsToSelector:selector];
	return contentViewRespondsToSelector ? contentViewRespondsToSelector : [super respondsToSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *) invocation {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:[invocation selector]] ) {
		[invocation invokeWithTarget:contentView];
	} else {
		[super forwardInvocation:invocation];
	}
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) selector {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:selector] ) {
		return [contentView methodSignatureForSelector:selector];
	} else {
		return [super methodSignatureForSelector:selector];
	}
}

@end
