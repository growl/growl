//
//  GrowlApplicationTicket.h
//  Growl
//
//  Created by Karl Adam on Tue Apr 27 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GrowlController;

@interface GrowlApplicationTicket : NSObject {
	NSString		*_appName;					//the Applications's name for display by notifications that want it
	NSImage			*_icon;						//this app's icon for notifications and display methods that want it
	NSSet			*_allNotifications;			//all the notifications possible for this app
	NSSet			*_defaultNotifications;		//the default notifications
	NSArray			*_allowedNotifications;		//the allowed notifications
	GrowlController *_parent;					//the GrowlController from which we came
	
	BOOL useDefaults;							//flag for whether this ticket just uses default
}

- (id) initWithApplication:(NSString *)inAppName withIcon:(NSImage *)inIcon andNotifications:(NSSet *) inAllNotifications andDefaultSet:(NSSet *) inDefaultSet fromParent:(GrowlController *) parent;
- (void) loadTicket;
- (void) saveTicket;

#pragma mark -

- (void) registerParentForNotifications:(NSSet *) inSet;
@end
