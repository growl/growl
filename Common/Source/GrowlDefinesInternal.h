//
//  GrowlDefinesInternal.h
//  Growl
//
//  Created by Karl Adam on Mon May 17 2004.
//  Copyright (c) 2004 the Growl Project. All rights reserved.
//

#ifndef _GROWL_GROWLDEFINESINTERNAL_H
#define _GROWL_GROWLDEFINESINTERNAL_H

#include <CoreFoundation/CoreFoundation.h>
#include <sys/types.h>
#include <unistd.h>

#ifdef __OBJC__
#define XSTR(x) (@x)
#else /* !__OBJC__ */
#define XSTR CFSTR
#endif /* __OBJC__ */

/*!	@header	GrowlDefinesInternal.h
 *	@abstract	Defines internal Growl macros and types.
 *  @ignore ATTRIBUTE_PACKED
 *	@discussion	These constants are used both by GrowlHelperApp and by plug-ins.
 *
 *	 Notification keys (used in GrowlHelperApp, in GrowlApplicationBridge, and
 *	 by applications that don't use GrowlApplicationBridge) are defined in
 *	 GrowlDefines.h.
 */

/*!
 * @defined GrowlCGFloatCeiling()
 * @abstract Macro for the ceil() function that uses a different precision depending on the CPU architecture.
 */
/*!
 * @defined GrowlCGFloatAbsoluteValue()
 * @abstract Macro for the fabs() function that uses a different precision depending on the CPU architecture.
 */
/*!
 * @defined GrowlCGFloatFloor()
 * @abstract Macro for the floor() function that uses a different precision depending on the CPU architecture.
 */
#if CGFLOAT_IS_DOUBLE
#define GrowlCGFloatCeiling(x) ceil(x)
#define GrowlCGFloatAbsoluteValue(x) fabs(x)
#define GrowlCGFloatFloor(x) floor(x)
#else
#define GrowlCGFloatCeiling(x) ceilf(x)
#define GrowlCGFloatAbsoluteValue(x) fabsf(x)
#define GrowlCGFloatFloor(x) floorf(x)
#endif

/*!	@defined	GROWL_TCP_DO_PORT
 *	@abstract	The TCP listen port for Growl's DirectObject-based notification servers.
 */
#define GROWL_TCP_DO_PORT	23052

/*!	@defined	GROWL_TCP_PORT
 *	@abstract	The TCP listen port for Growl's protocol-based notification servers.
 */
#define GROWL_TCP_PORT	23053

/*!	@defined	GROWL_PROTOCOL_VERSION
 *	@abstract	The current version of the Growl network-notifications protocol (without encryption).
 */
#define GROWL_PROTOCOL_VERSION	1

/*!	@defined	GROWL_PROTOCOL_VERSION_AES128
*	@abstract	The current version of the Growl network-notifications protocol (with AES-128 encryption).
*/
#define GROWL_PROTOCOL_VERSION_AES128	2

/*!	@defined	GROWL_TYPE_REGISTRATION
 *	@abstract	The packet type of registration packets with MD5 authentication.
 */
#define GROWL_TYPE_REGISTRATION			0
/*!	@defined	GROWL_TYPE_NOTIFICATION
 *	@abstract	The packet type of notification packets with MD5 authentication.
 */
#define GROWL_TYPE_NOTIFICATION			1
/*!	@defined	GROWL_TYPE_REGISTRATION_SHA256
 *	@abstract	The packet type of registration packets with SHA-256 authentication.
 */
#define GROWL_TYPE_REGISTRATION_SHA256	2
/*!	@defined	GROWL_TYPE_NOTIFICATION_SHA256
 *	@abstract	The packet type of notification packets with SHA-256 authentication.
 */
#define GROWL_TYPE_NOTIFICATION_SHA256	3
/*!	@defined	GROWL_TYPE_REGISTRATION_NOAUTH
*	@abstract	The packet type of registration packets without authentication.
*/
#define GROWL_TYPE_REGISTRATION_NOAUTH	4
/*!	@defined	GROWL_TYPE_NOTIFICATION_NOAUTH
*	@abstract	The packet type of notification packets without authentication.
*/
#define GROWL_TYPE_NOTIFICATION_NOAUTH	5

/*! @defined GROWL_NOTIFICATION_CLICKED
 *  @abstract Posted to the default notification center when the user clicks a notification
 */
#define GROWL_NOTIFICATION_CLICKED		@"GrowlNotificationClicked(Internal)"

/*! @defined GROWL_NOTIFICATION_TIMED_OUT
 *  @abstract Posted to the default notification center when a notification times out (or is closed via the close button)
 */
#define GROWL_NOTIFICATION_TIMED_OUT	@"GrowlNotificationTimedOut(Internal)"

#define GROWL_NOTIFICATION_CLICK_CONTENT_TYPE			@"NotificationCallbackClickContextType"
#define GROWL_NOTIFICATION_CALLBACK_URL_TARGET			@"NotificationCallbackURLTarget"
#define GROWL_NOTIFICATION_CALLBACK_URL_TARGET_METHOD	@"NotificationCallbackURLTargetMethod"
#define GROWL_NOTIFICATION_INTERNAL_ID					@"Growl Internal Notification ID"
#define GROWL_NOTIFICATION_GNTP_RECEIVED				@"GNTP Notification Received Headers"
#define GROWL_NOTIFICATION_GNTP_SENT_BY					@"GNTP Notification Sent-By"
#define GROWL_GNTP_ORIGIN_MACHINE						@"GNTP Origin-Machine-Name"
#define GROWL_GNTP_ORIGIN_SOFTWARE_NAME					@"GNTP Origin-Software-Name"
#define GROWL_GNTP_ORIGIN_SOFTWARE_VERSION				@"GNTP Origin-Software-Version"
#define GROWL_GNTP_ORIGIN_PLATFORM_NAME					@"GNTP Origin-Platform-Name"
#define GROWL_GNTP_ORIGIN_PLATFORM_VERSION				@"GNTP Origin-Platform-Versin"

/*!	@defined	GROWL_SCREENSHOT_MODE
 *	@abstract	Preference and notification key controlling whether to save a screenshot of the notification.
 *	@discussion	This is for GHA's private usage. If your application puts this
 *	 key into a notification dictionary, GHA will clobber it. This key is only
 *	 allowed in the notification dictionaries GHA passes to displays.
 *
 *	 If this key contains an object whose boolValue is not NO, the display is
 *	 asked to save a screenshot of the notification to
 *	 ~/Library/Application\ Support/Growl/Screenshots.
 */
#define GROWL_SCREENSHOT_MODE			XSTR("ScreenshotMode")

/*!	@defined	GROWL_CLICK_HANDLER_ENABLED
 *	@abstract	An NSNumber boolean indicating whether click notifications should be sent to the originating application
 */
#define GROWL_CLICK_HANDLER_ENABLED		XSTR("ClickHandlerEnabled")

/*!	@defined	GROWL_APP_LOCATION
 *	@abstract	The location of this application.
 *	@discussion	Contains either the POSIX path to the application, or a file-data dictionary (as used by the Dock).
 *	 contains the file's alias record and its pathname.
 */
#define GROWL_APP_LOCATION				XSTR("AppLocation")

/*!	@defined	GROWL_UDP_REMOTE_ADDRESS
 *	@abstract	The address of the host who sent this notification/registration.
 *	@discussion	Contains an NSData with the address of the remote host who
 *    sent this notification/registration.
 */
#define GROWL_UDP_REMOTE_ADDRESS			XSTR("RemoteAddress")

/*!
 *	@defined    GROWL_PREFPANE_BUNDLE_IDENTIFIER
 *	@discussion The bundle identifier for the Growl preference pane.
 */
#define GROWL_PREFPANE_BUNDLE_IDENTIFIER		XSTR("com.growl.prefpanel")
/*!
 *	@defined    GROWL_HELPERAPP_BUNDLE_IDENTIFIER
 *	@discussion The bundle identifier for the Growl background application (GrowlHelperApp).
 */
#define GROWL_HELPERAPP_BUNDLE_IDENTIFIER	XSTR("com.Growl.GrowlHelperApp")

/*!
 *	@defined    GROWL_PREFPANE_NAME
 *	@discussion The file name of the Growl preference pane.
 */
#define GROWL_PREFPANE_NAME						XSTR("Growl.prefPane")
#define PREFERENCE_PANES_SUBFOLDER_OF_LIBRARY	XSTR("PreferencePanes")
#define PREFERENCE_PANE_EXTENSION				XSTR("prefPane")

//plug-in bundle filename extensions
#define GROWL_PLUGIN_EXTENSION                  XSTR("growlPlugin")
#define GROWL_PATHWAY_EXTENSION                 XSTR("growlPathway")
#define GROWL_VIEW_EXTENSION					XSTR("growlView")
#define GROWL_STYLE_EXTENSION					XSTR("growlStyle")
#define GROWL_PATHEXTENSION_TICKET				XSTR("growlTicket")

/*!	@defined	GROWL_CLOSE_NOTIFICATION
 *	@abstract	Notification to close a Growl notification
 *	@discussion	The object of this notification is the GROWL_NOTIFICATION_INTERNAL_ID of the notification
 */
#define GROWL_CLOSE_NOTIFICATION XSTR("GrowlCloseNotification")

/*!	@defined	GROWL_CLOSE_ALL_NOTIFICATIONS
 *	@abstract	Notification to close all Growl notifications
 *	@discussion	Should be posted to the default notification center when a close widget is option+clicked.
 *    All notifications should close in response. 
 */
#define GROWL_CLOSE_ALL_NOTIFICATIONS XSTR("GrowlCloseAllNotifications")

#pragma mark Small utilities

/*!
 * @defined FLOAT_EQ(x,y)
 * @abstract Compares two floats.
 */
#define FLOAT_EQ(x,y) (((y - FLT_EPSILON) < x) && (x < (y + FLT_EPSILON)))

typedef enum {
	GrowlNotificationResultPosted,
	GrowlNotificationResultNotRegistered,
	GrowlNotificationResultDisabled
} GrowlNotificationResult;

#if GROWLHELPERAPP
extern NSString *const GrowlErrorDomain;

enum {
	GrowlPluginErrorMinimum = 1000,
	GrowlPluginErrorMaximum = GrowlPluginErrorMinimum + 999,
	
	GrowlDisplayErrorMinimum = GrowlPluginErrorMaximum  + 1,
	GrowlDisplayErrorMaximum = GrowlDisplayErrorMinimum + 999,
	
	GrowlPathwayErrorMinimum = GrowlDisplayErrorMaximum + 1,
	GrowlPathwayErrorMaximum = GrowlPathwayErrorMinimum + 999,
};

enum GrowlPathwayErrorCode {
	//A pathway that can be toggled on or off could not be toggled on.
	GrowlPathwayErrorCouldNotEnable = GrowlPathwayErrorMinimum,
	//A pathway that can be toggled on or off could not be toggled off.
	GrowlPathwayErrorCouldNotDisable,
};

enum GrowlPriority {
	GrowlPriorityUnset     = -1000,
	GrowlPriorityVeryLow   = -2,
	GrowlPriorityLow       = -1,
	GrowlPriorityNormal    =  0,
	GrowlPriorityHigh      =  1,
	GrowlPriorityEmergency =  2
};


#endif

#define GrowlVisualDisplayWindowLevel NSStatusWindowLevel

#endif //ndef _GROWL_GROWLDEFINESINTERNAL_H
