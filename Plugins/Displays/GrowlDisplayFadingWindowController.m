//
//  GrowlDisplayFadingWindowController.m
//  Display Plugins
//
//  Created by Ingmar Stein on 16.11.04.
//  Renamed from FadingWindowController by Mac-arena the Bored Zo on 2005-06-03.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefines.h"

#define TIMER_INTERVAL	0.01
#define DURATION		0.5

#define GrowlDisplayFadingWindowControllerWillFadeInNotification  @"GrowlDisplayFadingWindowControllerWillFadeInNotification"
#define GrowlDisplayFadingWindowControllerDidFadeInNotification   @"GrowlDisplayFadingWindowControllerDidFadeInNotification"
#define GrowlDisplayFadingWindowControllerWillFadeOutNotification @"GrowlDisplayFadingWindowControllerWillFadeOutNotification"
#define GrowlDisplayFadingWindowControllerDidFadeOutNotification  @"GrowlDisplayFadingWindowControllerDidFadeOutNotification"

@implementation GrowlDisplayFadingWindowController

- (id) initWithWindow:(NSWindow *)window {
	if ((self = [super initWithWindow:window])) {
		autoFadeOut = NO;
		doFadeIn = YES;
		doFadeOut = YES;
		animationDuration = DURATION;
		fadeInInterval = fadeOutInterval = TIMER_INTERVAL;
	}
	return self;
}

- (void) dealloc {
	[self stopFadeTimer];
	[super dealloc];
}

#pragma mark -
#pragma mark Timer control

- (void) startFadeInTimer {
	[self stopFadeTimer];

	animationStart = CFAbsoluteTimeGetCurrent();
	fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:fadeInInterval
												  target:self
												selector:@selector(fadeInTimer)
												userInfo:nil
												 repeats:YES] retain];
	//Start immediately
	[self fadeInTimer];
}
- (void) startFadeOutTimer {
	[self stopFadeTimer];

	animationStart = CFAbsoluteTimeGetCurrent();
	fadeTimer = [[NSTimer scheduledTimerWithTimeInterval:fadeOutInterval
												  target:self
												selector:@selector(fadeOutTimer)
												userInfo:nil
												 repeats:YES] retain];
	//Start immediately
	[self fadeOutTimer];
}
- (void) stopFadeTimer {
	[fadeTimer invalidate];
	[fadeTimer release];
	 fadeTimer = nil;
}

#pragma mark -
#pragma mark Timer callbacks

- (void) fadeInTimer {
	double progress = (CFAbsoluteTimeGetCurrent() - animationStart) / animationDuration;
	BOOL finished = (progress > (1.0 - DBL_EPSILON));
	if (finished) progress = 1.0; //in case progress > 1.0
	[self fadeInAnimation:progress];
	if (finished)
		[self stopFadeIn];
}

- (void) fadeOutTimer {
	double progress = (CFAbsoluteTimeGetCurrent() - animationStart) / animationDuration;
	BOOL finished = (progress > (1.0 - DBL_EPSILON));
	if (finished) progress = 1.0; //in case progress > 1.0
	[self fadeOutAnimation:progress];
	if (finished)
		[self stopFadeOut];
}

#pragma mark -
#pragma mark Fade steps

- (void) fadeInAnimation:(double)progress {
	[[self window] setAlphaValue:progress];
}

- (void) fadeOutAnimation:(double)progress {
	[[self window] setAlphaValue:1.0f - progress];
}

#pragma mark -
#pragma mark Fade control

- (void) startFadeIn {
	[self retain]; // release after fade out
	[self showWindow:nil];
	if (!isFadingIn)
		[self stopFadeTimer];
	if (doFadeIn && !didFadeIn) {
		if (!isFadingIn) {
			isFadingIn = YES;
			[self willDisplayNotification];
			[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayFadingWindowControllerWillFadeInNotification
																object:self];
			[self startFadeInTimer];
		}
	} else
		[self stopFadeIn];
}

- (void) stopFadeIn {
	isFadingIn = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayFadingWindowControllerDidFadeInNotification
														object:self];
	didFadeIn = YES;
	[self stopFadeTimer];
	[self didDisplayNotification];
	if (autoFadeOut)
		[self startDisplayTimer];
}

- (void) startFadeOut {
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayFadingWindowControllerWillFadeOutNotification
														object:self];
	[self stopFadeTimer];
	if (doFadeOut) {
		if (!isFadingOut) {
			isFadingOut = YES;
			[self startFadeOutTimer];
		}
	} else
		[self stopFadeOut];
}

- (void) stopFadeOut {
	isFadingOut = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayFadingWindowControllerDidFadeOutNotification
														object:self];
	[self stopFadeTimer];

	[self close];	// close our window
	[self didTakeDownNotification];
	[self release];	// we retained when we began fade in
}

#pragma mark -
#pragma mark Display control

- (void) startDisplay {
	if (!isFadingIn)
		[self startFadeIn]; //posts {will,did}DisplayNotification
}

- (void) stopDisplay {
	if (isFadingIn) {
		autoFadeOut = NO;
		[self stopFadeIn]; //posts didDisplayNotification
	}
	if (!isFadingOut)
		[self startFadeOut]; //posts {will,did}TakeDownNotification
}

#pragma mark -
#pragma mark Click feedback

- (void) notificationClicked:(id)sender {
	[super notificationClicked:sender];
	[self stopDisplay];
}

#pragma mark -
#pragma mark Accessors

- (BOOL) automaticallyFadeOut {
	return autoFadeOut;
}

- (void) setAutomaticallyFadesOut:(BOOL)autoFade {
	autoFadeOut = autoFade;
}

#pragma mark -

- (NSTimeInterval) animationDuration {
	return animationDuration;
}

- (void) setAnimationDuration:(NSTimeInterval)duration {
	animationDuration = duration;
}

#pragma mark -

- (BOOL) isFadingIn {
	return isFadingIn;
}

- (BOOL) isFadingOut {
	return isFadingOut;
}

#pragma mark -

- (id) delegate {
	return delegate;
}

- (void) setDelegate:(id)newDelegate {
	[super setDelegate:newDelegate];

	if (newDelegate) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

		if ([newDelegate respondsToSelector:@selector(displayWindowControllerWillFadeIn:)])
			[nc addObserver:newDelegate
				   selector:@selector(displayWindowControllerWillFadeIn:)
					   name:GrowlDisplayFadingWindowControllerWillFadeInNotification
					 object:self];
		if ([newDelegate respondsToSelector:@selector(displayWindowControllerDidFadeIn:)])
			[nc addObserver:newDelegate
				   selector:@selector(displayWindowControllerDidFadeIn:)
					   name:GrowlDisplayFadingWindowControllerDidFadeInNotification
					 object:self];

		if ([newDelegate respondsToSelector:@selector(displayWindowControllerWillFadeOut:)])
			[nc addObserver:newDelegate
				   selector:@selector(displayWindowControllerWillFadeOut:)
					   name:GrowlDisplayFadingWindowControllerWillFadeOutNotification
					 object:self];
		if ([newDelegate respondsToSelector:@selector(displayWindowControllerDidFadeOut:)])
			[nc addObserver:newDelegate
				   selector:@selector(displayWindowControllerDidFadeOut:)
					   name:GrowlDisplayFadingWindowControllerDidFadeOutNotification
					 object:self];
	}
}

@end
