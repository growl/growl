//
//  GrowlBezelWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlBezelWindowController.h"
#import "GrowlBezelWindowView.h"
#import "NSGrowlAdditions.h"

static unsigned int bezelWindowDepth = 0;

@implementation GrowlBezelWindowController

#define TIMER_INTERVAL (1. / 30.)
#define FADE_INCREMENT 0.05
#define MIN_DISPLAY_TIME 4.
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
	extern unsigned int bezelWindowDepth;
	
	NSPanel *panel = [[[NSPanel alloc] initWithContentRect:NSMakeRect( 0., 0., 160., 160. )
						styleMask:NSBorderlessWindowMask
						  backing:NSBackingStoreBuffered defer:NO] autorelease];
	NSRect panelFrame = [panel frame];
	[panel setBecomesKeyOnlyIfNeeded:YES];
	[panel setHidesOnDeactivate:NO];
	[panel setBackgroundColor:[NSColor clearColor]];
	[panel setLevel:NSStatusWindowLevel];
	[panel setIgnoresMouseEvents:YES];
	[panel setSticky:YES];
	[panel setAlphaValue:0.];
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
	if ( [text isKindOfClass:[NSString class]] ) {
		[view setText:text];
	} else if ( [text isKindOfClass:[NSAttributedString class]] ) {
		[view setText:[text string]]; // striping any attributes!! eat eat!
	}
	
	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];
	
	NSRect screen = [[NSScreen mainScreen] visibleFrame];
	[panel setFrameTopLeftPoint:NSMakePoint( NSWidth( screen ) - NSWidth( panelFrame ) - GrowlBezelPadding,
			NSMaxY ( screen ) - GrowlBezelPadding - (bezelWindowDepth ) )];
	
	_depth = bezelWindowDepth += NSHeight ( panelFrame );
	_autoFadeOut = YES;
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

	extern unsigned int bezelWindowDepth;
	if( _depth == bezelWindowDepth ) bezelWindowDepth = 0;

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
		[self close];
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
	[self retain]; // realease after fade out
	[self showWindow:nil];
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL
			  target:self
			selector:@selector( _fadeIn: )
			userInfo:nil
			 repeats:YES] retain];
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

@end
