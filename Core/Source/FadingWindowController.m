//
//  FadingWindowController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 16.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "FadingWindowController.h"
#import "GrowlController.h"

#define TIMER_INTERVAL (1.0 / 30.0)
#define FADE_INCREMENT 0.05f

@implementation FadingWindowController
- (id) initWithWindow:(NSWindow *)window {
	if ( (self = [super initWithWindow:window]) ) {
		delegate = nil;
		animationTimer = nil;
		autoFadeOut = NO;
		doFadeIn = YES;
		fadeIncrement = FADE_INCREMENT;
		timerInterval = TIMER_INTERVAL;
	}
	return self;
}

- (void) _stopTimer {
	[animationTimer invalidate];
	[animationTimer release];
	animationTimer = nil;
}

- (void) dealloc
{
	[self _stopTimer];
	[super dealloc];
}

- (void) _waitBeforeFadeOut {
	animationTimer = [[NSTimer scheduledTimerWithTimeInterval:displayTime
													   target:self
													 selector:@selector(startFadeOut)
													 userInfo:nil
													  repeats:NO] retain];
}

- (void) _fadeIn:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if ( alpha < 1.0f ) {
		[myWindow setAlphaValue: alpha + fadeIncrement];
	} else {
		[self stopFadeIn];
	}
}

- (void) _fadeOut:(NSTimer *)inTimer {
	NSWindow *myWindow = [self window];
	float alpha = [myWindow alphaValue];
	if ( alpha > 0.0f ) {
		[myWindow setAlphaValue: alpha - fadeIncrement];
	} else {
		if ( delegate && [delegate respondsToSelector:@selector(didFadeOut:)] ) {
			[delegate didFadeOut:self];
		}
		[self stopFadeOut];
	}
}

- (void) startFadeIn {
	if ( delegate && [delegate respondsToSelector:@selector(willFadeIn:)] ) {
		[delegate willFadeIn:self];
	}
	[self retain]; // release after fade out
	[self showWindow:nil];
	[self _stopTimer];
	if ( doFadeIn ) {
		animationTimer = [[NSTimer scheduledTimerWithTimeInterval:timerInterval
														   target:self
														 selector:@selector(_fadeIn:)
														 userInfo:nil
														  repeats:YES] retain];
	} else {
		[self stopFadeIn];
	}
}

- (void) stopFadeIn {
	[self _stopTimer];
	if ( delegate && [delegate respondsToSelector:@selector(didFadeIn:)] ) {
		[delegate didFadeIn:self];
	}
	if(screenshotMode) [self takeScreenshot];
	if ( autoFadeOut ) {
		[self _waitBeforeFadeOut];
	}
}

- (void) startFadeOut {
	if ( delegate && [delegate respondsToSelector:@selector(willFadeOut:)] ) {
		[delegate willFadeOut:self];
	}
	[self _stopTimer];
	animationTimer = [[NSTimer scheduledTimerWithTimeInterval:timerInterval
													   target:self
													 selector:@selector(_fadeOut:)
													 userInfo:nil
													  repeats:YES] retain];
	//Start immediately
	[self _fadeOut:nil];
}

- (void) stopFadeOut {
	[self _stopTimer];
	[self close]; // close our window
	[self autorelease]; // we retained when we fade in
}

#pragma mark -

- (BOOL)automaticallyFadeOut {
	return autoFadeOut;
}

- (void)setAutomaticallyFadesOut:(BOOL) autoFade {
	autoFadeOut = autoFade;
}

#pragma mark -

- (float)fadeIncrement {
	return fadeIncrement;
}

- (void)setFadeIncrement:(float) increment {
	fadeIncrement = increment;
}

#pragma mark -

- (float)timerInterval {
	return timerInterval;
}

- (void)setTimerInterval:(float) interval {
	timerInterval = interval;
}

#pragma mark -

- (double)displayTime {
	return displayTime;
}

- (void)setDisplayTime:(double) t {
	displayTime = t;
}

#pragma mark -

- (id) delegate {
	return delegate;
}

- (void) setDelegate:(id) object {
	delegate = object;
}

#pragma mark -

- (BOOL) screenshotModeEnabled {
	return screenshotMode;
}

- (void) setScreenshotModeEnabled:(BOOL)newScreenshotMode {
	screenshotMode = newScreenshotMode;
}

- (void)takeScreenshot {
	NSWindow *window = [self window];

	NSRect frame = [window frame];
	frame.origin = NSZeroPoint;

	NSImage *image = [[NSImage alloc] initWithSize:frame.size];
	[image lockFocus];
	[[window contentView] drawRect:frame];
	NSData *TIFF = [image TIFFRepresentation];
	[image unlockFocus];
	[image release];

	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithData:TIFF];
	NSData *PNG = [bitmap representationUsingType:NSPNGFileType
									   properties:nil];
	[bitmap release];

	GrowlController *growlController = [GrowlController standardController];
	NSString *path = [[[growlController screenshotsDirectory] stringByAppendingPathComponent:[growlController nextScreenshotName]] stringByAppendingPathExtension:@"png"];
	[PNG writeToFile:path atomically:NO];
}

#pragma mark -

- (BOOL) respondsToSelector:(SEL) selector {
	BOOL contentViewRespondsToSelector = [[[self window] contentView] respondsToSelector:selector];
	return contentViewRespondsToSelector ? contentViewRespondsToSelector : [super respondsToSelector:selector];
}

- (void) forwardInvocation:(NSInvocation *) invocation {
	NSView *contentView = [[self window] contentView];
	if ( [contentView respondsToSelector:[invocation selector]] ) {
		[invocation invokeWithTarget:contentView];
	} else {
		[super forwardInvocation:invocation];
	}
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) selector {
	NSView *contentView = [[self window] contentView];
	if ( [contentView respondsToSelector:selector] ) {
		return [contentView methodSignatureForSelector:selector];
	} else {
		return [super methodSignatureForSelector:selector];
	}
}
@end
