//
//  GrowlDefines.h
//  Growl
//
//  Created by Karl Adam on Mon May 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

// User Info Keys For Registration
#define GROWL_APP_NAME					@"ApplicationName"
#define GROWL_APP_ICON					@"ApplicationIcon"
#define GROWL_NOTIFICATIONS_DEFAULT		@"DefaultNotifications"
#define GROWL_NOTIFICATIONS_ALL			@"AllNotifications"
#define GROWL_NOTIFICATIONS_USER_SET	@"AllowedUserNotifications"

// User Info Keys For Notifications
#define GROWL_NOTIFICATION_TITLE		@"NotificationTitle"
#define GROWL_NOTIFICATION_DESCRIPTION  @"NotificationDescription"
#define GROWL_NOTIFICATION_ICON			@"NotificationIcon"

// Notifications
#define GROWL_APP_REGISTRATION			@"GrowlApplicationRegistrationNotification"
#define GROWL_APP_REGISTRATION_CONF		@"GrowlApplicationRegistrationConfirmationNotification"
#define GROWL_PING						@"Honey, Mind Taking Out The Trash"
#define GROWL_PONG						@"What Do You Want From Me, Woman"

#define GROWL_IS_READY					@"Lend Me Some Sugar; I Am Your Neighbor!"

@protocol GrowlPlugin
- (id) loadPlugin;
- (NSString *) author;
- (NSString *) name;
- (NSString *) userDescription;
- (NSString *) version;
- (void) unloadPlugin;
@end

@protocol GrowlDisplayPlugin <GrowlPlugin> 
- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict;
@end

@protocol GrowlFunctionalPlugin <GrowlPlugin>
//empty for now
@end
