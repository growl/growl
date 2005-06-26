//
//  GrowlDisplayFadingWindowController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 16.11.04.
//  Renamed from FadingWindowController by Mac-arena the Bored Zo on 2005-06-03.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@interface GrowlDisplayFadingWindowController : GrowlDisplayWindowController
{
	NSTimer         *fadeTimer;
	NSTimeInterval   fadeInInterval, fadeOutInterval;
	NSTimeInterval	 animationDuration;
	CFAbsoluteTime	 animationStart;
	float            fadeIncrement;

	unsigned         FWCReserved: 25;
	/*on deleting doFade{In,Out}:
	 *
	 *pro (by boredzo)
	 *I think these are unnecessary. GDWC provides for non-fading displays.
	 *if a display wants to do one but not the other, it can inherit from GDFWC
	 *	and call up to GDWC (skipping GDFWC's implementation) for the fade
	 *	it doesn't want to implement.
	 *
	 *con:
	 */
	unsigned         doFadeIn:     1; //VfD: +boredzo
	unsigned         doFadeOut:    1; //VfD: +boredzo
	unsigned         didFadeIn:    1;
	unsigned         didFadeOut:   1;
	unsigned         isFadingIn:   1;
	unsigned         isFadingOut:  1;
	unsigned         autoFadeOut:  1; //NO for sticky displays
}

- (void) startFadeIn;
- (void) startFadeOut;
- (void) stopFadeIn;
- (void) stopFadeOut;

- (void) startFadeInTimer;
- (void) startFadeOutTimer;
- (void) stopFadeTimer;
- (void) _waitBeforeFadeOut;

- (BOOL) automaticallyFadeOut;
- (void) setAutomaticallyFadesOut:(BOOL) autoFade;

- (NSTimeInterval) animationDuration;
- (void) setAnimationDuration:(NSTimeInterval)duration;

- (void) fadeInTimer:(NSTimer *)inTimer;
- (void) fadeOutTimer:(NSTimer *)inTimer;

- (void) fadeInAnimation:(double)progress;
- (void) fadeOutAnimation:(double)progress;

- (BOOL) isFadingIn;
- (BOOL) isFadingOut;

@end

@interface NSObject (FadingWindowControllerDelegate)
- (void) willFadeIn:(FadingWindowController *)controller;
- (void) didFadeIn:(FadingWindowController *)controller;

- (void) willFadeOut:(FadingWindowController *)controller;
- (void) didFadeOut:(FadingWindowController *)controller;
@end
