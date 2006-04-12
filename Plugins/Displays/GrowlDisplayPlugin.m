//
//	GrowlDisplayPlugin.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-06-01.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlDisplayPlugin.h"
#import "GrowlNotificationDisplayBridge.h"
#import "GrowlLog.h"
#import "GrowlDisplayWindowController.h"
#import "NSStringAdditions.h"

@implementation GrowlDisplayPlugin

- (id) init {
	if ((self = [super init])) {
		/*determine whether this display should enqueue notifications when a
		 *	notification is already being displayed.
		 */
		BOOL queuesNotifications = NO;
		windowControllerClass    = nil;

		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSString *queuesNotificationsObject = [bundle objectForInfoDictionaryKey:@"GrowlDisplayUsesQueue"];
		if (queuesNotificationsObject) {
			NSAssert3([queuesNotificationsObject respondsToSelector:@selector(boolValue)],
					  @"object for GrowlDisplayUsesQueue in Info.plist of %@ is a %@ and therefore has no Boolean value (description follows)\n%@",
					  bundle, [queuesNotificationsObject class], queuesNotificationsObject);
			queuesNotifications = [queuesNotificationsObject boolValue];
		}

		if (queuesNotifications)
			queue = [[NSMutableArray alloc] init];
		else
			activeBridges = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
    [activeBridges release];
    [bridge release];
    [queue release];

	[super dealloc];
}

#pragma mark -

- (void) displayNotification:(GrowlApplicationNotification *)notification {
	NSString *windowNibName = [self windowNibName];
	GrowlNotificationDisplayBridge *newBridge = nil;
	if (windowNibName)
		newBridge = [GrowlNotificationDisplayBridge bridgeWithDisplay:self
														 notification:notification
														windowNibName:windowNibName
												windowControllerClass:windowControllerClass];
	else
		newBridge = [GrowlNotificationDisplayBridge bridgeWithDisplay:self
														 notification:notification
												windowControllerClass:windowControllerClass];

	[newBridge makeWindowControllers];
	[self configureBridge:newBridge];
	if (queue) {
		if (bridge) {
			//a notification is already up; enqueue the new one
			[queue addObject:newBridge];
		} else {
			//nothing up at the moment; just display it
			[[newBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
			bridge = [newBridge retain];
		}
	} else {
		//no queue; just display it
		[[newBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
		[activeBridges addObject:newBridge];
	}
}

- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	// Default implementation does nothing, allows subclasses to configure before display.
#pragma unused(theBridge)
	return;
}

- (NSString *) windowNibName {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	NSString *windowNibName = [bundle objectForInfoDictionaryKey:@"GrowlDisplayWindowNibName"];
	if (windowNibName) {
		NSAssert3([windowNibName isKindOfClass:[NSString class]],
				  @"object for GrowlDisplayWindowNibName in Info.plist of %@ is a %@, not a string (description follows)\n%@",
				  bundle, [windowNibName class], windowNibName);
	}

	return windowNibName;
}

- (BOOL) queuesNotifications {
	return (queue != nil);
}

#pragma mark -

- (void) displayWindowControllerDidTakeDownWindow:(GrowlDisplayWindowController *)wc {
	if ([queue count] > 0U) {
		GrowlNotificationDisplayBridge *theBridge = [queue objectAtIndex:0U];
		[[theBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
		if ([queue count] > 0U)
			bridge = [theBridge retain];
		else
			bridge = NULL;
		[queue removeObjectAtIndex:0U];		
	}
	else
		bridge = NULL;
	
	if (bridge)
		[bridge removeWindowController:wc];
	else
		[[activeBridges bridgeForWindowController:wc] removeWindowController:wc];

}

@end
