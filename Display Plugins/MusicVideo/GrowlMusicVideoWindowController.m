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
	return [[[GrowlMusicVideoWindowController alloc] init] autorelease];
}

+ (GrowlMusicVideoWindowController *)musicVideoWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky {
	return [[[GrowlMusicVideoWindowController alloc] initWithTitle:title text:text icon:icon priority:priority sticky:sticky] autorelease];
}

- (id)initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky {
	int sizePref;
	NSRect sizeRect;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		sizeRect = NSMakeRect( 0.f, 0.f, NSWidth([[NSScreen mainScreen] visibleFrame]), 192.f );
	} else {
		sizeRect = NSMakeRect( 0.f, 0.f, NSWidth([[NSScreen mainScreen] visibleFrame]), 96.f );
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

	topLeftPosition = 0.f;
	[panel setFrameTopLeftPoint:NSMakePoint(0.f, topLeftPosition)];

	if( (self = [super initWithWindow:panel]) ) {
		_autoFadeOut = YES;	// !sticky
		_target = nil;
		_action = NULL;
		_displayTime = MIN_DISPLAY_TIME;
		_priority = priority;
		if (sizePref == MUSICVIDEO_SIZE_HUGE) {
			_timerInterval = (1. / 128.);
			_fadeIncrement = 6.f;
		} else {
			_timerInterval = (1. / 64.);
			_fadeIncrement = 6.f;
		}
	}
	
	return( self );
}

- (void)dealloc {
	[_target release];

	[super dealloc];
}

- (void)_fadeIn:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	NSRect theFrame = [myWindow frame];
	if ( topLeftPosition < NSHeight(theFrame) ) {
		topLeftPosition += _fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(0.f, topLeftPosition)];
	} else {
		[self _stopTimer];
		if ( _autoFadeOut ) {
			if ( _delegate && [_delegate respondsToSelector:@selector( didFadeIn: )] ) {
				[_delegate didFadeIn:self];
			}
			[self _waitBeforeFadeOut];
		}
	}
}

- (void)_fadeOut:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	if ( topLeftPosition > 0.f ) {
		topLeftPosition -= _fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(0.f, topLeftPosition)];
	} else {
		[self _stopTimer];
		if ( _delegate && [_delegate respondsToSelector:@selector( didFadeOut: )] ) {
			[_delegate didFadeOut:self];
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

- (int)priority {
	return _priority;
}

- (void)setPriority:(int)newPriority {
	_priority = newPriority;
}
@end
