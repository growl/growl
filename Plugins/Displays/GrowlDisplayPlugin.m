//
//	GrowlDisplayPlugin.m
//	Growl
//
//	Created by Peter Hosey on 2005-06-01.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <GrowlPlugins/GrowlDisplayPlugin.h>
#import <GrowlPlugins/GrowlDisplayWindowController.h>
#import "NSStringAdditions.h"
#import "GrowlDefines.h"
#import <GrowlPlugins/GrowlNotification.h>

NSString *GrowlDisplayPluginInfoKeyUsesQueue = @"GrowlDisplayUsesQueue";
NSString *GrowlDisplayPluginInfoKeyWindowNibName = @"GrowlDisplayWindowNibName";

@implementation GrowlDisplayPlugin

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
			queue = [[NSMutableArray alloc] init];
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
				window = [thisWindow retain];
				[thisWindow startDisplay];
			}
		} else {
			//no queue; just display it
			[thisWindow startDisplay];
		}
		
		if (identifier) {
			if (!coalescableWindows) coalescableWindows = [[NSMutableDictionary alloc] init];
			[coalescableWindows setObject:thisWindow
										  forKey:identifier];
		}
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
                [theWindow startDisplay];
                
                if (window != theWindow) {
                    [window release];
                    window = [theWindow retain];
                }
                [queue removeObjectAtIndex:0U];		
            }
            else
            {
                [window release];
                window = nil;
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
