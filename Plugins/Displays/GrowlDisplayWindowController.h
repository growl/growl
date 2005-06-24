//
//  GrowlDisplayWindowController.h
//  Display Plugins
//
//  Created by Mac-arena the Bored Zo on 2005-06-03.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

@interface GrowlDisplayWindowController : NSWindowController
{
	SEL            action;
	id             target;
	id             clickContext;
	NSString      *appName;
	//appPid declared below
	id             delegate;

	NSTimer       *displayTimer;
	NSTimeInterval displayDuration;
	unsigned       screenNumber;
	pid_t          appPid;
	unsigned       WCReserved: 31;
	unsigned       screenshotMode: 1;
}

- (void) takeScreenshot;

/*call these from subclasses as various phases of display occur.
 *for example, in GrowlDisplayFadingWindowController:
 *	* -startFadeIn  calls -willDisplayNotification
 *	* -stopFadeIn   calls  -didDisplayNotification
 *	* -startFadeOut calls -willTakeDownNotification
 *	* -stopFadeOut  calls  -didTakeDownNotification
 */
- (void) willDisplayNotification;
- (void)  didDisplayNotification;
- (void) willTakeDownNotification;
- (void)  didTakeDownNotification;

#pragma mark -

- (void) startDisplayTimer;
- (void)  stopDisplayTimer;

#pragma mark -

- (NSTimeInterval) displayDuration;
- (void) setDisplayDuration:(NSTimeInterval) newDuration;

- (enum displayPhase) displayPhase;

- (BOOL) screenshotModeEnabled;
- (void) setScreenshotModeEnabled:(BOOL) newScreenshotMode;

- (NSScreen *) screen;
- (void) setScreen:(NSScreen) newScreen;

- (id) target;
- (void) setTarget:(id) object;

- (SEL) action;
- (void) setAction:(SEL) selector;

- (NSString *) notifyingApplicationName;
- (void) setNotifyingApplicationName:(NSString *) inAppName;

- (pid_t) notifyingApplicationProcessIdentifier;
- (void) setNotifyingApplicationProcessIdentifier:(pid_t) inAppPid;

- (id) clickContext;
- (void) setClickContext:(id) clickContext;

- (void) addNotificationObserver:(id) observer;
- (void) removeNotificationObserver:(id) observer;

- (id) delegate;
- (void) setDelegate:(id) newDelegate;

@end

extern NSString *GrowlDisplayWindowControllerWillDisplayWindowNotification;
extern NSString *GrowlDisplayWindowControllerDidDisplayWindowNotification;
extern NSString *GrowlDisplayWindowControllerWillTakeDownWindowNotification;
extern NSString *GrowlDisplayWindowControllerDidTakeDownWindowNotification;
