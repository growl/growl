//
// GrowlDefinesCarbon.h
//
// Automatically generated from GrowlDefines.h on Fri Sep 2004 by GenCarbonHeader.pl
//

/*!
@header
 @abstract   Defines all the notification keys
 @discussion Defines all the keys used for registration and growl notifications.
 */

// UserInfo Keys for Registration
#pragma mark UserInfo Keys for Registration
/*! The name of your application */
#define GROWL_APP_NAME					CFSTR("ApplicationName")
/*! The TIFF data for the default icon for notifications (Optional) */
#define GROWL_APP_ICON					CFSTR("ApplicationIcon")
/*! The array of notifications to turn on by default */
#define GROWL_NOTIFICATIONS_DEFAULT		CFSTR("DefaultNotifications")
/*! The array of all notifications your application can send */
#define GROWL_NOTIFICATIONS_ALL			CFSTR("AllNotifications")
/*! The array of notifications the user has turned on */
#define GROWL_NOTIFICATIONS_USER_SET	CFSTR("AllowedUserNotifications")

// UserInfo Keys for Notifications
#pragma mark UserInfo Keys for Notifications
/*! The name of the notification. This should be human-readable as it's shown in the prefpane */
#define GROWL_NOTIFICATION_NAME			CFSTR("NotificationName")
/*! The title to display in the notification */
#define GROWL_NOTIFICATION_TITLE		CFSTR("NotificationTitle")
/*! The contents of the notification */
#define GROWL_NOTIFICATION_DESCRIPTION  CFSTR("NotificationDescription")
/*! The TIFF data for the notification icon (Optional) */
#define GROWL_NOTIFICATION_ICON			CFSTR("NotificationIcon")
/*! A boolean controlling whether the notification is sticky. (Optional)

Not necessarily supported by all display plugins */
#define GROWL_NOTIFICATION_STICKY		CFSTR("NotificationSticky")

// Notifications
#pragma mark Notifications
/*! The distributed notification name to use for registration */
#define GROWL_APP_REGISTRATION			CFSTR("GrowlApplicationRegistrationNotification")
/*! The distributed notification sent to confirm the registration. Used by the prefpane */
#define GROWL_APP_REGISTRATION_CONF		CFSTR("GrowlApplicationRegistrationConfirmationNotification")
/*! The distributed notification name to use for growl notifications */
#define GROWL_NOTIFICATION				CFSTR("GrowlNotification")
/*! The distributed notification name to use to tell Growl to shutdown (this is a guess) */
#define GROWL_SHUTDOWN					CFSTR("GrowlShutdown")
/*! The distribued notification sent to check if Growl is running. Used by the prefpane */
#define GROWL_PING						CFSTR("Honey, Mind Taking Out The Trash")
/*! The distributed notification sent in reply to GROWL_PING */
#define GROWL_PONG						CFSTR("What Do You Want From Me, Woman")

/*! The distributed notification sent when Growl starts up (this is a guess) */
#define GROWL_IS_READY					CFSTR("Lend Me Some Sugar; I Am Your Neighbor!")
