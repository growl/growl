//
//  GrowlDisplayWindowController.m
//  Display Plugins
//
//  Created by Mac-arena the Bored Zo on 2005-06-03.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"
#import "GrowlPathUtilities.h"
#import "GrowlDefines.h"
#import "GrowlWindowTransition.h"
#import "GrowlPositionController.h"
#import "NSViewAdditions.h"
#import "GrowlNotificationDisplayBridge.h"
#import "GrowlApplicationNotification.h"

#include "GrowlLog.h"

static NSMutableDictionary *existingInstances;

@interface GrowlDisplayWindowController (PRIVATE)
- (void)cancelDisplayDelayedPerforms;
@end

@implementation GrowlDisplayWindowController

#pragma mark -
#pragma mark Caching

+ (void) registerInstance:(id)instance withIdentifier:(NSString *)ident {
	if (!existingInstances)
		existingInstances = [[NSMutableDictionary alloc] init];

	NSDictionary *classInstances = [existingInstances objectForKey:self];
	if (!classInstances) {
		classInstances = [[NSMutableDictionary alloc] init];
		[existingInstances setObject:classInstances forKey:self];
	}
	[classInstances setValue:instance forKey:ident];
}

+ (id) instanceWithIdentifier:(NSString *)ident {
	NSMutableDictionary *classInstances = [existingInstances objectForKey:self];
	if (classInstances)
		return [classInstances objectForKey:ident];
	else
		return nil;
}

+ (void) unregisterInstanceWithIdentifier:(NSString *)ident {
	NSMutableDictionary *classInstances = [existingInstances objectForKey:self];
	if (classInstances)
		[classInstances removeObjectForKey:ident];
}

#pragma mark -

- (id) initWithWindowNibName:(NSString *)windowNibName bridge:(GrowlNotificationDisplayBridge *)displayBridge {
	// NOTE: for completeness we ought to offer the other nib related init methods with the plugin as a param
	if ((self = [self initWithWindowNibName:windowNibName owner:displayBridge])) {
		[self setBridge:displayBridge]; // weak reference
	}
	return self;
}

- (id) initWithBridge:(GrowlNotificationDisplayBridge *)displayBridge {
	/* Subclasses using this method should call initWithWindowNibName: from init */
	if ((self = [self init])) {
		[self setBridge:displayBridge]; // weak reference
	}
	return self;
}

- (id) initWithWindow:(NSWindow *)window {
	if ((self = [super initWithWindow:window])) {
		windowTransitions = [[NSMutableDictionary alloc] init];
		ignoresOtherNotifications = NO;
		bridge = nil;
		startTimes = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntMapValueCallBacks, 0U);
		endTimes = NSCreateMapTable(NSObjectMapKeyCallBacks, NSIntMapValueCallBacks, 0U);
		transitionDuration = 1.0;
	}

	return self;
}

- (void) dealloc {
	[self setDelegate:nil];
	[[self bridge] removeObserver:self forKeyPath:@"notification"];

	NSFreeMapTable(startTimes);
	NSFreeMapTable(endTimes);

	[bridge				 release];
	[target              release];
	[clickContext        release];
	[clickHandlerEnabled release];
	[appName             release];
	[appPid              release];
	[windowTransitions   release];
	[notification        release];

	[super dealloc];
}

#pragma mark -
#pragma mark Screenshot mode

- (void) takeScreenshot {
	NSView *view = [[self window] contentView];
	NSString *path = [[[GrowlPathUtilities screenshotsDirectory] stringByAppendingPathComponent:[GrowlPathUtilities nextScreenshotName]] stringByAppendingPathExtension:@"png"];
	[[view dataWithPNGInsideRect:[view frame]] writeToFile:path atomically:NO];
}

#pragma mark -
#pragma mark Display control

- (BOOL)reposition_startingDisplay:(BOOL)shouldStartDisplay
{
	NSWindow *window = [self window];
	
	//Make sure we don't cover any other notification (or not)
	BOOL foundSpace = NO;
	GrowlPositionController *pc = [GrowlPositionController sharedInstance];
	if ([self respondsToSelector:@selector(idealOriginInRect:)])
		foundSpace = [pc positionDisplay:self];
	else
		foundSpace = (ignoresOtherNotifications || [pc reserveRect:[window frame] inScreen:[window screen] forDisplayController:self]);
	
	if (foundSpace) {
		if (shouldStartDisplay) {
			[self cancelDisplayDelayedPerforms];
			
			[self willDisplayNotification];
			
			[window orderFront:nil];
			
			if ([self startAllTransitions]) {
				[self performSelector:@selector(didFinishTransitionsBeforeDisplay)
						   withObject:nil
						   afterDelay:transitionDuration];
			} else {
				[self didFinishTransitionsBeforeDisplay];
			}
			
			[self didDisplayNotification];
		}
		
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayWindowControllerNotificationBlockedNotification
															object:self];
		
		//Try again in 10 seconds
		if (!shouldStartDisplay) {
			//If we're restarting, get this display off-screen while we wait
			//XXX This should be more fluid
			NSWindow *window = [self window];
			[window orderOut:nil];

			[[GrowlPositionController sharedInstance] clearReservedRectForDisplayController:self];
			
		}
		[self performSelector:@selector(startDisplay) withObject:nil afterDelay:5];
	}
	
	return foundSpace;		
	
}

- (BOOL) startDisplay {
	[self reposition_startingDisplay:YES];
}

- (void) stopDisplay {
	[self cancelDisplayDelayedPerforms];

	[self willTakeDownNotification];
	if ([self startAllTransitions]) {
		[self performSelector:@selector(didFinishTransitionsAfterDisplay) 
				   withObject:nil
				   afterDelay:transitionDuration];
	} else {
		[self didFinishTransitionsAfterDisplay];
	}
	[self didTakeDownNotification];
}

#pragma mark -
#pragma mark Display stages

- (void)cancelDisplayDelayedPerforms
{
	[[self class] cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(didFinishTransitionsBeforeDisplay) 
												   object:nil];
	
	[[self class] cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(didFinishTransitionsAfterDisplay) 
												   object:nil];

	[[self class] cancelPreviousPerformRequestsWithTarget:self
												 selector:@selector(stopDisplay) 
												   object:nil];	
}

- (void) willDisplayNotification {
	displayStatus = GrowlDisplayTransitioningInStatus;

	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayWindowControllerWillDisplayWindowNotification
														object:self];
}

- (void) didFinishTransitionsBeforeDisplay {
	[self cancelDisplayDelayedPerforms];

	if (![[[notification auxiliaryDictionary] objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]) {
		[self performSelector:@selector(stopDisplay)
				   withObject:nil
				   afterDelay:(displayDuration+transitionDuration)];		
	}
	
	displayStatus = GrowlDisplayOnScreenStatus;
}

- (void) didFinishTransitionsAfterDisplay {
	[self cancelDisplayDelayedPerforms];

	//Clear the rect we reserved...
	NSWindow *window = [self window];
	[window orderOut:nil];

	//Release all window transitions immediately; they may have retained our window.
	[windowTransitions release]; windowTransitions = nil;

	[[GrowlPositionController sharedInstance] clearReservedRectForDisplayController:self];

	if ((bridge) && ([bridge respondsToSelector:@selector(display)]))
		[[bridge display] displayWindowControllerDidTakeDownWindow:self];
	else {
		NSLog(@"%@ bridge does not respond to display",bridge);
	}
}

- (void) didDisplayNotification {
	if (screenshotMode)
		[self takeScreenshot];

	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayWindowControllerDidDisplayWindowNotification
														object:self];
}

- (void) willTakeDownNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:GrowlDisplayWindowControllerWillTakeWindowDownNotification
														object:self];
	displayStatus = GrowlDisplayTransitioningOutStatus;
}

- (void) didTakeDownNotification {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	if (clickContext) {
		NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:2U];
		[userInfo setValue:clickContext forKey:GROWL_KEY_CLICKED_CONTEXT];
		if (appPid)
			[userInfo setValue:appPid forKey:GROWL_APP_PID];
		[nc postNotificationName:GROWL_NOTIFICATION_TIMED_OUT object:appName userInfo:userInfo];
		[userInfo release];

		//Avoid duplicate click messages by immediately clearing the clickContext
		clickContext = nil;
	}
	[nc postNotificationName:GrowlDisplayWindowControllerDidTakeWindowDownNotification object:self];
}
#pragma mark -
#pragma mark Click feedback

- (void) notificationClicked:(id)sender {
#pragma unused(sender)
	if (clickContext) {
		NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] initWithCapacity:3U];
		[userInfo setValue:clickHandlerEnabled forKey:@"ClickHandlerEnabled"];
		[userInfo setValue:clickContext forKey:GROWL_KEY_CLICKED_CONTEXT];
		if (appPid)
			[userInfo setValue:appPid forKey:GROWL_APP_PID];
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:appName
														  userInfo:userInfo];
		[userInfo release];

		//Avoid duplicate click messages by immediately clearing the clickContext
		clickContext = nil;
	}

	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];

	[self stopDisplay];
}

#pragma mark -
#pragma mark Window Transitions

- (BOOL) addTransition:(GrowlWindowTransition *)transition {
	[transition setWindow:[self window]];
	[transition setDelegate:self];
	if (![windowTransitions objectForKey:[transition class]]) {
		[windowTransitions setObject:transition forKey:[transition class]];
		return TRUE;
	}
	return FALSE;
}

- (void) removeTransition:(GrowlWindowTransition *)transition {
	[transition setDelegate:nil];
	[transition setWindow:nil];
	
	[windowTransitions removeObjectForKey:[transition class]];
}

- (void) setStartPercentage:(unsigned)start endPercentage:(unsigned)end forTransition:(GrowlWindowTransition *)transition {
	NSAssert1((start <= 100U || start < end),
			  @"The start parameter was invalid for the transition: %@",
			  transition);
	NSAssert1((end <= 100U || start < end),
			  @"The end parameter was invalid for the transition: %@",
			  transition);

	NSMapInsert(startTimes, transition, (void *)start);
	NSMapInsert(endTimes, transition, (void *)end);
}

#pragma mark-

- (NSArray *) allTransitions {
	return [windowTransitions allValues];
}

- (NSArray *) activeTransitions {
	int count = [windowTransitions count];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	NSArray *transitionArray = [windowTransitions allValues];

	int i;
	for (i=0; i<count; ++i) {
		GrowlWindowTransition *transition = [transitionArray objectAtIndex:i];
		if ([transition isAnimating])
			[result addObject:transition];
	}

	return result;
}

- (NSArray *) inactiveTransitions {
	int count = [windowTransitions count];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	NSArray *transitionArray = [windowTransitions allValues];

	int i;
	for (i=0; i<count; ++i) {
		GrowlWindowTransition *transition = [transitionArray objectAtIndex:i];
		if (![transition isAnimating])
			[result addObject:transition];
	}

	return result;
}

- (BOOL) startAllTransitions {
	BOOL result = NO;
	GrowlWindowTransition *transition;
	NSEnumerator *transitionEnum = [[windowTransitions allValues] objectEnumerator];

	while ((transition = [transitionEnum nextObject]))
		if ([self startTransition:transition])
			result = YES;
	return result;
}

- (BOOL) startTransition:(GrowlWindowTransition *)transition {
	int startPercentage = (int) NSMapGet(startTimes, transition);
	int endPercentage   = (int) NSMapGet(endTimes, transition);

	// If there were no times set up then the end time would be NULL (0)...
	if (endPercentage == 0)
		return NO;

	// Work out the start and the end times...
	CFTimeInterval startTime = startPercentage * (transitionDuration * 0.01);
	CFTimeInterval endTime = endPercentage * (transitionDuration * 0.01);

	// Set up this transition...
	[transition setDuration: (endTime - startTime)];
	[transition performSelector:@selector(startAnimation) 
					 withObject:nil
					 afterDelay:startTime];

	return YES;
}

- (BOOL) startTransitionOfKind:(Class)transitionClass {
	GrowlWindowTransition *transition = [windowTransitions objectForKey:transitionClass];
	if (transition)
		return [self startTransition:transition];
	return NO;
}

- (void) stopAllTransitions {
	GrowlWindowTransition *transition;
	NSEnumerator *transitionEnum = [[windowTransitions allValues] objectEnumerator];
	while (( transition = [transitionEnum nextObject] ))
		[self stopTransition:transition];
}

- (void) stopTransition:(GrowlWindowTransition *)transition {
	[transition stopAnimation];
	[self removeTransition:transition];

	[[self class] cancelPreviousPerformRequestsWithTarget:transition
												 selector:@selector(startAnimation)
												   object:nil];
}

- (void) stopTransitionOfKind:(Class)transitionClass {
	GrowlWindowTransition *transition = [windowTransitions objectForKey:transitionClass];
	if (transition)
		[self stopTransition:transition];
}

- (void)growlAnimationDidEnd:(GrowlAnimation *)animation
{
	if ([animation isKindOfClass:[GrowlWindowTransition class]] &&
		([(GrowlWindowTransition *)animation window] == [self window]) &&
		([(GrowlWindowTransition *)animation direction] == GrowlReverseTransition) &&
		![animation repeats]) {
		//A fade out nonrepeating animation finished. We don't need to wait on our timeout; we know we finished displaying a notification.
		[self didFinishTransitionsAfterDisplay];
	}
}

- (void)reverseAllTransitions
{
	[[windowTransitions allValues] makeObjectsPerformSelector:@selector(reverse)];
}

#pragma mark -
#pragma mark Notifications

- (GrowlApplicationNotification *) notification {
	// Only here for binding conformance
    return notification;
}

- (void) setNotification:(GrowlApplicationNotification *)theNotification {
    if (notification != theNotification) {
		[notification release];
		notification = [theNotification retain];
	}
}

- (void) updateToNotification:(GrowlApplicationNotification *)theNotification {
	[self setNotification:theNotification];

	switch (displayStatus) {
		case GrowlDisplayUnknownStatus:
		case GrowlDisplayTransitioningInStatus:
			//Do nothing; we're still transitioning in
			break;
			
		case GrowlDisplayOnScreenStatus:
			//We're on screen; reset our timer for transitioning out
			[self didFinishTransitionsBeforeDisplay];
			break;
			
		case GrowlDisplayTransitioningOutStatus:
			//We're transitioning out; we need to go back to transitioning in
			[self willDisplayNotification];
			[self reverseAllTransitions];
			[self didFinishTransitionsBeforeDisplay];
			break;
	}

	[self reposition_startingDisplay:NO];
}

#pragma mark -

- (GrowlNotificationDisplayBridge *) bridge {
    return bridge;
}

- (void) setBridge:(GrowlNotificationDisplayBridge *)theBridge {
	if (bridge != theBridge) {
		if (bridge) {
			NSLog(@"*** This may be an error. %@ had its bridge reset", self);
			[bridge removeObserver:self forKeyPath:@"notification"];
		}
		
		bridge = [theBridge retain];
		
		[bridge addObserver:self forKeyPath:@"notification" options:NSKeyValueObservingOptionNew context:NULL];
		[self observeValueForKeyPath:@"notification" ofObject:bridge change:nil context:NULL];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
#pragma unused(change)
#pragma unused(context)
	if ((object == bridge) &&
		[keyPath isEqualToString:@"notification"]) {
		[self setNotification:[bridge notification]];
	}
}

#pragma mark -

- (CFTimeInterval) transitionDuration {
    return transitionDuration;
}

- (void) setTransitionDuration:(CFTimeInterval)theTransitionDuration{
    transitionDuration = theTransitionDuration;
}

#pragma mark -

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
	[self setScreenNumber:newScreenNumber];
}

- (void) setScreenNumber:(unsigned)newScreenNumber {
	[self willChangeValueForKey:@"screenNumber"];
	screenNumber = newScreenNumber;
	[self  didChangeValueForKey:@"screenNumber"];
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
					   name:GrowlDisplayWindowControllerWillDisplayWindowNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerDidDisplayWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerDidDisplayWindow:)
					   name:GrowlDisplayWindowControllerDidDisplayWindowNotification
					 object:self];

		if ([observer respondsToSelector:@selector(displayWindowControllerWillTakeDownWindow:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerWillTakeWindowDown:)
					   name:GrowlDisplayWindowControllerWillTakeWindowDownNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerDidTakeWindowDown:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerDidTakeWindowDown:)
					   name:GrowlDisplayWindowControllerDidTakeWindowDownNotification
					 object:self];
		if ([observer respondsToSelector:@selector(displayWindowControllerNotificationBlocked:)])
			[nc addObserver:observer
				   selector:@selector(displayWindowControllerNotificationBlocked:)
					   name:GrowlDisplayWindowControllerNotificationBlockedNotification
					 object:self];
	}
}
- (void) removeNotificationObserver:(id)observer {
	[[NSNotificationCenter defaultCenter] removeObserver:observer];
}

@end

#pragma mark -

@implementation GrowlDisplayWindowController (GrowlNotificationViewDelegate)

- (void) mouseExitedNotificationView:(GrowlNotificationView *)view {
#pragma unused (view)

}

@end
