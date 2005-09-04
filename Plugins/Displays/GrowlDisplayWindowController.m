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
#import "NSViewAdditions.h"

static void stopDisplay(CFRunLoopTimerRef timer, void *context) {
#pragma unused(timer)
	[(GrowlDisplayWindowController *)context stopDisplay];
}

@implementation GrowlDisplayWindowController

- (id) init {
	if ((self = [super init])) {
		windowTransitions = [[NSMutableArray alloc] init];
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
	[windowTransitions	 release];

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

- (void) startDisplay {
	[self willDisplayNotification];
	[[self window] orderFront:nil];
	[self  didDisplayNotification];
}

- (void) stopDisplay {
	[self willTakeDownNotification];
	[[self window] orderOut:nil];
	[self  didTakeDownNotification];
}

#pragma mark -
#pragma mark Display stages

- (void) willDisplayNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayWindowControllerWillDisplayWindowNotification object:self];
}
- (void)  didDisplayNotification {
	if (screenshotMode)
		[self takeScreenshot];

	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayWindowControllerDidDisplayWindowNotification object:self];
}
- (void) willTakeDownNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayWindowControllerWillTakeDownWindowNotification object:self];
}
- (void)  didTakeDownNotification {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (clickContext) {
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			clickContext, GROWL_KEY_CLICKED_CONTEXT,
			appPid,       GROWL_APP_PID,
			nil];
		[nc postNotificationName:GROWL_NOTIFICATION_TIMED_OUT
						  object:appName
						userInfo:userInfo];
		[userInfo release];

		//Avoid duplicate click messages by immediately clearing the clickContext
		clickContext = nil;
	}

	[nc postNotificationName:GrowlDisplayWindowControllerWillDisplayWindowNotification object:self];
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

- (void) notificationClicked:(id) sender {
#pragma unused(sender)
	if (clickContext) {
		NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:
			clickHandlerEnabled,                          @"ClickHandlerEnabled",
			clickContext,                                 GROWL_KEY_CLICKED_CONTEXT,
			[self notifyingApplicationProcessIdentifier], GROWL_APP_PID,
			nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:[self notifyingApplicationName]
														  userInfo:userInfo];
		[userInfo release];

		//Avoid duplicate click messages by immediately clearing the clickContext
		[self setClickContext:nil];
	}

	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];
}

#pragma mark -
#pragma mark Window Transitions

- (void) addTransition:(GrowlWindowTransition *)transition {
	[transition setWindow:[self window]];
	[transition setDelegate:self];
	[windowTransitions addObject:transition];
}

- (void) removeTransition:(GrowlWindowTransition *)transition {
	[windowTransitions removeObject:transition];
	[transition setDelegate:nil];
	[transition setWindow:nil];
}

- (NSArray *) allTransitions {
	return windowTransitions;
}

- (NSArray *) activeTransitions {
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[windowTransitions count]];
	NSEnumerator *enumerator = [windowTransitions objectEnumerator];
	GrowlWindowTransition *transition;

	while ((transition = [enumerator nextObject]))
		if ([transition isAnimating])
			[result addObject:transition];

	return [result autorelease];
}

- (NSArray *) inactiveTransitions {
	NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:[windowTransitions count]];
	NSEnumerator *enumerator = [windowTransitions objectEnumerator];
	GrowlWindowTransition *transition;

	while ((transition = [enumerator nextObject]))
		if (![transition isAnimating])
			[result addObject:transition];

	return [result autorelease];
}

- (void) startAllTransitions {
	[windowTransitions makeObjectsPerformSelector:@selector(startAnimation)];
}

- (void) startAllTransitionsOfKind:(Class)transitionsClass {
	NSEnumerator *enumerator = [windowTransitions objectEnumerator];
	GrowlWindowTransition *transition;

	while ((transition = [enumerator nextObject]))
		if ([transition isKindOfClass:transitionsClass])
			[transition startAnimation];
}

- (void) stopAllTransitions {
	[windowTransitions makeObjectsPerformSelector:@selector(stopAnimation)];
}

- (void) stopAllTransitionsOfKind:(Class)transitionsClass {
	NSEnumerator *enumerator = [windowTransitions objectEnumerator];
	GrowlWindowTransition *transition;

	while ((transition = [enumerator nextObject]))
		if ([transition isKindOfClass:transitionsClass])
			[transition stopAnimation];
}

#pragma mark -
#pragma mark Accessors

- (NSTimeInterval) displayDuration {
	return displayDuration;
}

- (void) setDisplayDuration:(NSTimeInterval) newDuration {
	displayDuration = newDuration;
}

#pragma mark -

- (BOOL) screenshotModeEnabled {
	return screenshotMode;
}

- (void) setScreenshotModeEnabled:(BOOL) newScreenshotMode {
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
- (void) setScreen:(NSScreen *) newScreen {
	unsigned newScreenNumber = [[NSScreen screens] indexOfObjectIdenticalTo:newScreen];
	if (newScreenNumber == NSNotFound)
		[NSException raise:NSInternalInconsistencyException format:@"Tried to set %@ %p to a screen %p that isn't in the screen list", [self class], self, newScreen];
	[self willChangeValueForKey:@"screenNumber"];
	screenNumber = newScreenNumber;
	[self  didChangeValueForKey:@"screenNumber"];
}

- (void) setScreenNumber:(unsigned) newScreenNumber {
	screenNumber = newScreenNumber;
}

#pragma mark -

- (id) target {
	return target;
}

- (void) setTarget:(id) object {
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

- (void) setNotifyingApplicationName:(NSString *) inAppName {
	if (inAppName != appName) {
		[appName release];
		appName = [inAppName copy];
	}
}

#pragma mark -

- (NSNumber *) notifyingApplicationProcessIdentifier {
	return appPid;
}

- (void) setNotifyingApplicationProcessIdentifier:(NSNumber *) inAppPid {
	if (inAppPid != appPid) {
		[appPid release];
		appPid = [inAppPid retain];
	}
}

#pragma mark -

- (id) clickContext {
	return clickContext;
}

- (void) setClickContext:(id) inClickContext {
	[clickContext autorelease];
	clickContext = [inClickContext retain];
}

#pragma mark -

- (id) delegate {
	return delegate;
}
- (void) setDelegate:(id) newDelegate {
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

- (void) setClickHandlerEnabled:(NSNumber *) flag {
	if (flag != clickHandlerEnabled) {
		[clickHandlerEnabled release];
		clickHandlerEnabled = [flag retain];
	}
}

#pragma mark -

- (void) addNotificationObserver:(id) observer {
	NSParameterAssert(observer != nil);

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	if (observer) {
		//register the new delegate.
		if ([observer respondsToSelector:@selector(displayWindowControllerWillDisplayWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerWillDisplayWindow:)
					   name:GrowlDisplayWindowControllerWillDisplayWindowNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerDidDisplayWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerDidDisplayWindow:)
					   name:GrowlDisplayWindowControllerDidDisplayWindowNotification
					 object:self];

		if ([observer respondsToSelector:@selector(displayWindowControllerWillTakeDownWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerWillTakeDownWindow:)
					   name:GrowlDisplayWindowControllerWillTakeDownWindowNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerDidTakeDownWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerDidTakeDownWindow:)
					   name:GrowlDisplayWindowControllerDidTakeDownWindowNotification
					 object:self];
	}
}
- (void) removeNotificationObserver:(id) observer {
	[[NSNotificationCenter defaultCenter] removeObserver:observer
													name:nil
												  object:self];
}

@end
