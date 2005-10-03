//
//  GrowlNotificationDisplayBridge.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-05.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlNotificationDisplayBridge.h"
#import "GrowlDisplayWindowController.h"

#import "GrowlDisplayWindowController.h"

@implementation GrowlNotificationDisplayBridge

+ (GrowlNotificationDisplayBridge *) bridgeWithDisplay:(GrowlDisplayPlugin *)newDisplay notification:(GrowlApplicationNotification *)newNotification windowNibName:(NSString *)newWindowNibName {
	return [[[self alloc] initWithDisplay:newDisplay notification:newNotification windowNibName:newWindowNibName] autorelease];
}

- (id) initWithDisplay:(GrowlDisplayPlugin *)newDisplay notification:(GrowlApplicationNotification *)newNotification windowNibName:(NSString *)newWindowNibName {
	if ((self = [super init])) {
		display           =  newDisplay;
		notification      = [newNotification retain];
		windowNibName     = [newWindowNibName copy];
		windowControllers = [[NSMutableArray alloc] initWithCapacity:1U];
	}
	return self;
}

- (void)dealloc {
	[windowControllers release];

	[notification release];
	[windowNibName release];

	[super dealloc];
}

#pragma mark -

- (void) makeWindowControllers {
	GrowlDisplayWindowController *wc = [[GrowlDisplayWindowController alloc] initWithWindowNibName:windowNibName owner:self];
	[self addWindowController:wc];
	[wc release];
}

- (NSString *) windowNibName {
	return windowNibName;
}

- (void) windowControllerWillLoadNib:(GrowlDisplayWindowController *)windowController {
	if (display && [display respondsToSelector:@selector(windowControllerWillLoadNib:)])
		[display windowControllerWillLoadNib:windowController];
	if (notification && [notification respondsToSelector:@selector(windowControllerWillLoadNib:)])
		[notification windowControllerWillLoadNib:windowController];
}
- (void) windowControllerDidLoadNib:(GrowlDisplayWindowController *)windowController {
	if (display && [display respondsToSelector:@selector(windowControllerDidLoadNib:)])
		[display windowControllerDidLoadNib:windowController];
	if (notification && [notification respondsToSelector:@selector(windowControllerDidLoadNib:)])
		[notification windowControllerDidLoadNib:windowController];
}

- (void) addWindowController:(GrowlDisplayWindowController *)newWindowController {
	[windowControllers addObject:newWindowController];

	//we use the notifications so as not to clobber an existing delegate.
	[newWindowController addNotificationObserver:self];
}
- (void) removeWindowController:(GrowlDisplayWindowController *)windowControllerToRemove {
	[windowControllers removeObjectIdenticalTo:windowControllerToRemove];
	[windowControllerToRemove removeNotificationObserver:self];
}
- (BOOL) containsWindowController:(GrowlDisplayWindowController *)windowController {
	return ([windowControllers indexOfObjectIdenticalTo:windowController] != NSNotFound);
}

- (NSArray *) windowControllers {
#warning should this call -makeWindowControllers? discuss. --boredzo
	return [[windowControllers copy] autorelease];
}

@end

@implementation NSArray (GrowlDisplaySearching)

- (GrowlNotificationDisplayBridge *) bridgeForWindowController:(GrowlDisplayWindowController *) windowController {
	NSEnumerator *bridgesEnum = [self objectEnumerator];
	GrowlNotificationDisplayBridge *bridge;

	while ((bridge = [bridgesEnum nextObject]))
		if ([bridge containsWindowController:windowController])
			break;

	return bridge;
}

@end
