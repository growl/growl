//
//  GrowlDefines.h
//  Growl
//
//  Created by Karl Adam on Mon May 17 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

/*!
    @header
    @abstract   Defines all the notification keys and plugin protocols
    @discussion Defines all the keys used for registration and growl notifications,
	as well as the protocols used for Growl plugins.
*/

// UserInfo Keys for Registration
#pragma mark UserInfo Keys for Registration
/*! The name of your application */
#define GROWL_APP_NAME					@"ApplicationName"
/*! (Optional) The TIFF data for the default icon for notifications */
#define GROWL_APP_ICON					@"ApplicationIcon"
/*! The array of notifications to turn on by default */
#define GROWL_NOTIFICATIONS_DEFAULT		@"DefaultNotifications"
/*! The array of all notifications your application can send */
#define GROWL_NOTIFICATIONS_ALL			@"AllNotifications"
/*! The array of notifications the user has turned on */
#define GROWL_NOTIFICATIONS_USER_SET	@"AllowedUserNotifications"

// UserInfo Keys for Notifications
#pragma mark UserInfo Keys for Notifications
/*! The name of the notification. This should be human-readable as it's shown in the prefpane */
#define GROWL_NOTIFICATION_NAME			@"NotificationName"
/*! The title to display in the notification */
#define GROWL_NOTIFICATION_TITLE		@"NotificationTitle"
/*! The contents of the notification */
#define GROWL_NOTIFICATION_DESCRIPTION  @"NotificationDescription"
/*! (Optional) The TIFF data for the notification icon */
#define GROWL_NOTIFICATION_ICON			@"NotificationIcon"
/*! (Optional) A boolean controlling whether the notification is sticky.
	Not necessarily supported by all display plugins */
#define GROWL_NOTIFICATION_STICKY		@"NotificationSticky"

// Notifications
#pragma mark Notifications
/*! The distributed notification name to use for registration */
#define GROWL_APP_REGISTRATION			@"GrowlApplicationRegistrationNotification"
/*! The distributed notification sent to confirm the registration. Used by the prefpane */
#define GROWL_APP_REGISTRATION_CONF		@"GrowlApplicationRegistrationConfirmationNotification"
/*! The distributed notification name to use for growl notifications */
#define GROWL_NOTIFICATION				@"GrowlNotification"
/*! The distributed notification name to use to tell Growl to shutdown (this is a guess) */
#define GROWL_SHUTDOWN					@"GrowlShutdown"
/*! The distribued notification sent to check if Growl is running. Used by the prefpane */
#define GROWL_PING						@"Honey, Mind Taking Out The Trash"
/*! The distributed notification sent in reply to GROWL_PING */
#define GROWL_PONG						@"What Do You Want From Me, Woman"

/*! The distributed notification sent when Growl starts up (this is a guess) */
#define GROWL_IS_READY					@"Lend Me Some Sugar; I Am Your Neighbor!"

/*!
    @protocol    GrowlPlugin
    @abstract    The base plugin protocol
    @discussion  A protocol defining all methods supported by all Growl plugins.
 */
@protocol GrowlPlugin
/*! A method sent to tell the plugin to initialize itself */
- (void) loadPlugin;
/*! Returns the name of the author of the plugin
	@result A string */
- (NSString *) author;
/*! Returns the name of the plugin
	@result A string */
- (NSString *) name;
/*! Returns the description of the plugin
	@result A string */
- (NSString *) userDescription;
/*! Returns the version of the plugin
	@result A string */
- (NSString *) version;
/*! A method sent to tell the plugin to clean itself up */
- (void) unloadPlugin;
@end

/*!
	@protocol    GrowlDisplayPlugin
	@abstract    The display plugin protocol
	@discussion  A protocol defining all methods supported by Growl display plugins.
 */
@protocol GrowlDisplayPlugin <GrowlPlugin>
/*! Tells the display plugin to display a notification with the given information
	@param noteDict The userInfo dictionary that describes the notification */
- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict;
@end

/*!
	@protocol    GrowlFunctionalPlugin
	@abstract    The functional plugin protocol
	@discussion  A protocol defining all methods supported by Growl functionality plugins.
	
	Currently has no new methods on top of GrowlDisplayPlugin.
 */
@protocol GrowlFunctionalPlugin <GrowlPlugin>
//empty for now
@end
