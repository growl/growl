//
//  GrowlDisplayWindowController.m
//  Display Plugins
//
//  Created by Mac-arena the Bored Zo on 2005-06-03.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"
#import "GrowlPathUtil.h"
#import "GrowlDefines.h"

static NSMutableDictionary *screenshotExtensions = nil;

@implementation GrowlDisplayWindowController

- (void) dealloc {
	[target              release];
	[clickContext        release];
	[clickHandlerEnabled release];
	[appName             release];
	[appPid              release];

	[super dealloc];
}

#pragma mark -
#pragma mark Screenshot mode

//in subclasses, call up to super, then call +registerExtension:forScreenshotFormat: for each extra format.
+ (void) registerDefaultExtensions {
	if(!extensions) {
		extensions = [[NSDictionary alloc] initWithObjectsAndKeys:
		    @"png",  @"PNG",
		    @"tiff", @"TIFF",
		    @"pdf",  @"PDF",
		    nil];
	}
}

//public
+ (void) registerExtension:(NSString *)ext forScreenshotFormat:(NSString *)format {
	[self registerDefaultExtensions];

	[extensions setObject:ext forKey:format];
}
+ (NSString *) extensionForScreenshotFormat:(NSString *)format {
	[self registerDefaultExtensions];

	return [screenshotExtensions objectForKey:format];
}

//these methods can be subclassed.
- (NSString *) defaultScreenshotFormat {
	return @"PNG";
}

- (BOOL) takeScreenshot {
	NSView *view = [self contentView]; //needed to support WebKit window controllers (XXX: this is ugly)
	NSRect  rect = [view bounds];

	NSData  *data;
	NSString *ext;

	//XXX: should have a way for the user to specify a format for certain displays.
	NSString *preferredFormat = [[[NSUserDefaults standardUserDefaults] stringForKey:GROWL_SCREENSHOT_FORMAT] uppercaseString];
	if(!preferredFormat)
		preferredFormat = [self defaultScreenshotFormat];
	//XXX: should work out a way to map a format to a selector, then call it.
	if([preferredType isEqualToString:@"PNG"])
		data = [view dataWithPNGInsideRect:rect];
	else if([preferredType isEqualToString:@"TIFF"])
		data = [view dataWithTIFFInsideRect:rect];
	else if([preferredType isEqualToString:@"PDF"])
		data = [view dataWithPDFInsideRect:rect];

	if(data && ext) {
		NSString *path = [[[GrowlPathUtil screenshotsDirectory] stringByAppendingPathComponent:[GrowlPathUtil nextScreenshotName]] stringByAppendingPathExtension:[self extensionForScreenshotFormat:preferredFormat]];
		return [data writeToFile:path atomically:NO];
	}

	return NO;
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
	[NSTimer scheduledTimerWithTimeInterval:displayDuration
									 target:self
								   selector:@selector(stopDisplay)
								   userInfo:nil
									repeats:NO];
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
