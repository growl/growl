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
		topLeftPosition = 192.0f;
	} else {
		sizeRect.size.height = 96.0f;
		topLeftPosition = 96.0f;
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
	[view setAction:@selector(_notificationClicked:)]; // Not used for now
	[panel setContentView:view];

	[view setTitle:title];
	// Sanity check to unify line endings
	NSMutableString	*tempText = [NSMutableString stringWithString:text];
	[tempText replaceOccurrencesOfString:@"\r"
			withString:@"\n"
			options:nil
			range:NSMakeRange(0U, [tempText length])];
	[view setText:tempText];

	[view setIcon:icon];
	panelFrame = [view frame];
	//[panel setFrame:panelFrame display:NO];

	//topLeftPosition = screen.origin.y;
	//[panel setFrameTopLeftPoint:NSMakePoint(screen.origin.x, topLeftPosition)];
	frameHeight = 0.0f;
	panelFrame.origin = screen.origin;
	panelFrame.size.width = screen.size.width;
	panelFrame.size.height = frameHeight;
	[panel setFrame:panelFrame display:NO];

	if ((self = [super initWithWindow:panel])) {
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

#pragma mark -
#pragma mark Fading

- (void) stopFadeIn {
	if (!doFadeIn) {
		NSWindow *myWindow = [self window];
		NSRect screen = [[self screen] frame];
		NSRect theFrame = [myWindow frame];
		frameHeight = topLeftPosition;
		theFrame.origin = screen.origin;
		theFrame.size.width = screen.size.width;
		theFrame.size.height = frameHeight;
		[myWindow setFrame:theFrame display:YES];
	}
	[super stopFadeIn];
}

- (void) _fadeIn:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	NSRect screen = [[self screen] frame];
	NSRect theFrame = [myWindow frame];
	if (frameHeight < topLeftPosition) {
		frameHeight += fadeIncrement;
		theFrame.origin = screen.origin;
		theFrame.size.width = screen.size.width;
		theFrame.size.height = frameHeight;
		[myWindow setFrame:theFrame display:YES];
	} else {
		[self stopFadeIn];
	}
}

- (void) _fadeOut:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	NSRect theFrame = [myWindow frame];
	NSRect screen = [[self screen] frame];
	if (frameHeight > 0.0f) {
		frameHeight -= fadeIncrement;
		theFrame.origin = screen.origin;
		theFrame.size.width = screen.size.width;
		theFrame.size.height = frameHeight;
		[myWindow setFrame:theFrame display:YES];
	} else {
		[self stopFadeOut];
	}
}

#pragma mark -
#pragma mark Accessors

#pragma mark -

- (int)priority {
	return priority;
}

- (void)setPriority:(int)newPriority {
	priority = newPriority;
}

@end
