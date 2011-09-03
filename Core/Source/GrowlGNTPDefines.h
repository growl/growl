//
//  GrowlGNTPDefines.h
//  Growl
//

#define GROWL_NETWORK_DOMAIN		@"GrowlNetwork"

typedef enum {
	GrowlGNTPHeaderError,
	GrowlGNTPMalformedProtocolIdentificationError,
	GrowlGNTPRegistrationPacketError,
	GrowlGNTPCallbackPacketError
} GrowlGNTPPacketErrorType;

typedef enum {
	GrowlGNTP_NoCallback,
	GrowlGNTP_TCPCallback,
	GrowlGNTP_URLCallback
} GrowlGNTPCallbackBehavior;

typedef enum {
	GrowlGNTP_Close,
	GrowlGNTP_KeepAlive
} GrowlGNTPConnectionType;

typedef enum {
GrowlGNTPCallback_Closed,
GrowlGNTPCallback_Clicked
} GrowlGNTPCallbackType;

/*!
 *  @brief Return codes for the various requests, these should be sent back to the originating host
 *
 * 100 - [reserved]
 * Reserved for future use
 *
 * 200 - TIMED_OUT
 * The server timed out waiting for the request to complete
 *
 * 201 - NETWORK_FAILURE
 * The server was unavailable or the client could not reach the server for any reason
 *
 * 300 - INVALID_REQUEST
 * The request contained an unsupported directive, invalid headers or values, or was otherwise malformed
 *
 * 301 - UNKNOWN_PROTOCOL
 * The request was not a GNTP request
 *
 * 302 - UNKNOWN_PROTOCOL_VERSION
 * The request specified an unknown or unsupported GNTP version
 *
 * 303 - REQUIRED_HEADER_MISSING
 * The request was missing required information
 *
 * 400 - NOT_AUTHORIZED
 * The request supplied a missing or wrong password/key or was otherwise not authorized
 *
 * 401 - UNKNOWN_APPLICATION
 * Application is not registered to send notifications
 *
 * 402 - UNKNOWN_NOTIFICATION
 * Notification type is not registered by the application
 *
 * 500 - INTERNAL_SERVER_ERROR
 * An internal server error occurred while processing the request
 *
 */
typedef enum {
	GrowlGNTPReservedErrorCode = 100,
	GrowlGNTPRequestTimedOutErrorCode = 200,
	GrowlGNTPNetworkFailureErrorCode = 201,
	GrowlGNTPInvalidRequestErrorCode = 300,
	GrowlGNTPUnknownProtocolErrorCode = 301,
	GrowlGNTPUnknownProtocolVersionErrorCode = 302,
	GrowlGNTPRequiredHeaderMissingErrorCdoe = 303,
	GrowlGNTPUnauthorizedErrorCode = 400,
	GrowlGNTPUnknownApplicationErrorCode = 401,
	GrowlGNTPUnknownNotificationErrorCode = 402,
	GrowlGNTPInternalServerErrorErrorCode = 500,
   GrowlGNTPUserDisabledErrorCode = 1001
} GrowlGNTPErrorCode;

#pragma mark Encryption

extern NSString *GrowlGNTPMD5;
extern NSString *GrowlGNTPSHA1;
extern NSString *GrowlGNTPSHA256;
extern NSString *GrowlGNTPSHA512;
extern NSString *GrowlGNTPNone;
extern NSString *GrowlGNTPAES;
extern NSString *GrowlGNTPDES;
extern NSString *GrowlGNTP3DES;

typedef enum
{
	GNTPNone,
	GNTPAES,
	GNTPDES,
	GNTP3DES
} GrowlGNTPEncryptionAlgorithm;

typedef enum
{
	GNTPNoHash,
	GNTPMD5,
	GNTPSHA1,
	GNTPSHA256,
	GNTPSHA512
} GrowlGNTPHashingAlgorithm;

#pragma mark Callback Results
extern NSString *GrowlGNTPCallbackClicked;
extern NSString *GrowlGNTPCallbackClosed;
extern NSString *GrowlGNTPCallbackTimedout;
extern NSString *GrowlGNTPCallbackClick;
extern NSString *GrowlGNTPCallbackClose;
extern NSString *GrowlGNTPCallbackTimeout;

#pragma mark Requests
//Request Types
extern NSString *GrowlGNTPRegisterMessageType;
extern NSString *GrowlGNTPNotificationMessageType;
extern NSString *GrowlGNTPSubscribeMessageType;

#pragma mark Responses
//Response Types
extern NSString *GrowlGNTPOKResponseType;
extern NSString *GrowlGNTPErrorResponseType;

#pragma mark Callbacks
//Callback Types
extern NSString *GrowlGNTPCallbackTypeHeader;


#pragma mark Registration Headers

/* @brief Application-Name: <string>
 * @discussion The name of the application that is registering
 * @required
 */
extern NSString *GrowlGNTPApplicationNameHeader;

/* @brief Application-Icon: <url> | <uniqueid>
 * @discussion The icon of the application
 * @optional
 */
extern NSString *GrowlGNTPApplicationIconHeader;

/* @brief Notifications-Count: <int>
 * @discussion The number of notifications being registered
 * @required
 */
extern NSString *GrowlGNTPNotificationCountHeader;

/* @brief Notification-Name: <string>
 * @discussion The name (type) of the notification being registered
 * @required
 */
extern NSString *GrowlGNTPNotificationName;

/* @brief Notification-Display-Name: <string>
 * @discussion The name of the notification that is displayed to the user (defaults to the same value as Notification-Name)
 * @optional
 */
extern NSString *GrowlGNTPNotificationDisplayName;

/* @brief Notification-Enabled: <boolean>
 * @discussion Indicates if the notification should be enabled by default (defaults to False)
 * @optional
 */
extern NSString *GrowlGNTPNotificationEnabled;

/* @brief Notification-Icon: <url> | <uniqueid>
 * @discussion The default icon to use for notifications of this type
 * @optional
 */
extern NSString *GrowlGNTPNotificationIcon;

//Notify

#pragma mark Notify Headers

/* @brief Application-Name: <string>
 * @discussion The name of the application that sending the notification (must match a previously registered application)
 * @required
 */

/* @brief Notification-Name: <string>
 * @discussion The name (type) of the notification (must match a previously registered notification name registered by the application specified in Application-Name)
 * @required
 */

/* @brief Notification-ID: <string>
 * @discussion A unique ID for the notification. If present, serves as a hint to the notification system that this notification should replace any existing on-screen notification with the same ID. This can be used to update an existing notification. The notification system may ignore this hint. 
 * @optional
 */
extern NSString *GrowlGNTPNotificationID;

/* @brief Notification-Title: <string>
 * @discussion The notification's title
 * @required
 */
extern NSString *GrowlGNTPNotificationTitle;


/* @brief Notification-Text: <string>
 * @discussion The notification's text. (defaults to "")
 * @optional
 */
extern NSString *GrowlGNTPNotificationText;

/* @brief Notification-Sticky: <boolean>
 * @discussion Indicates if the notification should remain displayed until dismissed by the user. (default to False)
 * @optional
 */
extern NSString *GrowlGNTPNotificationSticky;

/* @brief Notification-Priority: <int>
 * @discussion A higher number indicates a higher priority. This is a display hint for the receiver which may be ignored. (valid values are between -2 and 2, defaults to 0)
 * @optional
 */
extern NSString *GrowlGNTPNotificationPriority;

/* @brief Notification-Icon: <url> | <uniqueid>
 * @discussion The icon to display with the notification.
 * @optional
 */
extern NSString *GrowlGNTPNotificationIcon;

/* @brief Notification-Callback-Context: <string>
 * @discussion Any data (will be passed back in the callback unmodified)
 * @optional
 */
extern NSString *GrowlGNTPNotificationCallbackContext;

/* @brief Notification-Callback-Context-Type: <string>
 * @discussion The type of data being passed in Notification-Callback-Context (will be passed back in the callback unmodified). This does not need to be of any pre-defined type, it is only a convenience to the sending application.
 * @optional unless Notification-Callbak-Context is defined
 */
extern NSString *GrowlGNTPNotificationCallbackContextType;

/* @brief Notification-Callback-Target: <string>
 * @discussion An alternate target for callbacks from this notification. If passed, the standard behavior of performing the callback over the original socket will be ignored and the callback data will be passed to this target instead. See the 'Url Callbacks' section for more information.
 * @optional
 */
extern NSString *GrowlGNTPNotificationCallbackTarget;

#pragma mark Subscribe Headers
//Subscribe

/* @brief Subscriber-ID: <string>
 * @discussion A unique id (UUID) that identifies the subscriber
 * @required
 */
extern NSString *GrowlGNTPSubscriberID;

/* @brief Subscriber-Name: <string>
 * @discussion The friendly name of the subscribing machine
 * @required
 */
extern NSString *GrowlGNTPSubscriberName;

/* @brief Subscriber-Port: <int>
 * @discussion The port that the subscriber will listen for notifications on (defaults to the standard 23053)
 * @optional
 */
extern NSString *GrowlGNTPSubscriberPort;


/* @brief Subscription-TTL: <int>
 * @discussion The number of seconds the subscription is valid for
 * @required
 */
extern NSString *GrowlGNTPResponseSubscriptionTTL;

#pragma mark Callback Headers
//-CALLBACK

/* @brief Notification-Callback-Result: <string>
 * @discussion [CLICKED|CLOSED|TIMEDOUT] | [CLICK|CLOSE|TIMEOUT]
 * @required
 */
extern NSString *GrowlGNTPNotificationCallbackResult;

/* @brief Notification-Callback-Timestamp: <date>
 * @discussion The date and time the callback occurred
 * @required
 */
extern NSString *GrowlGNTPNotificationCallbackTimestamp;


#pragma mark Generic Headers
//Generic Headers

/* @brief Origin-Machine-Name: <string>
 * @discussion The machine name/host name of the sending computer
 * @optional
 */
extern NSString *GrowlGNTPOriginMachineName;

/* @brief Origin-Software-Name: <string>
 * @discussion The identity of the sending framework. Example: GrowlAIRConnector
 * @optional
 */
extern NSString *GrowlGNTPOriginSoftwareName;

/* @brief Origin-Software-Version: <string>
 * @discussion The version of the sending framework. Example: 1.2
 * @optional
 */
extern NSString *GrowlGNTPOriginSoftwareVersion;

/* @brief Origin-Platform-Name: <string>
 * @discussion The identify of the sending computer OS/platform. Example: Mac OS X
 * @optional
 */
extern NSString *GrowlGNTPOriginPlatformName;

/* @brief Origin-Platform-Version: <string>
 * @discussion The version of the the sending computer OS/platform. Example: 10.6
 * @optional
 */
extern NSString *GrowlGNTPOriginPlatformVersion;


#pragma mark Extension Headers
//Extension Headers

/* @brief X-
 * @discussion the prefix to apply to an extension header
 * @optional
 */
extern NSString *GrowlGNTPExtensionPrefix;

/* @brief X-Application-BundleID: <string>
 * @discussion Growl (Mac OS X) - Used for application registration to identify the registering bundle ID, which is in reverse domain name notation.
 * @optional
 */
extern NSString *GrowlGNTPApplicationBundleIDHeader;

/* @brief X-Application-PID: <string>
 * @discussion Growl (Mac OS X) - Used for application registration to identify the registering application's process id.
 * @optional
 */
extern NSString *GrowlGNTPApplicationPIDHeader;

#pragma mark Data Headers
//Application Data Headers

/* @brief Data-
 * @discussion the prefix to apply to an application specific data header
 * @optional
 */
extern NSString *GrowlGNTPApplicationDataPrefix;
