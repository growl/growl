//
//  GrowlMusicVideoWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoWindowView.h"
#import "NSGrowlAdditions.h"

@implementation GrowlMusicVideoWindowController

#define MIN_DISPLAY_TIME 4.
#define ADDITIONAL_LINES_DISPLAY_TIME 0.5
#define MAX_DISPLAY_TIME 10.
#define GrowlMusicVideoPadding 10.

+ (GrowlMusicVideoWindowController *)musicVideo {
	return [[[self alloc] init] autorelease];
}

+ (GrowlMusicVideoWindowController *)musicVideoWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky {
	return [[[self alloc] initWithTitle:title text:text icon:icon priority:priority sticky:sticky] autorelease];
}

- (id)initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky {
	int sizePref;
	NSRect sizeRect;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		sizeRect = NSMakeRect( 0., 0., NSWidth([[NSScreen mainScreen] visibleFrame]), 192. );
		timerInterval = (1. / 128.);
		fadeIncrement = 6.;
	} else {
		sizeRect = NSMakeRect( 0., 0., NSWidth([[NSScreen mainScreen] visibleFrame]), 96. );
		timerInterval = (1. / 64.);
		fadeIncrement = 6.;
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
	[panel setAlphaValue:0.];
	[panel setOpaque:NO];
	[panel setHasShadow:NO];
	[panel setCanHide:NO];
	[panel setReleasedWhenClosed:YES];
	[panel setDelegate:self];
	
	GrowlMusicVideoWindowView *view = [[[GrowlMusicVideoWindowView alloc] initWithFrame:panelFrame] autorelease];
	
	[view setTarget:self];
	[view setAction:@selector(_musicVideoClicked:)]; // Not used for now
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
	
	topLeftPosition = 0.;
	[panel setFrameTopLeftPoint:NSMakePoint(0., topLeftPosition)];
	
	_autoFadeOut = YES;
	_doFadeIn = YES;
	_delegate = nil;
	_target = nil;
	_representedObject = nil;
	_action = NULL;
	_animationTimer = nil;
	
	_displayTime = MIN_DISPLAY_TIME;
	
	_priority = priority;
	
	//[self setAutomaticallyFadesOut:!sticky];
	[self setAutomaticallyFadesOut:TRUE];
	
	return ( self = [super initWithWindow:panel] );
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[_target release];
	[_representedObject release];
	[_animationTimer invalidate];
	[_animationTimer release];

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
	NSRect theFrame = [myWindow frame];
	if ( topLeftPosition < NSHeight(theFrame) ) {
		topLeftPosition += fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(0., topLeftPosition)];
	} else if ( _autoFadeOut ) {
		if ( _delegate && [_delegate respondsToSelector:@selector( musicVideoDidFadeIn: )] ) {
			[_delegate musicVideoDidFadeIn:self];
		}
		[self _waitBeforeFadeOut];
	}
}

- (void)_fadeOut:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	if ( topLeftPosition > 0. ) {
		topLeftPosition -= fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(0., topLeftPosition)];
	} else {
		[self _stopTimer];
		if ( _delegate && [_delegate respondsToSelector:@selector( musicVideoDidFadeOut: )] ) {
			[_delegate musicVideoDidFadeOut:self];
		}
		[self close]; // close our window
		[self autorelease]; // we retained when we fade in
	}
}

- (void)_musicVideoClicked:(id)sender {
	if ( _target && _action && [_target respondsToSelector:_action] ) {
		[_target performSelector:_action withObject:self];
	}
	[self startFadeOut];
}

- (void)startFadeIn {
	if ( _delegate && [_delegate respondsToSelector:@selector( musicVideoWillFadeIn: )] ) {
		[_delegate musicVideoWillFadeIn:self];
	}
	[self retain]; // release after fade out
	[self showWindow:nil];
	[self _stopTimer];
	[[self window] setAlphaValue:1.];
	if ( _doFadeIn ) {
		_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:timerInterval
				  target:self
				selector:@selector( _fadeIn: )
				userInfo:nil
				 repeats:YES] retain];
	} else if ( _autoFadeOut ) {
		if ( _delegate && [_delegate respondsToSelector:@selector( musicVideoDidFadeIn: )] ) {
			[_delegate musicVideoDidFadeIn:self];
		}
		[self _waitBeforeFadeOut];
	}
}

- (void)startFadeOut {
	if ( _delegate && [_delegate respondsToSelector:@selector( musicVideoWillFadeOut: )] ) {
		[_delegate musicVideoWillFadeOut:self];
	}
	[self _stopTimer];
	_animationTimer = [[NSTimer scheduledTimerWithTimeInterval:timerInterval
			  target:self
			selector:@selector( _fadeOut: )
			userInfo:nil
			 repeats:YES] retain];
}

- (void)stopFadeOut {
	[self _stopTimer];
	[self close];
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
