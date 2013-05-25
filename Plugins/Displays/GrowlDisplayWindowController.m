//
//  GrowlDisplayWindowController.m
//  Display Plugins
//
//  Created by Peter Hosey on 2005-06-03.
//  Copyright 2004-2011 The Growl Project, LLC. All rights reserved.
//

#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlWindowtransition.h>
#import <GrowlPlugins/GrowlDisplayWindowController.h>
#import <GrowlPlugins/GrowlNotification.h>
#import <GrowlPlugins/GrowlNotificationView.h>
#import "GrowlPathUtilities.h"
#import "GrowlDefines.h"
#import "GrowlPositioningDefines.h"
#import "GrowlDisplayBridgeController.h"
#import "NSViewAdditions.h"

#define DEFAULT_TRANSITION_DURATION	0.2

static NSMutableDictionary *existingInstances;

@interface GrowlDisplayWindowController (PRIVATE)
- (void)cancelDisplayDelayedPerforms;
- (BOOL)supportsStickyNotifications;
- (void)setAllTransitionsToDirection:(GrowlTransitionDirection)direction;
- (void)reverseAllTransitions; //icky. be explict.
@end

@interface NSWindow (LeopardMethods)
- (void)setCollectionBehavior:(int)collectionBehavior;
@end

@implementation GrowlDisplayWindowController

@synthesize finished;
@synthesize ignoresOtherNotifications;
@synthesize screenshotModeEnabled;
@synthesize action;
@synthesize target;
@synthesize displayDuration;
@synthesize transitionDuration;
@synthesize plugin;
@synthesize occupiedRect;

#pragma mark -
#pragma mark Caching

+ (void) registerInstance:(id)instance withIdentifier:(NSString *)ident {
	if (!existingInstances)
		existingInstances = [[NSMutableDictionary alloc] init];

	NSDictionary *classInstances = [existingInstances objectForKey:NSStringFromClass(self)];
	if (!classInstances) {
		classInstances = [[NSMutableDictionary alloc] init];
		[existingInstances setObject:classInstances forKey:NSStringFromClass(self)];
		[classInstances release];
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

- (id) initWithWindowNibName:(NSString *)windowNibName plugin:(GrowlDisplayPlugin *)aPlugin {
	// NOTE: for completeness we ought to offer the other nib related init methods with the plugin as a param
	if ((self = [self initWithWindowNibName:windowNibName owner:aPlugin])) {
		self.plugin = plugin;
	}
	return self;
}

- (id) initWithNotification:(GrowlNotification *)note plugin:(GrowlDisplayPlugin *)aPlugin {
	/* Subclasses using this method should call initWithWindowNibName: from init */
	if ((self = [self init])) {
		self.plugin = plugin;
	}
	return self;
}

- (id) initWithWindow:(NSWindow *)window andPlugin:(GrowlDisplayPlugin*)aPlugin {
	if ((self = [super initWithWindow:window])) {
		self.finished = NO;
		self.plugin = aPlugin;
		self.occupiedRect = CGRectZero;
		windowTransitions = [[NSMutableDictionary alloc] init];
		ignoresOtherNotifications = NO;
		startTimes = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0U);
		endTimes = NSCreateMapTable(NSObjectMapKeyCallBacks, NSObjectMapValueCallBacks, 0U);
		transitionDuration = DEFAULT_TRANSITION_DURATION;

		//Show notifications on all Spaces
		if ([window respondsToSelector:@selector(setCollectionBehavior:)]) {
#define NSWindowCollectionBehaviorCanJoinAllSpaces 1 << 0
			[window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
		}

		//Respond to 'close all notifications' by closing
	}

	return self;
}

- (void) dealloc {
	[self setDelegate:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
   [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	
	[self stopAllTransitions];

	NSFreeMapTable(startTimes);
	NSFreeMapTable(endTimes);

	[target              release];
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
	//Deprecated no-op
}

#pragma mark -
#pragma mark Display control

- (void)foundSpaceToStart
{
	[self cancelDisplayDelayedPerforms];
	
	[self willDisplayNotification];
	
	[[self window] orderFront:nil];
	
	if ([self startAllTransitions]) {
		[self performSelector:@selector(didFinishTransitionsBeforeDisplay)
					  withObject:nil
					  afterDelay:transitionDuration
						  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];
	} else {
		[self didFinishTransitionsBeforeDisplay];
	}
	
	[self didDisplayNotification];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
														  selector:@selector(stopDisplay)
																name:GROWL_CLOSE_ALL_NOTIFICATIONS
															 object:nil];
}

- (void) startDisplay {
	[[GrowlDisplayBridgeController sharedController] displayWindow:self reposition:NO];
}

- (void) stopDisplay {	
	id contentView = [[self window] contentView];
	if ([contentView respondsToSelector:@selector(mouseOver)] &&
		[contentView mouseOver] &&
		!userRequestedClose) {
		//The mouse is currently within the view; close when it exits
        displayStatus = GrowlDisplayOnScreenStatus; //it has to be display right now. lets just make sure.
		[contentView setCloseOnMouseExit:YES];

	} else {
		//If we're already transitioning out, just keep doing our thing
		if (displayStatus != GrowlDisplayTransitioningOutStatus) {
			[self cancelDisplayDelayedPerforms];
			[self willTakeDownNotification];
            [self setAllTransitionsToDirection:GrowlReverseTransition];
			if ([self startAllTransitions]) {
            /* This should happen automatically, with animationDidEnd */
				/*[self performSelector:@selector(didFinishTransitionsAfterDisplay) 
						   withObject:nil
						   afterDelay:transitionDuration];*/
			} else {
				[self didFinishTransitionsAfterDisplay];
			}
		}
	}
}

- (void) clickedCloseBox {
   didClick = YES;
   [[NSNotificationCenter defaultCenter] postNotificationName:@"GROWL_NOTIFICATION_CLOSED"
                                                       object:[self notification]];
   
   [self clickedClose];
}
- (void) clickedClose {
	userRequestedClose = YES;
    displayStatus = GrowlDisplayOnScreenStatus;
    
	[self stopDisplay];
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

	if (![[[notification auxiliaryDictionary] valueForKey:GROWL_NOTIFICATION_STICKY] boolValue] ||
		![self supportsStickyNotifications]) {
		[self performSelector:@selector(stopDisplay)
					  withObject:nil
					  afterDelay:(displayDuration+transitionDuration)
						  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];		
	}
	
	displayStatus = GrowlDisplayOnScreenStatus;
}

- (void) didFinishTransitionsAfterDisplay {
	if(self.finished){
		//NSLog(@"this has already been called!");
		return;
	}
	self.finished = YES;
	
	[self retain];
	
	[self cancelDisplayDelayedPerforms];
	
	//Clear the rect we reserved...
	NSWindow *window = [self window];
	[window orderOut:nil];
	
	//Release all window transitions immediately; they may have retained our window.
	[self stopAllTransitions];
	[windowTransitions release]; windowTransitions = nil;
	
	[self didTakeDownNotification];
	
	[plugin displayWindowControllerDidTakeDownWindow:self];
	
	[[GrowlDisplayBridgeController sharedController] takeDownDisplay:self];
	
	/* This object should now be deallocated.
	 */
	[self release];
}

- (void) didDisplayNotification {
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
	if (!didClick) {
		[nc postNotificationName:GROWL_NOTIFICATION_TIMED_OUT object:[self notification]];
	}
	[nc postNotificationName:GrowlDisplayWindowControllerDidTakeWindowDownNotification object:self];
}
#pragma mark -
#pragma mark Click feedback

- (void) notificationClicked:(id)sender {
	if (target && action && [target respondsToSelector:action])
		[target performSelector:action withObject:self];

	if (!didClick) {
		[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_CLICKED
															object:[self notification]
														  userInfo:nil];
		didClick = YES;
	}
	
	//Now that we've notified the clickContext and target, it's as if the user just clicked the close button
	[self clickedClose];
}

#pragma mark -
#pragma mark Window Transitions

- (BOOL) addTransition:(GrowlWindowTransition *)transition {
	[transition setWindow:[self window]];
	[transition setDelegate:self];
   NSString *classString = NSStringFromClass([transition class]);
	if (![windowTransitions objectForKey:classString]) {
		[windowTransitions setObject:transition forKey:classString];
		return TRUE;
	}
	return FALSE;
}

- (void) removeTransition:(GrowlWindowTransition *)transition {
	[transition setDelegate:nil];
	[transition setWindow:nil];
	
	[windowTransitions removeObjectForKey:NSStringFromClass([transition class])];
}

- (void) setStartPercentage:(NSUInteger)start endPercentage:(NSUInteger)end forTransition:(GrowlWindowTransition *)transition {
	NSAssert1((start <= 100U || start < end),
			  @"The start parameter was invalid for the transition: %@",
			  transition);
	NSAssert1((end <= 100U || start < end),
			  @"The end parameter was invalid for the transition: %@",
			  transition);

	[startTimes setObject:[NSNumber numberWithUnsignedInteger:start] forKey:transition ];
	[endTimes setObject:[NSNumber numberWithUnsignedInteger:end] forKey:transition ];
}

#pragma mark-

- (NSArray *) allTransitions {
	return [windowTransitions allValues];
}

- (NSArray *) activeTransitions {
	NSUInteger count = [windowTransitions count];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	NSArray *transitionArray = [windowTransitions allValues];

	NSUInteger i;
	for (i=0; i<count; ++i) {
		GrowlWindowTransition *transition = [transitionArray objectAtIndex:i];
		if ([transition isAnimating])
			[result addObject:transition];
	}

	return result;
}

- (NSArray *) inactiveTransitions {
	NSUInteger count = [windowTransitions count];
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
	NSArray *transitionArray = [windowTransitions allValues];

	NSUInteger i;
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

    for (transition in [windowTransitions allValues])
		if ([self startTransition:transition])
			result = YES;
	return result;
}

- (BOOL) startTransition:(GrowlWindowTransition *)transition {
    NSNumber *start = [startTimes objectForKey:transition];
    NSNumber *end = [endTimes objectForKey:transition];
	NSUInteger startPercentage = [start unsignedIntegerValue];
	NSUInteger endPercentage   = [end unsignedIntegerValue];

	// If there were no times set up then the end time would be NULL (0)...
	if (endPercentage == 0)
		return NO;

	// Work out the start and the end times...
	CFTimeInterval startTime = (float)startPercentage * ((float)transitionDuration * 0.01);
	CFTimeInterval endTime = (float)endPercentage * ((float)transitionDuration * 0.01);

	// Set up this transition...
	[transition setDuration: (endTime - startTime)];
	[transition performSelector:@selector(startAnimation) 
						  withObject:nil
						  afterDelay:startTime
							  inModes:[NSArray arrayWithObjects:NSRunLoopCommonModes, NSEventTrackingRunLoopMode, nil]];

	return YES;
}

- (BOOL) startTransitionOfKind:(Class)transitionClass {
	GrowlWindowTransition *transition = [windowTransitions objectForKey:NSStringFromClass(transitionClass)];
	if (transition)
		return [self startTransition:transition];
	return NO;
}

- (void) stopAllTransitions {
	for (GrowlWindowTransition *transition in [windowTransitions allValues]) {
		[self stopTransition:transition];
    }
}

- (void) stopTransition:(GrowlWindowTransition *)transition {
	[transition setDelegate:nil];
	[transition stopAnimation];
	[self removeTransition:transition];

	[[self class] cancelPreviousPerformRequestsWithTarget:transition
												 selector:@selector(startAnimation)
												   object:nil];
}

- (void) stopTransitionOfKind:(Class)transitionClass {
	GrowlWindowTransition *transition = [windowTransitions objectForKey:NSStringFromClass(transitionClass)];
	if (transition)
		[self stopTransition:transition];
}

- (void) animationDidEnd:(NSAnimation *)animation
{
	if ([animation isKindOfClass:[GrowlWindowTransition class]] &&
		([(GrowlWindowTransition *)animation window] == [self window]) &&
		([(GrowlWindowTransition *)animation direction] == GrowlReverseTransition)) {
		//A fade out nonrepeating animation finished. We don't need to wait on our timeout; we know we finished displaying a notification.
		[self didFinishTransitionsAfterDisplay];
	}
}

- (void) reverseAllTransitions
{
	[[windowTransitions allValues] makeObjectsPerformSelector:@selector(reverse)];
}

- (void) setAllTransitionsToDirection:(GrowlTransitionDirection)direction
{
	for (GrowlWindowTransition *transition in [windowTransitions allValues]){
        [transition setDirection:direction];
    }

}

#pragma mark -
- (void) mouseEnteredNotificationView:(GrowlNotificationView *)notificationView
{
	if (!userRequestedClose &&
		(displayStatus == GrowlDisplayTransitioningOutStatus)) {
		// We're transitioning out; we need to go back to transitioning in...
		[self willDisplayNotification];
		[self setAllTransitionsToDirection:GrowlForwardTransition];
		[self didFinishTransitionsBeforeDisplay];

		// ...but when the mouse leaves, transition out again
		[self stopDisplay];
	}
}

- (void) mouseExitedNotificationView:(GrowlNotificationView *)notificationView
{
	// Notifies us that the mouse left the notification view.
}

#pragma mark -
#pragma mark Notifications

- (GrowlNotification *) notification {
	// Only here for binding conformance
    return notification;
}

- (void) setNotification:(GrowlNotification *)theNotification {	
	if (notification != theNotification) {
		[[NSNotificationCenter defaultCenter] removeObserver:self
																		name:GROWL_CLOSE_NOTIFICATION
																	 object:[[notification dictionaryRepresentation] objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]];
      [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
      [notification release];
		notification = [theNotification retain];
	}
	
	NSDictionary *noteDict = [theNotification dictionaryRepresentation];
		
	NSView *view = [[self window] contentView];
	if ([view isKindOfClass:[GrowlNotificationView class]]) {
		GrowlNotificationView *notificationView = (GrowlNotificationView *)view;
		
		NSImage *icon;	
		NSData *iconData = [noteDict objectForKey:GROWL_NOTIFICATION_ICON_DATA];
		if ([iconData isKindOfClass:[NSImage class]])
			icon = (NSImage *)iconData;
		else
			icon = (iconData ? [[[NSImage alloc] initWithData:iconData] autorelease] : nil);
		
		[notificationView setPriority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]];
		[notificationView setTitle:[notification title]];
		[notificationView setText:[notification notificationDescription]];
		[notificationView setIcon:icon];
		[notificationView sizeToFit];
	}
	
	//Respond to 'close notification' by closing if our notification matches the one posted
	[[NSNotificationCenter defaultCenter] addObserver:self
														  selector:@selector(stopDisplay)
																name:GROWL_CLOSE_NOTIFICATION
															 object:[noteDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]];
   [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                       selector:@selector(stopDisplay)
                                                           name:@"GROWL3_NOTIFICATION_CANCEL_REQUESTED"
                                                         object:[noteDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]
                                             suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
}

- (void) updateToNotification:(GrowlNotification *)theNotification {
	[[NSNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION_TIMED_OUT 
																		 object:[self notification]
																	  userInfo:nil];
	CGSize start = [self requiredSize];
	[self setNotification:theNotification];
	CGSize end = [self requiredSize];
	
	BOOL resize = !CGSizeEqualToSize(start, end);
	
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
			//Reset userRequestedClose in case we were transitioning out via the user's request; we have new information!
			userRequestedClose = NO;

			[self willDisplayNotification];
			[self reverseAllTransitions];
			[self didFinishTransitionsBeforeDisplay];

			break;
	}
	if(resize && [[self window] isVisible])
		[[GrowlDisplayBridgeController sharedController] displayWindow:self reposition:YES];
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
	NSUInteger newScreenNumber = [[NSScreen screens] indexOfObjectIdenticalTo:newScreen];
	if (newScreenNumber == NSNotFound)
		[NSException raise:NSInternalInconsistencyException format:@"Tried to set %@ %p to a screen %p that isn't in the screen list", [self class], self, newScreen];
	[self setScreenNumber:newScreenNumber];
}

- (NSUInteger) screenNumber {
	return screenNumber;
}

- (void) setScreenNumber:(NSUInteger)newScreenNumber {
	[self willChangeValueForKey:@"screenNumber"];
	screenNumber = newScreenNumber;
	[self  didChangeValueForKey:@"screenNumber"];
}

- (BOOL)supportsStickyNotifications
{
	return ![[self window] ignoresMouseEvents];
}

#pragma mark -

- (id) clickContext {
	return [[[self notification] dictionaryRepresentation] objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
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
	return @YES;
}

- (void) setClickHandlerEnabled:(NSNumber *)flag {
	//deprecated no-op
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

- (NSDictionary*)configurationDict {
	return [notification configurationDict];
}

- (CGSize) requiredSize {
	CGSize size = [[self window] frame].size;
	size.width += [self requiredDistanceFromExistingDisplays];
	size.height += [self requiredDistanceFromExistingDisplays];
	return size;
}

-(CGPoint)idealOriginInRect:(CGRect)rect {
	NSRect viewFrame = [[[self window] contentView] frame];
	NSDictionary *configDict = [[self notification] configurationDict];
	GrowlPositionOrigin	position = configDict ? [[configDict valueForKey:@"com.growl.positioncontroller.selectedposition"] intValue] : GrowlTopRightCorner;
	CGPoint idealOrigin;
	
	CGFloat padding = [self requiredDistanceFromExistingDisplays];
		
	switch(position){
		case GrowlNoOrigin:
		case GrowlTopRightCorner:
			idealOrigin = CGPointMake(NSMaxX(rect) - NSWidth(viewFrame) - padding,
											  NSMaxY(rect) - padding - NSHeight(viewFrame));
			break;
		case GrowlTopLeftCorner:
			idealOrigin = CGPointMake(NSMinX(rect) + padding,
											  NSMaxY(rect) - padding - NSHeight(viewFrame));
			break;
		case GrowlBottomLeftCorner:
			idealOrigin = CGPointMake(NSMinX(rect) + padding,
											  NSMinY(rect) + padding);
			break;
		case GrowlBottomRightCorner:
			idealOrigin = CGPointMake(NSMaxX(rect) - NSWidth(viewFrame) - padding,
											  NSMinY(rect) + padding);
			break;
	}
	
	return idealOrigin;
}

- (void) positionInRect:(CGRect)rect {
	CGRect frame = [[self window] frame];
	frame.origin = [self idealOriginInRect:rect];
	[[self window] setFrame:frame display:YES];
}
- (void)setOccupiedRect:(CGRect)rect {
	occupiedRect = rect;
	if(!CGRectEqualToRect(rect, CGRectZero)){
		[self positionInRect:rect];
	}
}

- (CGRect) occupiedRect {
	return occupiedRect;
}

- (CGFloat) requiredDistanceFromExistingDisplays {
	return 0.0;
}

- (NSString*)displayQueueKey {
	return nil;
}

@end
