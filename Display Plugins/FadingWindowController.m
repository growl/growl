//
//  GrowlWindowControllerAdditions.m
//  Display Plugins
//
//  Created by Ingmar Stein on 16.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "FadingWindowController.h"

#define TIMER_INTERVAL (1. / 30.)
#define FADE_INCREMENT 0.05f

@implementation FadingWindowController
- (id)initWithWindow:(NSWindow *)window {
	if( (self = [super initWithWindow:window]) ) {
		_delegate = nil;
		_animationTimer = nil;
		_autoFadeOut = NO;
		_doFadeIn = YES;
		_fadeIncrement = FADE_INCREMENT;
		_timerInterval = TIMER_INTERVAL;
	}
	return( self );
}

- (void)_stopTimer {
	[_animationTimer invalidate];
	[_animationTimer release];
	_animationTimer = nil;
}

- (void)dealloc
{
	[self _stopTimer];
	[super dealloc];
}

- (void)_waitBeforeFadeOut {
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:_displayTime
														target:self
													  selector:@selector( startFadeOut )
													  userInfo:nil
													   repeats:NO] retain];
}

- (void)_fadeIn:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if ( alpha < 1.f ) {
		[myWindow setAlphaValue: alpha + _fadeIncrement];
	} else {
		[self _stopTimer];
		if ( _delegate && [_delegate respondsToSelector:@selector( didFadeIn: )] ) {
			[_delegate didFadeIn:self];
		}
		if ( _autoFadeOut ) {
			[self _waitBeforeFadeOut];
		}
	}
}

- (void)_fadeOut:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if ( alpha > 0.f ) {
		[myWindow setAlphaValue: alpha - _fadeIncrement];
	} else {
		[self _stopTimer];
		if ( _delegate && [_delegate respondsToSelector:@selector( didFadeOut: )] ) {
			[_delegate didFadeOut:self];
		}
		[self close]; // close our window
		[self autorelease]; // we retained when we fade in
	}
}

- (void)startFadeIn {
	if ( _delegate && [_delegate respondsToSelector:@selector( willFadeIn: )] ) {
		[_delegate willFadeIn:self];
	}
	[self retain]; // release after fade out
	[self showWindow:nil];
	[self _stopTimer];
	if ( _doFadeIn ) {
		_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:_timerInterval
															target:self
														  selector:@selector( _fadeIn: )
														  userInfo:nil
														   repeats:YES] retain];
	} else {
		if ( _delegate && [_delegate respondsToSelector:@selector( didFadeIn: )] ) {
			[_delegate didFadeIn:self];
		}
		if ( _autoFadeOut ) {
			[self _waitBeforeFadeOut];
		}
	}
}

- (void)startFadeOut {
	if ( _delegate && [_delegate respondsToSelector:@selector( willFadeOut: )] ) {
		[_delegate willFadeOut:self];
	}
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:_timerInterval
														target:self
													  selector:@selector( _fadeOut: )
													  userInfo:nil
													   repeats:YES] retain];
}

- (void)stopFadeOut {
	[self _stopTimer];
	[self close];
	[self autorelease];
}

#pragma mark -

- (BOOL)automaticallyFadeOut {
	return _autoFadeOut;
}

- (void)setAutomaticallyFadesOut:(BOOL) autoFade {
	_autoFadeOut = autoFade;
}

#pragma mark -

- (float)fadeIncrement {
	return _fadeIncrement;
}

- (void)setFadeIncrement:(float) increment {
	_fadeIncrement = increment;
}

#pragma mark -

- (float)timerInterval {
	return _timerInterval;
}

- (void)setTimerInterval:(float) interval {
	_timerInterval = interval;
}

#pragma mark -

- (double)displayTime {
	return _displayTime;
}

- (void)setDisplayTime:(double) t {
	_displayTime = t;
}

#pragma mark -

- (id) delegate {
	return _delegate;
}

- (void) setDelegate:(id) delegate {
	_delegate = delegate;
}

#pragma mark -

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
