//
//  GrowlDisplayWindowController.m
//  Display Plugins
//
//  Created by Mac-arena the Bored Zo on 2005-06-03.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefines.h"
#import "GrowlWindowTransition.h"
#import "GrowlPositionController.h"
#import "NSViewAdditions.h"

#define GrowlDisplayWindowControllerWillDisplayWindowNotification	CFSTR("GrowlDisplayWindowControllerWillDisplayWindowNotification")
#define GrowlDisplayWindowControllerDidDisplayWindowNotification	CFSTR("GrowlDisplayWindowControllerDidDisplayWindowNotification")
#define GrowlDisplayWindowControllerWillTakeDownWindowNotification	CFSTR("GrowlDisplayWindowControllerWillTakeDownWindowNotification")
#define GrowlDisplayWindowControllerDidTakeDownWindowNotification	CFSTR("GrowlDisplayWindowControllerDidTakeDownWindowNotification")
#define GrowlDisplayWindowControllerNotificationBlockedNotification	CFSTR("GrowlDisplayWindowControllerNotificationBlockedNotification")

static void stopDisplay(CFRunLoopTimerRef timer, void *context) {
#pragma unused(timer)
	[(GrowlDisplayWindowController *)context stopDisplay];
}

@implementation GrowlDisplayWindowController

- (id) initWithWindow:(NSWindow *)window {
	if ((self = [super initWithWindow:window])) {
		windowTransitions = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
		ignoresOtherNotifications = NO;
	}

	return self;
}

- (void) dealloc {
	[self stopDisplayTimer];

	[self setDelegate:nil];

	[target              release];
	[clickContext        release];
	[clickHandlerEnabled release];
	[appName             release];
	[appPid              release];
	CFRelease(windowTransitions);

	[super dealloc];
}

#pragma mark -
#pragma mark Screenshot mode

- (void) takeScreenshot {
	NSView *view = [[self window] contentView];
	NSString *path = [[GrowlPathUtilities_screenshotsDirectory() stringByAppendingPathComponent:GrowlPathUtilities_nextScreenshotName()] stringByAppendingPathExtension:@"png"];
	[[view dataWithPNGInsideRect:[view frame]] writeToFile:path atomically:NO];
}

#pragma mark -
#pragma mark Display control

- (BOOL) startDisplay {
	NSWindow *window = [self window];

	//Make sure we don't cover any other notification (or not)
	if (ignoresOtherNotifications || [[GrowlPositionController sharedInstance] reserveRect:[window frame] inScreen:[window screen]]) {
		[self willDisplayNotification];
		[window orderFront:nil];
		[self didDisplayNotification];
		return YES;
	} else {
		CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
											 GrowlDisplayWindowControllerNotificationBlockedNotification,
											 self, NULL, false);
		return NO;
	}
}

- (void) stopDisplay {
	NSWindow *window = [self window];
	
	[self willTakeDownNotification];
	[[GrowlPositionController sharedInstance] clearReservedRect:[window frame] inScreen:[window screen]];	//Clear the rect we reserved
	[window orderOut:nil];
	[self didTakeDownNotification];
}

#pragma mark -
#pragma mark Display stages

- (void) willDisplayNotification {
	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
										 GrowlDisplayWindowControllerWillDisplayWindowNotification,
										 self, NULL, false);
}

- (void) didDisplayNotification {
	if (screenshotMode)
		[self takeScreenshot];

	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
										 GrowlDisplayWindowControllerDidDisplayWindowNotification,
										 self, NULL, false);
}

- (void) willTakeDownNotification {
	CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
										 GrowlDisplayWindowControllerWillTakeDownWindowNotification,
										 self, NULL, false);
}

- (void) didTakeDownNotification {
	CFNotificationCenterRef center = CFNotificationCenterGetLocalCenter();
	if (clickContext) {
		CFMutableDictionaryRef userInfo = CFDictionaryCreateMutable(kCFAllocatorDefault, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(userInfo, GROWL_KEY_CLICKED_CONTEXT, clickContext);
		if (appPid)
			CFDictionarySetValue(userInfo, GROWL_APP_PID, appPid);
		CFNotificationCenterPostNotification(center,
											 (CFStringRef)GROWL_NOTIFICATION_TIMED_OUT,
											 appName, userInfo, false);
		CFRelease(userInfo);

		//Avoid duplicate click messages by immediately clearing the clickContext
		clickContext = nil;
	}

	CFNotificationCenterPostNotification(center,
										 GrowlDisplayWindowControllerWillDisplayWindowNotification,
										 self, NULL, false);
}

#pragma mark -
#pragma mark Display timer

- (void) startDisplayTimer {
	CFRunLoopTimerContext context = {0, self, NULL, NULL, NULL};
	displayTimer = CFRunLoopTimerCreate(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent()+displayDuration, 0, 0, 0, stopDisplay, &context);
	CFRunLoopAddTimer(CFRunLoopGetCurrent(), displayTimer, kCFRunLoopCommonModes);
}

- (void) stopDisplayTimer {
	if (displayTimer) {
		CFRunLoopTimerInvalidate(displayTimer);
		CFRelease(displayTimer);
		displayTimer = NULL;
	}
}

#pragma mark -
#pragma mark Click feedback

- (void) notificationClicked:(id)sender {
#pragma unused(sender)
	if (clickContext) {
		CFMutableDictionaryRef userInfo = CFDictionaryCreateMutable(kCFAllocatorDefault, 3, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		CFDictionarySetValue(userInfo, CFSTR("ClickHandlerEnabled"), clickHandlerEnabled);
		CFDictionarySetValue(userInfo, GROWL_KEY_CLICKED_CONTEXT, clickContext);
		if (appPid)
			CFDictionarySetValue(userInfo, GROWL_APP_PID, appPid);
		CFNotificationCenterPostNotification(CFNotificationCenterGetLocalCenter(),
											 (CFStringRef)GROWL_NOTIFICATION_CLICKED,
											 appName, userInfo, false);
		CFRelease(userInfo);

		//Avoid duplicate click messages by immediately clearing the clickContext
		clickContext = nil;
	}

	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];
}

#pragma mark -
#pragma mark Window Transitions

- (void) addTransition:(GrowlWindowTransition *)transition {
	[transition setWindow:[self window]];
	[transition setDelegate:self];
	CFArrayAppendValue(windowTransitions, transition);
}

- (void) removeTransition:(GrowlWindowTransition *)transition {
	CFIndex count = CFArrayGetCount(windowTransitions);
	for (CFIndex i=0; i<count;) {
		if (CFEqual(transition, CFArrayGetValueAtIndex(windowTransitions, i))) {
			CFArrayRemoveValueAtIndex(windowTransitions, i);
			--count;
		} else {
			++i;
		}
	}
	[transition setDelegate:nil];
	[transition setWindow:nil];
}

- (NSArray *) allTransitions {
	return (NSArray *)windowTransitions;
}

- (NSArray *) activeTransitions {
	CFIndex count = CFArrayGetCount(windowTransitions);
	CFMutableArrayRef result = CFArrayCreateMutable(kCFAllocatorDefault, count, &kCFTypeArrayCallBacks);

	for (CFIndex i=0; i<count; ++i) {
		GrowlWindowTransition *transition = (GrowlWindowTransition *)CFArrayGetValueAtIndex(windowTransitions, i);
		if ([transition isAnimating])
			CFArrayAppendValue(result, transition);
	}

	return [(NSArray *)result autorelease];
}

- (NSArray *) inactiveTransitions {
	CFIndex count = CFArrayGetCount(windowTransitions);
	CFMutableArrayRef result = CFArrayCreateMutable(kCFAllocatorDefault, count, &kCFTypeArrayCallBacks);

	for (CFIndex i=0; i<count; ++i) {
		GrowlWindowTransition *transition = (GrowlWindowTransition *)CFArrayGetValueAtIndex(windowTransitions, i);
		if (![transition isAnimating])
			CFArrayAppendValue(result, transition);
	}

	return [(NSArray *)result autorelease];
}

- (void) startAllTransitions {
	CFIndex count = CFArrayGetCount(windowTransitions);
	for (CFIndex i=0; i<count; ++i)
		[(GrowlWindowTransition *)CFArrayGetValueAtIndex(windowTransitions, i) startAnimation];
}

- (void) startAllTransitionsOfKind:(Class)transitionsClass {
	CFIndex count = CFArrayGetCount(windowTransitions);

	for (CFIndex i=0; i<count; ++i) {
		GrowlWindowTransition *transition = (GrowlWindowTransition *)CFArrayGetValueAtIndex(windowTransitions, i);
		if ([transition isKindOfClass:transitionsClass])
			[transition startAnimation];
	}
}

- (void) stopAllTransitions {
	CFIndex count = CFArrayGetCount(windowTransitions);
	for (CFIndex i=0; i<count; ++i)
		[(GrowlWindowTransition *)CFArrayGetValueAtIndex(windowTransitions, i) stopAnimation];
}

- (void) stopAllTransitionsOfKind:(Class)transitionsClass {
	CFIndex count = CFArrayGetCount(windowTransitions);
	
	for (CFIndex i=0; i<count; ++i) {
		GrowlWindowTransition *transition = (GrowlWindowTransition *)CFArrayGetValueAtIndex(windowTransitions, i);
		if ([transition isKindOfClass:transitionsClass])
			[transition stopAnimation];
	}
}

#pragma mark -
#pragma mark Accessors

- (CFTimeInterval) displayDuration {
	return displayDuration;
}

- (void) setDisplayDuration:(CFTimeInterval)newDuration {
	displayDuration = newDuration;
}

#pragma mark -

- (BOOL) screenshotModeEnabled {
	return screenshotMode;
}

- (void) setScreenshotModeEnabled:(BOOL)newScreenshotMode {
	screenshotMode = newScreenshotMode;
}

#pragma mark -

- (NSScreen *) screen {
	NSArray *screens = [NSScreen screens];
	if (screenNumber < [screens count])
		return [screens objectAtIndex:screenNumber];
	else
		return [NSScreen mainScreen];
}

- (void) setScreen:(NSScreen *)newScreen {
	unsigned newScreenNumber = [[NSScreen screens] indexOfObjectIdenticalTo:newScreen];
	if (newScreenNumber == NSNotFound)
		[NSException raise:NSInternalInconsistencyException format:@"Tried to set %@ %p to a screen %p that isn't in the screen list", [self class], self, newScreen];
	[self willChangeValueForKey:@"screenNumber"];
	screenNumber = newScreenNumber;
	[self  didChangeValueForKey:@"screenNumber"];
}

- (void) setScreenNumber:(unsigned)newScreenNumber {
	screenNumber = newScreenNumber;
}

#pragma mark -

- (id) target {
	return target;
}

- (void) setTarget:(id)object {
	if (object != target) {
		[target release];
		target = [object retain];
	}
}

#pragma mark -

- (SEL) action {
	return action;
}

- (void) setAction:(SEL) selector {
	action = selector;
}

#pragma mark -

- (NSString *) notifyingApplicationName {
	return appName;
}

- (void) setNotifyingApplicationName:(NSString *)inAppName {
	if (inAppName != appName) {
		[appName release];
		appName = [inAppName copy];
	}
}

#pragma mark -

- (NSNumber *) notifyingApplicationProcessIdentifier {
	return appPid;
}

- (void) setNotifyingApplicationProcessIdentifier:(NSNumber *)inAppPid {
	if (inAppPid != appPid) {
		[appPid release];
		appPid = [inAppPid retain];
	}
}

#pragma mark -

- (id) clickContext {
	return clickContext;
}

- (void) setClickContext:(id)inClickContext {
	if (clickContext != inClickContext) {
		[clickContext release];
		clickContext = [inClickContext retain];
	}
}

#pragma mark -

- (BOOL) ignoresOtherNotifications {
	return ignoresOtherNotifications;
}

- (void) setIgnoresOtherNotifications:(BOOL)flag {
	ignoresOtherNotifications = flag;
}

#pragma mark -

- (id) delegate {
	return delegate;
}

- (void) setDelegate:(id)newDelegate {
	if (delegate)
		[self removeNotificationObserver:delegate];

	if (newDelegate)
		[self addNotificationObserver:newDelegate];

	delegate = newDelegate;
}

#pragma mark -

- (NSNumber *) clickHandlerEnabled {
	return clickHandlerEnabled;
}

- (void) setClickHandlerEnabled:(NSNumber *)flag {
	if (flag != clickHandlerEnabled) {
		[clickHandlerEnabled release];
		clickHandlerEnabled = [flag retain];
	}
}

#pragma mark -

- (void) addNotificationObserver:(id)observer {
	NSParameterAssert(observer != nil);

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	if (observer) {
		//register the new delegate.
		if ([observer respondsToSelector:@selector(displayWindowControllerWillDisplayWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerWillDisplayWindow:)
					   name:(NSString *)GrowlDisplayWindowControllerWillDisplayWindowNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerDidDisplayWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerDidDisplayWindow:)
					   name:(NSString *)GrowlDisplayWindowControllerDidDisplayWindowNotification
					 object:self];

		if ([observer respondsToSelector:@selector(displayWindowControllerWillTakeDownWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerWillTakeDownWindow:)
					   name:(NSString *)GrowlDisplayWindowControllerWillTakeDownWindowNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerDidTakeDownWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerDidTakeDownWindow:)
					   name:(NSString *)GrowlDisplayWindowControllerDidTakeDownWindowNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerNotificationBlocked:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerNotificationBlocked:)
					   name:(NSString *)GrowlDisplayWindowControllerNotificationBlockedNotification
					 object:self];
	}
}
- (void) removeNotificationObserver:(id)observer {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetLocalCenter(),
									   observer,
									   NULL,
									   self);
}

@end
