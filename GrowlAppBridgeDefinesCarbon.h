//
// GrowlAppBridgeDefinesCarbon.h
//
// Automatically generated from GrowlAppBridgeDefines.h on Sat Jan 2005 by GenCarbonHeader.pl
//

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
#define GROWL_NOTIFICATION_DESCRIPTION  	CFSTR("NotificationDescription")
/*! The TIFF data for the notification icon (Optional) */
#define GROWL_NOTIFICATION_ICON			CFSTR("NotificationIcon")
/*! The TIFF data for the application icon (Optional) */
#define GROWL_NOTIFICATION_APP_ICON		CFSTR("NotificationAppIcon")
/*! The priority of the notification from the preference pane */
#define GROWL_NOTIFICATION_PRIORITY		CFSTR("NotificationPriority")
/*! A boolean controlling whether the notification is sticky. (Optional)

Not necessarily supported by all display plugins */
#define GROWL_NOTIFICATION_STICKY		CFSTR("NotificationSticky")
/*! A context for the notification for clicking purposes.

This will be passed back to the application when the notification is clicked
(not necessarily supported by all display plugins). It must be plist-encodable. */
#define GROWL_NOTIFICATION_CLICK_CONTEXT			CFSTR("NotificationClickContext")

//add documentation comments
#define GROWL_NOTIFICATION_FORCE_APP_LINK	CFSTR("NotificationForceAppLink")
#define GROWL_NOTIFICATION_LINKS		CFSTR("NotificationLinks")

// Notifications
#pragma mark Notifications
/*! The distributed notification name to use for registration */
#define GROWL_APP_REGISTRATION			CFSTR("GrowlApplicationRegistrationNotification")
/*! The distributed notification sent to confirm the registration. Used by the prefpane */
#define GROWL_APP_REGISTRATION_CONF		CFSTR("GrowlApplicationRegistrationConfirmationNotification")
/*! The distributed notification name to use for growl notifications */
#define GROWL_NOTIFICATION				CFSTR("GrowlNotification")
/*! The distributed notification name to use to tell Growl to shutdown */
#define GROWL_SHUTDOWN					CFSTR("GrowlShutdown")
/*! The distribued notification sent to check if Growl is running. Used by the prefpane */
#define GROWL_PING						CFSTR("Honey, Mind Taking Out The Trash")
/*! The distributed notification sent in reply to GROWL_PING */
#define GROWL_PONG						CFSTR("What Do You Want From Me, Woman")

/*! The distributed notification sent when Growl starts up */
#define GROWL_IS_READY					CFSTR("Lend Me Some Sugar; I Am Your Neighbor!")

/*! The distributed notification set when a supported notification is clicked.
Handled by the GrowlAppBridge. */
#define GROWL_NOTIFICATION_CLICKED		CFSTR("GrowlClicked!")

/*! Used internally as the key for the clickedContext passed over DNC */
#define	GROWL_KEY_CLICKED_CONTEXT		CFSTR("ClickedContext")
