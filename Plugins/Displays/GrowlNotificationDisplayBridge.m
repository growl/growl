//
//  GrowlNotificationDisplayBridge.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlNotification.h"
#import "GrowlNotificationDisplayBridge.h"
#import "GrowlDisplayWindowController.h"
#import "GrowlDisplayPlugin.h"

#import "GrowlDisplayWindowController.h"

//Used to silence a warning when forwarding one of these messages to the display or notification.
@protocol WindowControllerListener <NSObject>

- (void) windowControllerWillLoadNib:(GrowlDisplayWindowController *)windowController;
- (void) windowControllerDidLoadNib:(GrowlDisplayWindowController *)windowController;

@end

@implementation GrowlNotificationDisplayBridge

+ (GrowlNotificationDisplayBridge *) bridgeWithDisplay:(GrowlDisplayPlugin *)newDisplay notification:(GrowlNotification *)newNotification windowControllerClass:(Class)wcc {
	return [[[self alloc] initWithDisplay:newDisplay
							 notification:newNotification
					windowControllerClass:wcc] autorelease];
}

+ (GrowlNotificationDisplayBridge *) bridgeWithDisplay:(GrowlDisplayPlugin *)newDisplay notification:(GrowlNotification *)newNotification windowNibName:(NSString *)newWindowNibName windowControllerClass:(Class)wcc {
	return [[[self alloc] initWithDisplay:newDisplay
							 notification:newNotification
							windowNibName:newWindowNibName
					windowControllerClass:wcc] autorelease];
}

- (id) initWithDisplay:(GrowlDisplayPlugin *)newDisplay notification:(GrowlNotification *)newNotification windowControllerClass:(Class)wcc {
	return [self initWithDisplay:newDisplay
					notification:newNotification
				   windowNibName:nil
		   windowControllerClass:wcc];
}

- (id) initWithDisplay:(GrowlDisplayPlugin *)newDisplay notification:(GrowlNotification *)newNotification windowNibName:(NSString *)newWindowNibName windowControllerClass:(Class)wcc  {
	if ((self = [self init])) {
		windowControllerClass = (wcc ? wcc : NSClassFromString(@"GrowlDisplayWindowController"));
		display               =  newDisplay;
		notification          = [newNotification retain];
		windowControllers     = [[NSMutableArray alloc] initWithCapacity:1U];
		if (newWindowNibName)
			windowNibName     = [newWindowNibName copy];
	}
	return self;
}

- (void) dealloc {
	[windowControllers release];

	[notification release];
	[windowNibName release];

	[super dealloc];
}

#pragma mark -

- (void) makeWindowControllers {
	id wc = nil;
	if (windowNibName)
		wc = [[windowControllerClass alloc] initWithWindowNibName:windowNibName
														   bridge:self];
	else
		wc = [[windowControllerClass alloc] initWithBridge:self];

	[self addWindowController:wc];
	[wc release];
}

- (GrowlDisplayPlugin *) display {
    return display;
}

- (GrowlNotification *) notification{
    return notification;
}

- (NSString *) windowNibName {
	return windowNibName;
}

- (void) windowControllerWillLoadNib:(GrowlDisplayWindowController *)windowController {
	if (display && [display respondsToSelector:@selector(windowControllerWillLoadNib:)])
		[(id <WindowControllerListener>)display windowControllerWillLoadNib:windowController];
	if (notification && [notification respondsToSelector:@selector(windowControllerWillLoadNib:)])
		[(id <WindowControllerListener>)notification windowControllerWillLoadNib:windowController];
}

- (void) windowControllerDidLoadNib:(GrowlDisplayWindowController *)windowController {
	if (display && [display respondsToSelector:@selector(windowControllerDidLoadNib:)])
		[(id <WindowControllerListener>)display windowControllerDidLoadNib:windowController];
	if (notification && [notification respondsToSelector:@selector(windowControllerDidLoadNib:)])
		[(id <WindowControllerListener>)notification windowControllerDidLoadNib:windowController];
}

- (void) addWindowController:(GrowlDisplayWindowController *)newWindowController {
	[windowControllers addObject:newWindowController];

	//we use the notifications so as not to clobber an existing delegate.
	[newWindowController addNotificationObserver:self];
}
- (void) removeWindowController:(GrowlDisplayWindowController *)windowControllerToRemove {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[windowControllerToRemove removeNotificationObserver:self];
	[windowControllers removeObjectIdenticalTo:windowControllerToRemove];

	[pool release];
}
- (BOOL) containsWindowController:(GrowlDisplayWindowController *)windowController {
	return ([windowControllers indexOfObjectIdenticalTo:windowController] != NSNotFound);
}

- (NSArray *) windowControllers {
	return windowControllers;
}

#pragma mark -
- (void)setNotification:(GrowlNotification *)inNotification
{
	if (notification != inNotification) {
		[notification release];
		notification = [inNotification retain];
	}

	[windowControllers makeObjectsPerformSelector:@selector(updateToNotification:)
									   withObject:notification];
}

@end

@implementation NSArray (GrowlDisplaySearching)

- (GrowlNotificationDisplayBridge *) bridgeForWindowController:(GrowlDisplayWindowController *) windowController {
	GrowlNotificationDisplayBridge *bridge = nil;
	for (bridge in self)
		if ([bridge containsWindowController:windowController])
			break;

	return bridge;
}

@end
