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
#import "GrowlDefines.h"
#import "GrowlApplicationNotification.h"

NSString *GrowlDisplayPluginInfoKeyUsesQueue = @"GrowlDisplayUsesQueue";
NSString *GrowlDisplayPluginInfoKeyWindowNibName = @"GrowlDisplayWindowNibName";

@implementation GrowlDisplayPlugin

- (id) init {
	if ((self = [super init])) {
		/*determine whether this display should enqueue notifications when a
		 *	notification is already being displayed.
		 */
		BOOL queuesNotifications = NO;
		windowControllerClass    = nil;

		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSString *queuesNotificationsObject = [bundle objectForInfoDictionaryKey:GrowlDisplayPluginInfoKeyUsesQueue];
		if (queuesNotificationsObject) {
			NSAssert4([queuesNotificationsObject respondsToSelector:@selector(boolValue)],
					  @"object for %@ in Info.plist of %@ is a %@ and therefore has no Boolean value (description follows)\n%@",
					  GrowlDisplayPluginInfoKeyUsesQueue,
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
	[coalescableBridges release];
    [bridge release];
    [queue release];

	[super dealloc];
}

#pragma mark -

- (void) displayNotification:(GrowlApplicationNotification *)notification {
	NSString *windowNibName = [self windowNibName];
	GrowlNotificationDisplayBridge *thisBridge = nil;
	
	NSString *identifier = [[notification auxiliaryDictionary] objectForKey:GROWL_NOTIFICATION_IDENTIFIER];

	if (identifier) {
		thisBridge = [coalescableBridges objectForKey:identifier];
	}
	
	if (thisBridge) {
		//Tell the bridge to update its displayed notification
		[thisBridge setNotification:notification];

	} else {
		//No existing bridge on this identifier, or no identifier. Create one.
		if (windowNibName)
			thisBridge = [GrowlNotificationDisplayBridge bridgeWithDisplay:self
															 notification:notification
															windowNibName:windowNibName
													windowControllerClass:windowControllerClass];
		else
			thisBridge = [GrowlNotificationDisplayBridge bridgeWithDisplay:self
															 notification:notification
													windowControllerClass:windowControllerClass];
		
		[thisBridge makeWindowControllers];
		[self configureBridge:thisBridge];
		if (queue) {
			if (bridge) {
				//a notification is already up; enqueue the new one
				[queue addObject:thisBridge];
			} else {
				//nothing up at the moment; just display it
				[[thisBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
				bridge = [thisBridge retain];
			}
		} else {
			//no queue; just display it
			[[thisBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
			[activeBridges addObject:thisBridge];
		}
		
		if (identifier) {
			if (!coalescableBridges) coalescableBridges = [[NSMutableDictionary alloc] init];
			[coalescableBridges setObject:thisBridge
								   forKey:identifier];
		}
	}
}

- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge {
	// Default implementation does nothing, allows subclasses to configure before display.
#pragma unused(theBridge)
	return;
}

- (NSString *) windowNibName {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	NSString *windowNibName = [bundle objectForInfoDictionaryKey:GrowlDisplayPluginInfoKeyWindowNibName];
	if (windowNibName) {
		NSAssert4([windowNibName isKindOfClass:[NSString class]],
				  @"object for %@ in Info.plist of %@ is a %@, not a string (description follows)\n%@",
				  GrowlDisplayPluginInfoKeyWindowNibName,
				  bundle, [windowNibName class], windowNibName);
	}

	return windowNibName;
}

- (BOOL) queuesNotifications {
	return (queue != nil);
}

#pragma mark -

- (void) displayWindowControllerDidTakeDownWindow:(GrowlDisplayWindowController *)wc {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	GrowlNotificationDisplayBridge *theBridge;

	[wc retain];

	if(queue)
	{
		[bridge removeWindowController:wc];

		if ([queue count] > 0U) {
			theBridge = [queue objectAtIndex:0U];
			[[theBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];

			if (bridge != theBridge) {
				[bridge release];
				bridge = [theBridge retain];
			}
			[queue removeObjectAtIndex:0U];		
		}
		else
		{
			[bridge release];
			bridge = nil;
		}
	} else {
		theBridge = [activeBridges bridgeForWindowController:wc];
		[theBridge removeWindowController:wc];
		[activeBridges removeObjectIdenticalTo:theBridge];
	}

	if (coalescableBridges) {
		NSString *identifier = [[[[wc bridge] notification] auxiliaryDictionary] objectForKey:GROWL_NOTIFICATION_IDENTIFIER];
		if (identifier)
			[coalescableBridges removeObjectForKey:identifier];
	}

	[wc release];

	[pool release];
}

@end
