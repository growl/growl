//
//  GrowlWindowControllerAdditions.h
//  Display Plugins
//
//  Created by Ingmar Stein on 16.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FadingWindowController : NSWindowController
{
	id			delegate;
	NSTimer		*animationTimer;
	BOOL		autoFadeOut;
	BOOL		doFadeIn;
	float		fadeIncrement;
	float		timerInterval;
	double		displayTime;
}
- (void) startFadeIn;
- (void) startFadeOut;
- (void) stopFadeOut;

- (BOOL) automaticallyFadeOut;
- (void) setAutomaticallyFadesOut:(BOOL) autoFade;

- (float) fadeIncrement;
- (void) setFadeIncrement:(float)increment;

- (float) timerInterval;
- (void) setTimerInterval:(float)interval;

- (double) displayTime;
- (void) setDisplayTime:(double)t;

- (id) delegate;
- (void) setDelegate:(id)delegate;

- (void) _stopTimer;
- (void) _waitBeforeFadeOut;

- (void) _fadeIn:(NSTimer *)inTimer;
- (void) _fadeOut:(NSTimer *)inTimer;
@end

@interface NSObject (FadingWindowControllerDelegate)
- (void) willFadeIn:(FadingWindowController *)controller;
- (void) didFadeIn:(FadingWindowController *)controller;

- (void) willFadeOut:(FadingWindowController *)controller;
- (void) didFadeOut:(FadingWindowController *)controller;
@end
