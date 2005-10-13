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
#import "NSWindow+Transforms.h"

@implementation GrowlMusicVideoWindowController

- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)prio identifier:(NSString *)ident {
	identifier = [ident retain];

	int sizePref = MUSICVIDEO_SIZE_NORMAL;
	float duration = MUSICVIDEO_DEFAULT_DURATION;

	unsigned screenNumber = 0U;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, MusicVideoPrefDomain, &screenNumber);
	[self setScreen:[[NSScreen screens] objectAtIndex:screenNumber]];

	NSRect sizeRect;
	NSRect screen = [[self screen] frame];
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	sizeRect.origin = screen.origin;
	sizeRect.size.width = screen.size.width;
	if (sizePref == MUSICVIDEO_SIZE_HUGE)
		sizeRect.size.height = 192.0f;
	else
		sizeRect.size.height = 96.0f;
	frameHeight = sizeRect.size.height;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, MusicVideoPrefDomain, &duration);
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, MusicVideoPrefDomain, &sizePref);
	NSPanel *panel = [[NSPanel alloc] initWithContentRect:sizeRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:NO];
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
	[panel setOneShot:YES];
	[panel useOptimizedDrawing:YES];
	//[panel setReleasedWhenClosed:YES]; // ignored for windows owned by window controllers.
	//[panel setDelegate:self];

	subview = [[GrowlMusicVideoWindowView alloc] initWithFrame:panelFrame];

	[subview setTarget:self];
	[subview setAction:@selector(notificationClicked:)]; // Not used for now

	[panel setContentView:subview]; // retains subview
	[subview release];

	[subview setPriority:prio];
	[subview setTitle:title];
	[self setText:text];
	[subview setIcon:icon];

	frameY = -frameHeight;
	[subview translateOriginToPoint:NSMakePoint(0.0f, frameY)];

	if ((self = [super initWithWindow:panel])) {
		autoFadeOut = YES;
		[self setDisplayDuration:duration];
		priority = prio;
		animationDuration = 0.25;
	}

	return self;
}

#pragma mark -
#pragma mark Fading

- (void) stopFadeIn {
	if (!doFadeIn) {
		[subview translateOriginToPoint:NSMakePoint(0.0f, -frameY)];
		frameY = 0.0f;
		[subview setNeedsDisplay:YES];
	}
	[super stopFadeIn];
}

- (void) fadeInAnimation:(double)progress {
	float oldY = frameY;
	frameY = frameHeight * (progress - 1.0f);
	[subview translateOriginToPoint:NSMakePoint(0.0f, frameY - oldY)];
	NSRect dirtyRect = [subview bounds];
	dirtyRect.size.height = ceilf(dirtyRect.size.height+frameY);
	[subview setNeedsDisplayInRect:dirtyRect];
}

- (void) fadeOutAnimation:(double)progress {
	float oldY = frameY;
	frameY = -frameHeight * progress;
	[subview translateOriginToPoint:NSMakePoint(0.0f, frameY - oldY)];
	NSRect dirtyRect = [subview bounds];
	dirtyRect.size.height = ceilf(dirtyRect.size.height+oldY);
	[subview setNeedsDisplayInRect:dirtyRect];
}

#pragma mark -

- (void) dealloc {
	[identifier    release];
	[[self window] release];
	[super dealloc];
}

#pragma mark Accessors

- (NSString *) identifier {
	return identifier;
}

#pragma mark -

- (int) priority {
	return priority;
}

- (void) setPriority:(int)newPriority {
	priority = newPriority;
	[subview setPriority:priority];
}

- (void) setTitle:(NSString *)title {
	[subview setTitle:title];
}

- (void) setText:(NSString *)text {
	// Sanity check to unify line endings
	NSMutableString	*tempText = [[NSMutableString alloc] initWithString:text];
	[tempText replaceOccurrencesOfString:@"\r"
							  withString:@"\n"
								 options:nil
								   range:NSMakeRange(0U, [tempText length])];
	[subview setText:tempText];
	[tempText release];
}

- (void) setIcon:(NSImage *)icon {
	[subview setIcon:icon];
}

@end
