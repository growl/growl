//
//  GrowlDisplayPlugin.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-01.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayPlugin.h"
#import "GrowlLog.h"

@implementation GrowlDisplayPlugin

- (id) init {
	if ((self = [super init])) {
		/*determine whether this display should enqueue notifications when a
		 *	notification is already being displayed.
		 */
		BOOL queuesNotifications = NO;

		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSString *queuesNotificationsObject = [bundle objectForInfoDictionaryKey:@"GrowlDisplayUsesQueue"];
		if(queuesNotificationsObject) {
			NSAssert3([queuesNotificationsObject respondsToSelector:@selector(boolValue)],
					  @"object for GrowlDisplayUsesQueue in Info.plist of %@ is a %@ and therefore has no Boolean value (description follows)\n%@",
					  bundle, [windowNibName class], windowNibName);
			queuesNotifications = [queuesNotificationsObject boolValue];
		}

		if(queuesNotifications)
			queue = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	[bridge release];

	[super dealloc];
}

#pragma mark -

- (void) displayNotification:(GrowlApplicationNotification *)notification {
	NSString *windowNibName = [self windowNibName];
	if (windowNibName) {
		GrowlNotificationDisplayBridge *newBridge = [GrowlNotificationDisplayBridge bridgeWithDisplay:self
																						 notification:notification
																						windowNibName:windowNibName];
		[newBridge makeWindowControllers];

		if (queue) {
			if (bridge) {
				//a notification is already up; enqueue the new one
				[queue addObject:newBridge];
			} else {
				//nothing up at the moment; just display it
				[[newBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
				bridge = newBridge;
			}
		} else {
			//no queue; just display it
			[[newBridge windowControllers] makeObjectsPerformSelector:@selector(startDisplay)];
			[activeBridges addObject:newBridge];
		}
	}
}

- (NSString *) windowNibName {
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];

	NSString *windowNibName = [bundle objectForInfoDictionaryKey:@"GrowlDisplayWindowNibName"];
	if(windowNibName) {
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

- (void) displayWindowControllerDidTakeDownWindow:(GrowlDisplayWindowController *) wc {
	if (bridge)
		[bridge removeWindowController:wc];
	else
		[[activeBridges bridgeForWindowController:wc] removeWindowController:wc];
}

@end
