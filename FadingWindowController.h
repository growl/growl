//
//  GrowlWindowControllerAdditions.h
//  Display Plugins
//
//  Created by Ingmar Stein on 16.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FadingWindowController : NSWindowController
{
	id				_delegate;
	NSTimer			*_animationTimer;
	BOOL			_autoFadeOut;
	BOOL			_doFadeIn;
	float			_fadeIncrement;
	float			_timerInterval;
	double			_displayTime;
}
- (void)startFadeIn;
- (void)startFadeOut;
- (void)stopFadeOut;

- (BOOL)automaticallyFadeOut;
- (void)setAutomaticallyFadesOut:(BOOL) autoFade;

- (float)fadeIncrement;
- (void)setFadeIncrement:(float)increment;

- (float)timerInterval;
- (void)setTimerInterval:(float)interval;

- (double)displayTime;
- (void)setDisplayTime:(double)t;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (void)_stopTimer;
- (void)_waitBeforeFadeOut;
@end

@interface NSObject (FadingWindowControllerDelegate)
- (void)willFadeIn:(FadingWindowController *)controller;
- (void)didFadeIn:(FadingWindowController *)controller;

- (void)willFadeOut:(FadingWindowController *)controller;
- (void)didFadeOut:(FadingWindowController *)controller;
@end
