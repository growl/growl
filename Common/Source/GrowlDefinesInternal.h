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

#ifdef __OBJC__
#define XSTR(x) (@x)
#else /* !__OBJC__ */
#define XSTR CFSTR
#endif /* __OBJC__ */

/*!	@header	GrowlDefinesInternal.h
 *	@abstract	Defines internal Growl macros and types.
 *	@discussion	These constants are used both by GrowlHelperApp and by plug-ins.
 *	 
 *	 Notification keys (used in GrowlHelperApp, in GrowlApplicationBridge, and
 *	 by applications that don't use GrowlApplicationBridge) are defined in
 *	 GrowlDefines.h.
 */

/*!	@defined	GROWL_TCP_PORT
 *	@abstract	The TCP listen port for Growl notification servers.
 */
#define GROWL_TCP_PORT	23052

/*!	@defined	GROWL_UDP_PORT
 *	@abstract	The UDP listen port for Growl notification servers.
 */
#define GROWL_UDP_PORT	9887

/*!	@defined	GROWL_PROTOCOL_VERSION
 *	@abstract	The current version of the Growl network-notifications protocol.
 */
#define GROWL_PROTOCOL_VERSION	1

/*!	@defined	GROWL_TYPE_REGISTRATION
 *	@abstract	The packet type of registration packets.
 */
#define GROWL_TYPE_REGISTRATION	0
/*!	@defined	GROWL_TYPE_NOTIFICATION
 *	@abstract	The packet type of notification packets.
 */
#define GROWL_TYPE_NOTIFICATION	1

/*!	@struct	GrowlNetworkPacket
 *	@abstract	This struct is a header common to all incoming Growl network
 *	 packets which identifies the type and version of the packet.
 */
struct GrowlNetworkPacket {
	unsigned char version;
	unsigned char type;
} __attribute__((packed));

/*!	@struct	GrowlNetworkRegistration
 *	@abstract	The format of a registration packet.
 *	@discussion	A Growl client that wants to register with a Growl server sends
 *	 a packet in this format.
 */
struct GrowlNetworkRegistration {
	/*!	@field	common
	 *	@abstract	The Growl packet header.
	 */
	struct GrowlNetworkPacket common;
	/*!	@field	appNameLen
	 *	@abstract	The name of the application that is registering.
	 *	@discussion	This name is used both internally and in the Growl
	 *	 preferences.
	 *	 
	 *	 The application name should remain stable between different versions
	 *	 and incarnations of your application.
	 *	 For example, "SurfWriter" is a good app name, whereas "SurfWriter 2.0"
	 *	 and "SurfWriter Lite" are not.
	 *
	 *	 In addition to being unsigned, the application name length is in
	 *	 network byte order.
	 */
	unsigned short appNameLen;
	/*!	@field	numAllNotifications
	 *	@abstract	The number of notifications in the list.
	 *	@discussion	These names are used both internally and in the Growl
	 *	 preferences. For this reason, they should be human-readable.
	 */
	unsigned char numAllNotifications;
	/*!	@field	numDefaultNotifications
	 *	@abstract	The number of notifications in the list that are enabled by
	 *	 default.
	 */
	unsigned char numDefaultNotifications;
	/*!	@field	data
	 *	@abstract	Variable-sized data.
	 *	@discussion	The variable-sized data of a registration is:
	 *	 - The application name, in UTF-8 encoding, for appNameLen bytes.
	 *	 - The list of all notification names.
	 *	 - The list of default notifications, as 8-bit unsigned indices into the list of all notifications.
	 *	 - The MD5 checksum of all the data preceding the checksum.
	 *	 
	 *	 Each notification name is encoded as:
	 *	 - Length: two bytes, unsigned, network byte order.
	 *	 - Name: As many bytes of UTF-8-encoded text as the length says.
	 *	 And there are numAllNotifications of these.
	 */
	unsigned char data[];
} __attribute__((packed));

/*!	@struct	GrowlNetworkNotification
 *	@abstract	The format of a notification packet.
 *	@discussion	A Growl client that wants to post a notification to a Growl
 *	 server sends a packet in this format.
 */
struct GrowlNetworkNotification {
	/*!	@field	common
	 *	@abstract	The Growl packet header.
	 */
	struct GrowlNetworkPacket common;
	/*!	@field	flags
	 *	@abstract	The priority number and the sticky bit.
	 *	@discussion	This 16-bit packed structure contains the priority as a
	 *	 signed 3-bit integer from -2 to +2, and the priority as a single bit.
	 *	 The high 12 bits of the structure are reserved for future use.
	 */
	struct GrowlNetworkNotificationFlags {
		unsigned reserved: 12;
		signed   priority: 3;
		unsigned sticky:   1;
	} __attribute__((packed)) flags; //size = 16 (12 + 3 + 1)
	/*!	@field	nameLen
	 *	@abstract	The length of the notification name.
	 *	@discussion	In addition to being unsigned, the notification name length
	 *	 is in network byte order.
	 */
	unsigned short nameLen;
	/*!	@field	titleLen
	 *	@abstract	The length of the notification title.
	 *	@discussion	In addition to being unsigned, the title length is in
	 *	 network byte order.
	 */
	unsigned short titleLen;
	/*!	@field	descriptionLen
	 *	@abstract	The length of the notification description.
	 *	@discussion	In addition to being unsigned, the description length is in
	 *	 network byte order.
	 */
	unsigned short descriptionLen;
	/*!	@field	appNameLen
	 *	@abstract	The length of the application name.
	 *	@discussion	In addition to being unsigned, the application name length
	 *	 is in network byte order.
	 */
	unsigned short appNameLen;
	/*!	@field	data
	 *	@abstract	Variable-sized data.
	 *	@discussion	The variable-sized data of a notification is:
	 *	 - Notification name, in UTF-8 encoding, for nameLen bytes.
	 *	 - Title, in UTF-8 encoding, for titleLen bytes.
	 *	 - Description, in UTF-8 encoding, for descriptionLen bytes.
	 *	 - Application name, in UTF-8 encoding, for appNameLen bytes.
	 *	 - The MD5 checksum of all the data preceding the checksum.
	 */
	unsigned char data[];
} __attribute__((packed));

/*!	@defined	GrowlEnabledKey
 *	@abstract	Preference key controlling whether Growl is enabled.
 *	@discussion	If this is false, then when GrowlHelperApp is launched to open
 *	 a Growl registration dictionary file, GrowlHelperApp will quit when it has
 *	 finished processing the file instead of listening for notifications.
 */
#define GrowlEnabledKey					XSTR("GrowlEnabled")

#endif //ndef _GROWL_GROWLDEFINESINTERNAL_H

/* --- These following macros are intended for plug-ins --- */

/*Since anything that needs the include guards won't be using these macros, we
 *	don't need the include guards here.
 */

#ifdef __OBJC__

/*!	@function    SYNCHRONIZE_GROWL_PREFS
 *	@abstract    Synchronizes Growl prefs so they're up-to-date.
 *	@discussion  This macro is intended for use by GrowlHelperApp and by
 *	 plug-ins (when the prefpane is selected).
 */
#define SYNCHRONIZE_GROWL_PREFS() CFPreferencesAppSynchronize(CFSTR("com.Growl.GrowlHelperApp"))

/*!	@function    UPDATE_GROWL_PREFS
 *	@abstract    Tells GrowlHelperApp to update its prefs.
 *	@discussion  This macro is intended for use by plug-ins.
 *	 It sends a notification to tell GrowlHelperApp to update its preferences.
 */
#define UPDATE_GROWL_PREFS() do { \
	SYNCHRONIZE_GROWL_PREFS(); \
	[[NSDistributedNotificationCenter defaultCenter] \
		postNotificationName:@"GrowlPreferencesChanged" object:@"GrowlUserDefaults"];\
	} while(0)

/*!	@function    READ_GROWL_PREF_VALUE
 *	@abstract    Reads the given pref value from the plug-in's preferences.
 *	@discussion  This macro is intended for use by plug-ins. It reads the value for the
 *	 given key from the plug-in's preferences (which are stored in a dictionary inside of
 *	 GrowlHelperApp's prefs).
 *	@param	key	The preference key to read the value of.
 *	@param	domain	The bundle ID of the plug-in.
 *	@param	type	The type of the result expected.
 *	@param	result	A pointer to an id. Set to the value if exists, left unchanged if not.
 *	
 *	 If the value is set, you are responsible for releasing it.
 */
#define READ_GROWL_PREF_VALUE(key, domain, type, result) do {\
	CFDictionaryRef prefs = (CFDictionaryRef)CFPreferencesCopyAppValue((CFStringRef)domain, \
																		CFSTR("com.Growl.GrowlHelperApp")); \
	if (prefs != NULL) {\
		if (CFDictionaryContainsKey(prefs, key)) {\
			*result = (type)CFDictionaryGetValue(prefs, key); \
			CFRetain(*result); \
		} \
		CFRelease(prefs); } \
	} while(0)

/*!	@function    WRITE_GROWL_PREF_VALUE
 *	@abstract    Writes the given pref value to the plug-in's preferences.
 *	@discussion  This macro is intended for use by plug-ins. It writes the given
 *	 value to the plug-in's preferences.
 *	@param	key	The preference key to write the value of.
 *	@param	value	The value to write to the preferences. It should be either a
 *	 CoreFoundation type or toll-free bridged with one.
 *	@param	domain	The bundle ID of the plug-in.
 */
#define WRITE_GROWL_PREF_VALUE(key, value, domain) do {\
	CFDictionaryRef staticPrefs = (CFDictionaryRef)CFPreferencesCopyAppValue((CFStringRef)domain, \
																			 CFSTR("com.Growl.GrowlHelperApp")); \
	CFMutableDictionaryRef prefs; \
	if (staticPrefs == NULL) {\
		prefs = CFDictionaryCreateMutable(NULL, 0, NULL, NULL); \
	} else {\
		prefs = CFDictionaryCreateMutableCopy(NULL, 0, staticPrefs); \
		CFRelease(staticPrefs); \
	}\
	CFDictionarySetValue(prefs, key, value); \
	CFPreferencesSetAppValue((CFStringRef)domain, prefs, CFSTR("com.growl.GrowlHelperApp")); \
	CFRelease(prefs); } while(0)

/*!	@function    READ_GROWL_PREF_BOOL
 *	@abstract    Reads the given Boolean from the plug-in's preferences.
 *	@discussion  This is a wrapper around READ_GROWL_PREF_VALUE() intended for
 *	 use with Booleans.
 *	@param	key	The preference key to read the Boolean from.
 *	@param	domain	The bundle ID of the plug-in.
 *	@param	result	A pointer to a Boolean type. Left unchanged if the value doesn't exist.
 */
#define READ_GROWL_PREF_BOOL(key, domain, result) do {\
	CFBooleanRef boolValue = NULL; \
	READ_GROWL_PREF_VALUE(key, domain, CFBooleanRef, &boolValue); \
	if (boolValue != NULL) {\
		*result = CFBooleanGetValue(boolValue); \
		CFRelease(boolValue); \
	} } while(0)

/*!	@function    WRITE_GROWL_PREF_BOOL
 *	@abstract    Writes the given Boolean to the plug-in's preferences.
 *	@discussion  This is a wrapper around WRITE_GROWL_PREF_VALUE() intended for
 *	 use with Booleans.
 *	@param	key	The preference key to write the Boolean for.
 *	@param	value	The Boolean value to write to the preferences.
 *	@param	domain	The bundle ID of the plug-in.
 */
#define WRITE_GROWL_PREF_BOOL(key, value, domain) do {\
	CFBooleanRef boolValue; \
	if (value) {\
		boolValue = kCFBooleanTrue; \
	} else {\
		boolValue = kCFBooleanFalse; \
	}\
	WRITE_GROWL_PREF_VALUE(key, boolValue, domain); } while(0)

/*!	@function    READ_GROWL_PREF_INT
 *	@abstract    Reads the given integer from the plug-in's preferences.
 *	@discussion  This is a wrapper around READ_GROWL_PREF_VALUE() intended for
 *	 use with integers.
 *	@param	key	The preference key to read the integer from.
 *	@param	domain	The bundle ID of the plug-in.
 *	@param	result	A pointer to an integer. Leaves unchanged if the value doesn't exist.
 */
#define READ_GROWL_PREF_INT(key, domain, result) do {\
	CFNumberRef intValue = NULL; \
	READ_GROWL_PREF_VALUE(key, domain, CFNumberRef, &intValue); \
	if (intValue != NULL) {\
		CFNumberGetValue(intValue, kCFNumberIntType, result); \
		CFRelease(intValue); \
	} } while(0)

/*!	@function    WRITE_GROWL_PREF_INT
 *	@abstract    Writes the given integer to the plug-in's preferences.
 *	@discussion  This is a wrapper around WRITE_GROWL_PREF_VALUE() intended for
 *	 use with integers.
 *	@param	key	The preference key to write the integer for.
 *	@param	value	The integer value to write to the preferences.
 *	@param	domain	The bundle ID of the plug-in.
 */
#define WRITE_GROWL_PREF_INT(key, value, domain) do {\
	CFNumberRef intValue = CFNumberCreate(NULL, kCFNumberIntType, &value); \
	WRITE_GROWL_PREF_VALUE(key, intValue, domain); \
	CFRelease(intValue); } while(0)

/*!	@function    READ_GROWL_PREF_FLOAT
 *	@abstract    Reads the given float from the plug-in's preferences.
 *	@discussion  This is a wrapper around READ_GROWL_PREF_VALUE() intended for
 *	 use with floats.
 *	@param	key	The preference key to read the float from.
 *	@param	domain	The bundle ID of the plug-in.
 *	@param	result	A pointer to a float. Leaves unchanged if the value doesn't exist.
 */
#define READ_GROWL_PREF_FLOAT(key, domain, result) do {\
	CFNumberRef floatValue = NULL; \
	READ_GROWL_PREF_VALUE(key, domain, CFNumberRef, &floatValue); \
	if (floatValue != NULL) {\
		CFNumberGetValue(floatValue, kCFNumberFloatType, result); \
		CFRelease(floatValue); \
	} } while(0)

/*!	@function    WRITE_GROWL_PREF_FLOAT
 *	@abstract    Writes the given float to the plug-in's preferences.
 *	@discussion  This is a wrapper around WRITE_GROWL_PREF_VALUE() intended for
 *	 use with floats.
 *	@param	key	The preference key to write the float for.
 *	@param	value	The float value to write to the preferences.
 *	@param	domain	The bundle ID of the plug-in.
 */
#define WRITE_GROWL_PREF_FLOAT(key, value, domain) do {\
	CFNumberRef floatValue = CFNumberCreate(NULL, kCFNumberFloatType, &value); \
	WRITE_GROWL_PREF_VALUE(key, floatValue, domain); \
	CFRelease(floatValue); } while(0)

#endif /* __OBJC__ */
