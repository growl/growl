//
//	GrowlDisplayPlugin.m
//	Growl
//
//	Created by Peter Hosey on 2005-06-01.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlDisplayWindowController.h>
#import "GrowlDisplayBridgeController.h"
#import "NSStringAdditions.h"
#import "GrowlDefines.h"
#import <GrowlPlugins/GrowlNotification.h>

NSString *GrowlDisplayPluginInfoKeyUsesQueue = @"GrowlDisplayUsesQueue";
NSString *GrowlDisplayPluginInfoKeyWindowNibName = @"GrowlDisplayWindowNibName";

@interface GrowlDisplayPlugin ()

@property (nonatomic, retain) NSMutableArray *queue;
@property (nonatomic, retain) GrowlDisplayWindowController *window;

@end

@implementation GrowlDisplayPlugin

@synthesize queue;
@synthesize window;

- (id) initWithBundle:(NSBundle *)bundle {
	if ((self = [super initWithBundle:bundle])) {
		/*determine whether this display should enqueue notifications when a
		 *	notification is already being displayed.
		 */
		BOOL queuesNotifications = NO;
		windowControllerClass    = nil;

		NSString *queuesNotificationsObject = [bundle objectForInfoDictionaryKey:GrowlDisplayPluginInfoKeyUsesQueue];
		if (queuesNotificationsObject) {
			NSAssert4([queuesNotificationsObject respondsToSelector:@selector(boolValue)],
					  @"object for %@ in Info.plist of %@ is a %@ and therefore has no Boolean value (description follows)\n%@",
					  GrowlDisplayPluginInfoKeyUsesQueue,
					  bundle, [queuesNotificationsObject class], queuesNotificationsObject);
			queuesNotifications = [queuesNotificationsObject boolValue];
		}

		if (queuesNotifications)
			self.queue = [NSMutableArray array];
	}
	return self;
}

- (void) dealloc {
	[coalescableWindows release];
	[window release];
	[queue release];
	
	[super dealloc];
}

#pragma mark -

- (void)dispatchNotification:(NSDictionary *)noteDict withConfiguration:(NSDictionary *)configuration {
	GrowlNotification *notification = [GrowlNotification notificationWithDictionary:noteDict 
																					  configurationDict:configuration];
	NSString *windowNibName = [self windowNibName];
	GrowlDisplayWindowController *thisWindow = nil;
	
	NSString *identifier = [[notification auxiliaryDictionary] valueForKey:GROWL_NOTIFICATION_IDENTIFIER];
	
	if (identifier) {
		thisWindow = [coalescableWindows objectForKey:identifier];
	}
	
	if (thisWindow) {
		//Tell the bridge to update its displayed notification
		[thisWindow updateToNotification:notification];
		
	} else {
		//No existing bridge on this identifier, or no identifier. Create one.
		if (windowNibName)
			thisWindow = [[windowControllerClass alloc] initWithWindowNibName:windowNibName];
		else
			thisWindow = [[windowControllerClass alloc] initWithNotification:notification plugin:self];
		[thisWindow setNotification:notification];
				
		if (queue) {
			if (window) {
				//a notification is already up; enqueue the new one
				[queue addObject:thisWindow];
			} else {
				//nothing up at the moment; just display it
				self.window = thisWindow;
				[[GrowlDisplayBridgeController sharedController] displayBridge:thisWindow reposition:NO];
			}
		} else {
			//no queue; just display it
			[[GrowlDisplayBridgeController sharedController] displayBridge:thisWindow reposition:NO];
		}
		
		if (identifier) {
			if (!coalescableWindows) coalescableWindows = [[NSMutableDictionary alloc] init];
			[coalescableWindows setObject:thisWindow
										  forKey:identifier];
		}
		[thisWindow release];
	}
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

- (BOOL) requiresPositioning {
	return YES;
}

#pragma mark -

- (void) displayWindowControllerDidTakeDownWindow:(GrowlDisplayWindowController *)wc {
	@autoreleasepool {
		
		[wc retain];
		
		if(queue)
		{
			GrowlDisplayWindowController *theWindow;
			
			if ([queue count] > 0U) {
				theWindow = [queue objectAtIndex:0U];
				
				[[GrowlDisplayBridgeController sharedController] displayBridge:theWindow reposition:NO];
				
				if(theWindow != wc)
					self.window = theWindow;
				
				[queue removeObjectAtIndex:0U];		
			}
			else
			{
				self.window = nil;
			}
		}
		if (coalescableWindows) {
			NSString *identifier = [[[wc notification] auxiliaryDictionary] objectForKey:GROWL_NOTIFICATION_IDENTIFIER];
			if (identifier)
				[coalescableWindows removeObjectForKey:identifier];
		}
		
		[wc release];
	}
}

@end
