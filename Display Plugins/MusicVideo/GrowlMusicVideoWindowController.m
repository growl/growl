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

#define MIN_DISPLAY_TIME 4.0
#define ADDITIONAL_LINES_DISPLAY_TIME 0.5
#define MAX_DISPLAY_TIME 10.0
#define GrowlMusicVideoPadding 10.0

+ (GrowlMusicVideoWindowController *)musicVideo {
	return [[[GrowlMusicVideoWindowController alloc] init] autorelease];
}

+ (GrowlMusicVideoWindowController *)musicVideoWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	return [[[GrowlMusicVideoWindowController alloc] initWithTitle:title text:text icon:icon priority:prio sticky:sticky] autorelease];
}

- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	int sizePref;
	NSRect sizeRect;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		sizeRect = NSMakeRect( 0.0f, 0.0f, NSWidth([[NSScreen mainScreen]frame]), 192.0f );
	} else {
		sizeRect = NSMakeRect( 0.0f, 0.0f, NSWidth([[NSScreen mainScreen]frame]), 96.0f );
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
			range:NSMakeRange(0U, [tempText length])];
	[view setText:tempText];
	
	[view setIcon:icon];
	panelFrame = [view frame];
	[panel setFrame:panelFrame display:NO];

	topLeftPosition = 0.0f;
	[panel setFrameTopLeftPoint:NSMakePoint(0.0f, topLeftPosition)];

	if ( (self = [super initWithWindow:panel]) ) {
		autoFadeOut = YES;	// !sticky
		target = nil;
		action = NULL;
		displayTime = MIN_DISPLAY_TIME;
		priority = prio;
		if (sizePref == MUSICVIDEO_SIZE_HUGE) {
			timerInterval = (1.0 / 128.0);
			fadeIncrement = 6.0f;
		} else {
			timerInterval = (1.0 / 64.0);
			fadeIncrement = 6.0f;
		}
	}

	return self;
}

- (void) dealloc {
	[target release];

	[super dealloc];
}

- (void) _fadeIn:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	NSRect theFrame = [myWindow frame];
	if ( topLeftPosition < NSHeight(theFrame) ) {
		topLeftPosition += fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(0.0f, topLeftPosition)];
	} else {
		[self _stopTimer];
		if ( autoFadeOut ) {
			if ( delegate && [delegate respondsToSelector:@selector( didFadeIn: )] ) {
				[delegate didFadeIn:self];
			}
			[self _waitBeforeFadeOut];
		}
	}
}

- (void) _fadeOut:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	if ( topLeftPosition > 0.0f ) {
		topLeftPosition -= fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(0.0f, topLeftPosition)];
	} else {
		[self _stopTimer];
		if ( delegate && [delegate respondsToSelector:@selector( didFadeOut: )] ) {
			[delegate didFadeOut:self];
		}
		[self close]; // close our window
		[self autorelease]; // we retained when we fade in
	}
}

- (void) _musicVideoClicked:(id)sender {
	if ( target && action && [target respondsToSelector:action] ) {
		[target performSelector:action withObject:self];
	}
	[self startFadeOut];
}

- (id)target {
	return target;
}

- (void)setTarget:(id)object {
	[target autorelease];
	target = [object retain];
}

- (SEL)action {
	return action;
}

- (void)setAction:(SEL)selector {
	action = selector;
}

- (int)priority {
	return priority;
}

- (void)setPriority:(int)newPriority {
	priority = newPriority;
}
@end
