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

#define TIMER_INTERVAL (1. / 30.)
#define FADE_INCREMENT 0.05
#define MIN_DISPLAY_TIME 3.
#define ADDITIONAL_LINES_DISPLAY_TIME 0.5
#define MAX_DISPLAY_TIME 10.
#define GrowlBezelPadding 10.

+ (GrowlBezelWindowController *)bezel {
	return [[[self alloc] init] autorelease];
}

+ (GrowlBezelWindowController *)bezelWithTitle:(NSString *)title text:(id)text icon:(NSImage *)icon sticky:(BOOL)sticky {
	return [[[self alloc] initWithTitle:title text:text icon:icon sticky:sticky] autorelease];
}

- (id)initWithTitle:(NSString *)title text:(id)text icon:(NSImage *)icon sticky:(BOOL)sticky {
	int sizePref = 0;
	READ_GROWL_PREF_INT(BEZEL_SIZE_PREF, @"com.Growl.Bezel", &sizePref);
	NSRect sizeRect;
	if (sizePref == BEZEL_SIZE_NORMAL) {
		sizeRect = NSMakeRect( 0., 0., 211., 206. );
	} else {
		sizeRect = NSMakeRect( 0., 0., 160., 160. );
	}
	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:sizeRect
						styleMask:NSBorderlessWindowMask
						  backing:NSBackingStoreBuffered defer:NO] autorelease];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
//	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
	[panel setAlphaValue:0.];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];
	[panel setMovableByWindowBackground:YES];
	
	GrowlBezelWindowView *view = [[[GrowlBezelWindowView alloc] initWithFrame:panelFrame] autorelease];
	
	[view setTarget:self];
	[view setAction:@selector(_bezelClicked:)]; // Not used for now
	[panel setContentView:view];
	
	[view setTitle:title];
	NSMutableString	*tempText = [[[NSMutableString alloc] init] autorelease];
	if ( [text isKindOfClass:[NSString class]] ) {
		// Sanity check to unify line endings
		[tempText setString:text];
		[tempText replaceOccurrencesOfString:@"\r"
				withString:@"\n"
				options:nil
				range:NSMakeRange(0, [tempText length])];
		[view setText:tempText];
	} else if ( [text isKindOfClass:[NSAttributedString class]] ) {
		// Sanity check to unify line endings
		[tempText setString:[text string]];
		[tempText replaceOccurrencesOfString:@"\r"
				withString:@"\n"
				options:nil
				range:NSMakeRange(0, [tempText length])];
		[view setText:tempText]; // striping any attributes!! eat eat!
	}
	
	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	
	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	NSPoint panelTopLeft;
	int positionPref = 0;
	READ_GROWL_PREF_INT(BEZEL_POSITION_PREF, @"com.Growl.Bezel", &positionPref);
	switch (positionPref) {
		case BEZEL_POSITION_DEFAULT:
			panelTopLeft = NSMakePoint(ceil((NSWidth(screen)/2.0) -(NSWidth(panelFrame)/2.0)),
				140.0 + NSHeight(panelFrame));
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
	
	_autoFadeOut = YES;
	_doFadeIn = NO;
	_delegate = nil;
	_target = nil;
	_representedObject = nil;
	_action = NULL;
	_animationTimer = nil;
	
	_displayTime = MIN_DISPLAY_TIME;
	
	[self setAutomaticallyFadesOut:!sticky];
	
	return ( self = [super initWithWindow:panel] );
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_target release];
	[_representedObject release];
	[_animationTimer invalidate];
	[_animationTimer release];
	
	_target = nil;
	_representedObject = nil;
	_delegate = nil;
	_animationTimer = nil;

	[super dealloc];
}

- (void)_stopTimer {
	[_animationTimer invalidate];
	[_animationTimer release];
	_animationTimer = nil;
}

- (void)_waitBeforeFadeOut {
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:_displayTime
			target:self
		  selector:@selector( startFadeOut )
		   userInfo:nil
		    repeats:NO] retain];
}

- (void)_fadeIn:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if ( alpha < 1. ) {
		[myWindow setAlphaValue:( alpha + FADE_INCREMENT)];
	} else if ( _autoFadeOut ) {
		if ( _delegate && [_delegate respondsToSelector:@selector( bezelDidFadeIn: )] ) {
			[_delegate bezelDidFadeIn:self];
		}
		[self _waitBeforeFadeOut];
	}
}

- (void)_fadeOut:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if ( alpha > 0. ) {
		[myWindow setAlphaValue:( alpha - FADE_INCREMENT)];
	} else {
		[self _stopTimer];
		if ( _delegate && [_delegate respondsToSelector:@selector( bezelDidFadeOut: )] ) {
			[_delegate bezelDidFadeOut:self];
		}
		[self close]; // close our window
		[self autorelease]; // we retained when we fade in
	}
}

- (void)_bezelClicked:(id)sender {
	if ( _target && _action && [_target respondsToSelector:_action] ) {
		[_target performSelector:_action withObject:self];
	}
	[self startFadeOut];
}

- (void)startFadeIn {
	if ( _delegate && [_delegate respondsToSelector:@selector( bezelWillFadeIn: )] ) {
		[_delegate bezelWillFadeIn:self];
	}
	[self retain]; // release after fade out
	[self showWindow:nil];
	[self _stopTimer];
	if ( _doFadeIn ) {
		_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
				  target:self
				selector:@selector( _fadeIn: )
				userInfo:nil
				 repeats:YES] retain];
	} else if ( _autoFadeOut ) {
		[[self window] setAlphaValue:1.];
		if ( _delegate && [_delegate respondsToSelector:@selector( bezelDidFadeIn: )] ) {
			[_delegate bezelDidFadeIn:self];
		}
		[self _waitBeforeFadeOut];
	}
}

- (void)startFadeOut {
	if ( _delegate && [_delegate respondsToSelector:@selector( bezelWillFadeOut: )] ) {
		[_delegate bezelWillFadeOut:self];
	}
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
			  target:self
			selector:@selector( _fadeOut: )
			userInfo:nil
			 repeats:YES] retain];
}

- (BOOL)automaticallyFadeOut {
	return _autoFadeOut;
}

- (void)setAutomaticallyFadesOut:(BOOL) autoFade {
	_autoFadeOut = autoFade;
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

- (id) delegate {
	return _delegate;
}

- (void) setDelegate:(id) delegate {
	_delegate = delegate;
}

- (BOOL) respondsToSelector:(SEL) selector {
	BOOL contentViewRespondsToSelector = [[[self window] contentView] respondsToSelector:selector];
	return contentViewRespondsToSelector ? contentViewRespondsToSelector : [super respondsToSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *) invocation {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:[invocation selector]] )
		[invocation invokeWithTarget:contentView];
	else [super forwardInvocation:invocation];
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) selector {
	NSView *contentView = [[self window] contentView];
	if( [contentView respondsToSelector:selector] )
		return [contentView methodSignatureForSelector:selector];
	else return [super methodSignatureForSelector:selector];
}

#pragma mark -

- (void)mouseDown:(NSEvent *)event {
	dragging = NO;
	[[self nextResponder] mouseDown:event];
}
- (void)mouseDragged:(NSEvent *)event {
	dragging = YES;
	[self _stopTimer];
	[[self nextResponder] mouseDragged:event];
}
- (void)mouseUp:(NSEvent *)event {
	if(dragging && _autoFadeOut)
		[self _waitBeforeFadeOut];
	[[self nextResponder] mouseUp:event];
}

@end
