//
//  GrowlMusicVideoWindowController.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoWindowView.h"
#import "GrowlMusicVideoPrefs.h"
#import "NSGrowlAdditions.h"

@implementation GrowlMusicVideoWindowController

+ (GrowlMusicVideoWindowController *)musicVideo {
	return [[[GrowlMusicVideoWindowController alloc] init] autorelease];
}

+ (GrowlMusicVideoWindowController *)musicVideoWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	return [[[GrowlMusicVideoWindowController alloc] initWithTitle:title text:text icon:icon priority:prio sticky:sticky] autorelease];
}

- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)prio sticky:(BOOL)sticky {
	int sizePref = MUSICVIDEO_SIZE_NORMAL;
	float duration = MUSICVIDEO_DEFAULT_DURATION;

	screenNumber = 0U;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, MusicVideoPrefDomain, &screenNumber);

	NSRect sizeRect;
	NSRect screen = [[self screen] frame];
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	sizeRect.origin = screen.origin;
	sizeRect.size.width = screen.size.width;
	if (sizePref == MUSICVIDEO_SIZE_HUGE) {
		sizeRect.size.height = 192.0f;
	} else {
		sizeRect.size.height = 96.0f;
	}
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, MusicVideoPrefDomain, &duration);
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
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

	topLeftPosition = screen.origin.y;
	[panel setFrameTopLeftPoint:NSMakePoint(screen.origin.x, topLeftPosition)];

	if ( (self = [super initWithWindow:panel]) ) {
		autoFadeOut = YES;	// !sticky
		displayTime = duration;
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
	[clickContext release];
	[appName release];
	[super dealloc];
}

#pragma mark -
#pragma mark Fading and click feedback

- (void) _fadeIn:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	NSRect screen = [[self screen] frame];
	NSRect theFrame = [myWindow frame];
	if ( topLeftPosition < screen.origin.y + NSHeight(theFrame) ) {
		topLeftPosition += fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(screen.origin.x, topLeftPosition)];
	} else {
		[self _stopTimer];
		if (screenshotMode) {
			[self takeScreenshot];
		}
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
	NSRect screen = [[self screen] frame];
	if ( topLeftPosition > screen.origin.y ) {
		topLeftPosition -= fadeIncrement;
		[myWindow setFrameTopLeftPoint:NSMakePoint(screen.origin.x, topLeftPosition)];
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

#pragma mark -
#pragma mark Accessors

- (id)target {
	return target;
}

- (void)setTarget:(id)object {
	[target autorelease];
	target = [object retain];
}

#pragma mark -

- (SEL)action {
	return action;
}

- (void)setAction:(SEL)selector {
	action = selector;
}

#pragma mark -

- (NSString *)appName {
	return appName;
}

- (void) setAppName:(NSString *) inAppName {
	[appName autorelease];
	appName = [inAppName retain];
}

#pragma mark -

- (id) clickContext {
	return clickContext;
}

- (void) setClickContext:(id)inClickContext {
	[clickContext autorelease];
	clickContext = [inClickContext retain];
}

#pragma mark -

- (int)priority {
	return priority;
}

- (void)setPriority:(int)newPriority {
	priority = newPriority;
}
@end
