//
//  GrowlDisplayWindowController.h
//  Display Plugins
//
//  Created by Mac-arena the Bored Zo on 2005-06-03.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GrowlWindowTransition;

@interface GrowlDisplayWindowController : NSWindowController {
	@private
	SEL					action;
	id					target;
	id					clickContext;
	NSNumber			*clickHandlerEnabled;
	NSString			*appName;
	NSNumber			*appPid;
	id					delegate;
	CFRunLoopTimerRef	displayTimer;
	CFMutableArrayRef	windowTransitions;
	BOOL				ignoresOtherNotifications;

	CFTimeInterval		displayDuration;
	unsigned			screenNumber;
	unsigned			screenshotMode: 1;
	
	@protected
	unsigned			WCReserved: 31;
}

- (void) takeScreenshot;

- (BOOL) startDisplay;
- (void) stopDisplay;
	
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
- (void) stopDisplayTimer;

#pragma mark -

- (void) addTransition:(GrowlWindowTransition *)transition;
- (void) removeTransition:(GrowlWindowTransition *)transition;

- (NSArray *) allTransitions;
- (NSArray *) activeTransitions;
- (NSArray *) inactiveTransitions;

- (void) startAllTransitions;
- (void) startAllTransitionsOfKind:(Class)transitionsClass;

- (void) stopAllTransitions;
- (void) stopAllTransitionsOfKind:(Class)transitionsClass;

#pragma mark -

- (CFTimeInterval) displayDuration;
- (void) setDisplayDuration:(CFTimeInterval) newDuration;

- (BOOL) screenshotModeEnabled;
- (void) setScreenshotModeEnabled:(BOOL) newScreenshotMode;

- (NSScreen *) screen;
- (void) setScreen:(NSScreen *) newScreen;

- (id) target;
- (void) setTarget:(id) object;

- (SEL) action;
- (void) setAction:(SEL) selector;

- (NSString *) notifyingApplicationName;
- (void) setNotifyingApplicationName:(NSString *) inAppName;

- (NSNumber *) notifyingApplicationProcessIdentifier;
- (void) setNotifyingApplicationProcessIdentifier:(NSNumber *) inAppPid;

- (id) clickContext;
- (void) setClickContext:(id) clickContext;

- (void) notificationClicked:(id) sender;

- (void) addNotificationObserver:(id) observer;
- (void) removeNotificationObserver:(id) observer;

- (id) delegate;
- (void) setDelegate:(id) newDelegate;

- (NSNumber *) clickHandlerEnabled;
- (void) setClickHandlerEnabled:(NSNumber *) flag;

- (BOOL) ignoresOtherNotifications;
- (void) setIgnoresOtherNotifications:(BOOL) flag;

@end

/*!
 * @category NSObject (GrowlDisplayWindowControllerDelegate)
 * Delegate methods for GrowlDisplayWindowController's delegate.
 */
@interface NSObject (GrowlDisplayWindowControllerDelegate)

/*!
 * @method displayWindowControllerWillDisplayWindow:
 * @abstract Called right before the notification's window is displayed.
 * @param notification A notification containing the GrowlDisplayWindowController which sent the notification.
 */
- (void)displayWindowControllerWillDisplayWindow:(NSNotification *)notification;

/*!
 * @method displayWindowControllerDidDisplayWindow:
 * @abstract Called right after the notification's window is displayed.
 * @param notification A notification containing the GrowlDisplayWindowController which sent the notification.
 */
- (void)displayWindowControllerDidDisplayWindow:(NSNotification *)notification;

/*!
 * @method displayWindowControllerWillTakeDownWindow:
 * @abstract Called right before the notification's window is hidden.
 * @param notification A notification containing the GrowlDisplayWindowController which sent the notification.
 */
- (void)displayWindowControllerWillTakeWindowDown:(NSNotification *)notification;

/*!
 * @method displayWindowControllerDidTakeDownWindow:
 * @abstract Called right after the notification's window was hidden.
 * @param notification A notification containing the GrowlDisplayWindowController which sent the notification.
 */
- (void)displayWindowControllerDidTakeWindowDown:(NSNotification *)notification;

/*!
 * @method displayWindowControllerNotificationBlocked:
 * @abstract Called whenever a notification can not be displayed.
 * @discussion A notification will be blocked only when it'll cover an already displayed notification.
 * You should relocate the notification in that case.
 * @param notification A notification containing the GrowlDisplayWindowController which sent the notification.
 */
- (void)displayWindowControllerNotificationBlocked:(NSNotification *)notification;

@end

