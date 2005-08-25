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

#pragma mark -
#pragma mark Timer callbacks

static void fadeInTimer(CFRunLoopTimerRef timer, void *info) {
	GrowlDisplayFadingWindowController *controller = (GrowlDisplayFadingWindowController *)info;
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	double progress = (now - [controller animationStart]) / [controller animationDuration];
	BOOL finished = (progress > (1.0 - DBL_EPSILON));
	if (finished) progress = 1.0; //in case progress > 1.0
	[controller fadeInAnimation:progress];
	if (finished)
		[controller stopFadeIn];
	else
		CFRunLoopTimerSetNextFireDate(timer, now + CFRunLoopTimerGetInterval(timer));
}

static void fadeOutTimer(CFRunLoopTimerRef timer, void *info) {
	GrowlDisplayFadingWindowController *controller = (GrowlDisplayFadingWindowController *)info;
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	double progress = (now - [controller animationStart]) / [controller animationDuration];
	BOOL finished = (progress > (1.0 - DBL_EPSILON));
	if (finished) progress = 1.0; //in case progress > 1.0
	[controller fadeOutAnimation:progress];
	if (finished)
		[controller stopFadeOut];
	else
		CFRunLoopTimerSetNextFireDate(timer, now + CFRunLoopTimerGetInterval(timer));
}

#pragma mark -

@implementation GrowlDisplayFadingWindowController

- (id) initWithWindow:(NSWindow *)window {
	if ((self = [super initWithWindow:window])) {
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

	CFRunLoopTimerContext context = {0, self, NULL, NULL, NULL};
	animationStart = CFAbsoluteTimeGetCurrent();
	fadeTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, animationStart+fadeInInterval, fadeInInterval, 0, 0, fadeInTimer, &context);
	CFRunLoopAddTimer(CFRunLoopGetCurrent(), fadeTimer, kCFRunLoopCommonModes);
	//Start immediately
	fadeInTimer(fadeTimer, self);
}
- (void) startFadeOutTimer {
	[self stopFadeTimer];

	CFRunLoopTimerContext context = {0, self, NULL, NULL, NULL};
	animationStart = CFAbsoluteTimeGetCurrent();
	fadeTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, animationStart+fadeOutInterval, fadeOutInterval, 0, 0, fadeOutTimer, &context);
	CFRunLoopAddTimer(CFRunLoopGetCurrent(), fadeTimer, kCFRunLoopCommonModes);
	//Start immediately
	fadeOutTimer(fadeTimer, self);
}
- (void) stopFadeTimer {
	if (fadeTimer) {
        CFRunLoopTimerInvalidate(fadeTimer);
        CFRelease(fadeTimer);
		fadeTimer = NULL;
	}
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
	[self stopDisplayTimer];
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
	if (!isFadingOut) {
		[super notificationClicked:sender];
		[self stopDisplay];
	}
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

- (CFAbsoluteTime) animationDuration {
	return animationDuration;
}

- (void) setAnimationDuration:(CFAbsoluteTime)duration {
	animationDuration = duration;
}

#pragma mark -

- (CFAbsoluteTime) animationStart {
	return animationStart;
}

#pragma mark -

- (BOOL) isFadingIn {
	return isFadingIn;
}

- (BOOL) isFadingOut {
	return isFadingOut;
}

#pragma mark -

- (BOOL) didFadeIn {
	return didFadeIn;
}

- (BOOL) didFadeOut {
	return didFadeOut;
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
