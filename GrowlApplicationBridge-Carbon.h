//
//  GrowlApplicationBridge-Carbon.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Based on GrowlApplicationBridge.h by Evan Schoenberg.
//  This source code is in the public domain. You may freely link it into any
//    program.
//

#ifndef _GROWLAPPLICATIONBRIDGE_CARBON_H_
#define _GROWLAPPLICATIONBRIDGE_CARBON_H_

#include <sys/cdefs.h>
#include <Carbon/Carbon.h>

/*!	@header GrowlApplicationBridge-Carbon.h
 *	@abstract	Declares an API that Carbon applications can use to interact with Growl.
 *	@discussion	GrowlApplicationBridge uses a delegate to provide information
 *	 to Growl (such as your application's name and what notifications it may
 *	 post) and to provide information to your application (such as that Growl
 *	 is listening for notifications or that a notification has been clicked).
 *
 *	 You can set the Growldelegate with Growl_SetDelegate and find out the
 *	 current delegate with Growl_GetDelegate. See struct Growl_Delegate for more
 *	 information about the delegate.
 */

__BEGIN_DECLS

/*!	@struct Growl_Delegate
 *	@abstract Delegate to supply GrowlApplicationBridge with information and respond to events.
 *	@discussion The Growl delegate provides your interface to
 *	 GrowlApplicationBridge. When GrowlApplicationBridge needs information about
 *	 your application, it looks for it in the delegate; when Growl or the user
 *	 does something that you might be interested in, GrowlApplicationBridge
 *	 looks for a callback in the delegate and calls it if present
 *	 (meaning, if it is not NULL).
 */
struct Growl_Delegate {
	/*!	@field size
	 *	@abstract The size of the delegate structure.
	 *	@discussion This should be sizeof(struct Growl_Delegate).
	 */
	size_t size;

	/*Required attributes. Setting the Growl delegate will fail if any of these
	 *	is NULL.
	 */

	/*!	@field applicationName
	 *	@abstract The name of your application.
	 *	@discussion This name is used both internally and in the Growl preferences.
	 *
	 *	 This should remain stable between different versions and incarnations of
	 *	 your application.
	 *	 For example, "SurfWriter" is a good app name, whereas "SurfWriter 2.0" and
	 *	 "SurfWriter Lite" are not.
	 */
	CFStringRef applicationName;

	//Optional attributes. These can be NULL.

	/*!	@field registrationDictionary
	 *	@abstract	A dictionary describing your application and the notifications it can send out.
	 *	@discussion
	 *Must contain at least these keys:
	 *	GROWL_NOTIFICATIONS_ALL (CFArray):
	 *		Contains the names of all notifications your application may post.
	 *
	 *Can also contain these keys:
	 *	GROWL_NOTIFICATIONS_DEFAULT (CFArray):
	 *		Names of notifications that should be enabled by default.
	 *		If omitted, GROWL_NOTIFICATIONS_ALL will be used.
	 *	GROWL_APP_NAME (CFString):
	 *		Same as the applicationName member of this structure.
	 *		If both are present, the applicationName member shall prevail.
	 *		If this key is present, you may omit applicationName (set it to NULL).
	 *	GROWL_APP_ICON (CFData):
	 *		Same as the iconData member of this structure.
	 *		If both are present, the iconData member shall prevail.
	 *		If this key is present, you may omit iconData (set it to NULL).
	 *
	 *If you change the contents of this dictionary after setting the delegate,
	 *	be sure to call Growl_Reregister.
	 */
	CFDictionaryRef registrationDictionary;

	/*!	@field	applicationIconData
	 *	@abstract	Your application's icon.
	 *	@discussion	The data can be in any format supported by NSImage. As of
	 *	 Mac OS X 10.3, this includes the .icns, TIFF, JPEG, GIF, PNG, PDF, and
	 *	 PICT formats.
	 *
	 *	 If this is not supplied, Growl will look up your application's icon by
	 *	 its application name.
	 */
	CFDataRef applicationIconData;

	/*Installer display attributes
	 *
	 *These four attributes are used by the Growl installer, if this framework
	 *	supports it.
	 *For any of these being NULL, a localised default will be supplied.
	 */

	/*!	@field	growlInstallationWindowTitle
	 *	@abstract	The title of the installation window.
	 *	@discussion	If this is NULL, Growl will use a default, localized title.
	 *	
	 *	 Only used if you're using Growl-WithInstaller.framework. Otherwise,
	 *	 this member is ignored.
	 */
	CFStringRef growlInstallationWindowTitle;
	/*!	@field	growlInstallationInformation
	 *	@abstract	Text to display in the installation window.
	 *	@discussion	This information may be as long or short as desired (the
	 *	 window will be sized to fit it).  If Growl is not installed, it will
	 *	 be displayed to the user as an explanation of what Growl is and what
	 *	 it can do in your application.
	 *	 It should probably note that no download is required to install.
	 *
	 *	 If this is NULL, Growl will use a default, localized explanation.
	 *	
	 *	 Only used if you're using Growl-WithInstaller.framework. Otherwise,
	 *	 this member is ignored.
	 */
	CFStringRef growlInstallationInformation;
	/*!	@field	growlUpdateWindowTitle
	 *	@abstract	The title of the update window.
	 *	@discussion	If this is NULL, Growl will use a default, localized title.
	 *	
	 *	 Only used if you're using Growl-WithInstaller.framework. Otherwise,
	 *	 this member is ignored.
	 */
	CFStringRef growlUpdateWindowTitle;
	/*!	@field	growlUpdateInformation
	 *	@abstract	Text to display in the update window.
	 *	@discussion	This information may be as long or short as desired (the
	 *	 window will be sized to fit it).  If an older version of Growl is
	 *	 installed, it will be displayed to the user as an explanation that an
	 *	 updated version of Growl is included in your application and
	 *	 no download is required.
	 *
	 *	 If this is NULL, Growl will use a default, localized explanation.
	 *	
	 *	 Only used if you're using Growl-WithInstaller.framework. Otherwise,
	 *	 this member is ignored.
	 */
	CFStringRef growlUpdateInformation;

	/*!	@field referenceCount
	 *	@abstract	A count of owners of the delegate.
	 *	@discussion	This member is provided for use by your retain and release
	 *	 callbacks (see below).
	 *	
	 *	 GrowlApplicationBridge never directly uses this member. Instead, it
	 *	 calls your retain callback (if non-NULL) and your release callback
	 *	 (if non-NULL).
	 */
	unsigned referenceCount;

	//Functions. Currently all of these are optional (any of them can be NULL).

	/*!	@field	retain
	 *	@abstract	Called when GrowlApplicationBridge receives this delegate.
	 *	@discussion	
	 *	 When you call Growl_SetDelegate(newDelegate), it will call
	 *	 oldDelegate->release(oldDelegate), and then it will call
	 *	 newDelegate->retain(newDelegate), and the return value from retain
	 *	 is what will be set as the delegate.
	 *	 (This means that this member works like CFRetain and -[NSObject retain].)
	 *	 This member is optional (it can be NULL).
	 *	 For a delegate allocated with malloc, this member would be NULL.
	 *	@result	A delegate to which GrowlApplicationBridge holds a reference.
	 */
	void *(*retain)(void *);
	/*!	@field	release
	 *	@abstract	Called when GrowlApplicationBridge no longer needs this delegate.
	 *	@discussion	
	 *	 When you call Growl_SetDelegate(newDelegate), it will call
	 *	 oldDelegate->release(oldDelegate), and then it will call
	 *	 newDelegate->retain(newDelegate), and the return value from retain
	 *	 is what will be set as the delegate.
	 *	 (This means that this member works like CFRelease and -[NSObject release].)
	 *	 This member is optional (it can be NULL).
	 *	 For a delegate allocated with malloc, this member would be free(3).
	 */
	void (*release)(void *);

	/*!	@field	growlIsReady
	 *	@abstract	Called when GrowlHelperApp is listening for notifications.
	 *	@discussion	
	 *	 Informs the delegate that Growl (specifically, the GrowlHelperApp) was
	 *	 launched successfully (or was already running). The application can
	 *	 take actions with the knowledge that Growl is installed and functional.
	 */
	void (*growlIsReady)(void);

	/*!	@field	growlNotificationWasClicked
	 *	@abstract	Called when a Growl notification is clicked.
	 *	@discussion	
	 *	 Informs the delegate that a Growl notification was clicked. It is only
	 *	 sent for notifications sent with a non-NULL clickContext, so if you
	 *	 want to receive a message when a notification is clicked, clickContext
	 *	 must not be NULL when calling Growl_PostNotification or
	 *	 Growl_NotifyWithTitleDescriptionNameIconPriorityStickyClickContext.
	 */
	void (*growlNotificationWasClicked)(CFPropertyListRef clickContext);
};

/*!	@struct Growl_Delegate
 *	@abstract Delegate to supply GrowlApplicationBridge with information and respond to events.
 *	@discussion The Growl delegate provides your interface to
 *	 GrowlApplicationBridge. When GrowlApplicationBridge needs information about
 *	 your application, it looks for it in the delegate; when Growl or the user
 *	 does something that you might be interested in, GrowlApplicationBridge
 *	 looks for a callback in the delegate and calls it if present
 *	 (meaning, if it is not NULL).
 */

struct Growl_Notification {
	/*!	@field	size
	 *	@abstract	The size of the notification structure.
	 *	@discussion	This should be sizeof(struct Growl_Notification).
	 */
 	size_t size;

	/*!	@field	name
	 *	@abstract	Identifies the notification.
	 *	@discussion	The notification name distinguishes one type of
	 *	 notification from another. The name should be human-readable, as it
	 *	 will be displayed in the Growl preference pane.
	 *
	 *	 The name is used in the GROWL_NOTIFICATIONS_ALL and
	 *	 GROWL_NOTIFICATIONS_DEFAULT arrays in the registration dictionary, and
	 *	 in this member of the Growl_Notification structure.
	 */
	CFStringRef name;

	/*!	@field	title
	 *	@abstract	Short synopsis of the notification.
	 *	@discussion	A notification's title describes the notification briefly.
	 *	 It should be easy to read quickly by the user. 
	 */
	CFStringRef title;

	/*!	@field	description
	 *	@abstract	Additional text.
	 *	@discussion	The description supplements the title with more
	 *	 information. It is usually longer and sometimes involves a list of
	 *	 subjects. For example, for a 'Download complete' notification, the
	 *	 description might have one filename per line. GrowlMail in Growl 0.6
	 *	 uses a description of '%d new mail(s)' (formatted with the number of
	 *	 messages).
	 */
	CFStringRef description;

	/*!	@field	iconData
	 *	@abstract	An icon for the notification.
	 *	@discussion	The notification icon usually indicates either what
	 *	 happened (it may have the same icon as e.g. a toolbar item that
	 *	 started the process that led to the notification), or what it happened
	 *	 to (e.g. a document icon).
	 *
	 *	 The icon data is optional, so it can be NULL. In that case, the
	 *	 application icon is used by itself. Not all displays support icons.
	 *
	 *	 The data can be in any format supported by NSImage. As of Mac OS X
	 *	 10.3, this includes the .icns, TIFF, JPEG, GIF, PNG, PDF, and PICT form
	 *	 ats.
	 */
	CFDataRef iconData;

	/*!	@field	priority
	 *	@abstract	An indicator of the notification's importance.
	 *	@discussion	Priority is new in Growl 0.6, and is represented as a
	 *	 signed integer from -2 to +2. 0 is Normal priority, -2 is Very Low
	 *	 priority, and +2 is Very High priority.
	 *
	 *	 Not all displays support priority. If you do not wish to assign a
	 *	 priority to your notification, assign 0.
	 */
	signed int priority;

	/*!	@field	reserved
	 *	@abstract	Bits reserved for future usage.
	 *	@discussion	These bits are not used in Growl 0.6. Set them to 0.
	 */
	unsigned reserved: 31;

	/*!	@field	sticky
	 *	@abstract	Requests that a notification stay on-screen until dismissed
	 *	 explicitly.
	 *	@discussion	When the sticky bit is clear, in most displays,
	 *	 notifications disappear after a certain amount of time. Sticky
	 *	 notifications, however, remain on-screen until the user dismisses them
	 *	 explicitly, usually by clicking them.
	 *
	 *	 Sticky notifications were introduced in Growl 0.6. Most notifications
	 *	 should not be sticky. Not all displays support sticky notifications,
	 *	 and the user may choose in Growl's preference pane to force the
	 *	 notification to be sticky or non-sticky, in which case the sticky bit
	 *	 in the notification will be ignored.
	 */
	unsigned isSticky: 1;

	/*!	@field	clickContext
	 *	@abstract	An identifier to be passed to your click callback when a
	 *	 notification is clicked.
	 *	@discussion	If this is not NULL, and your click callback is not
	 *	 NULL either, this will be passed to the callback when your
	 *	 notification is clicked by the user.
	 *
	 *	 Click feedback was introduced in Growl 0.6, and it is optional. Not
	 *	 all displays support click feedback.
	 */
	CFPropertyListRef clickContext;

	/*!	@field	clickCallback
	 *	@abstract	A callback to call when the notification is clicked.
	 *	@discussion	If this is not NULL, it will be called instead of the
	 *	 Growl delegate's click callback when clickContext is non-NULL and the
	 *	 notification is clicked on by the user.
	 *
	 *	 Click feedback was introduced in Growl 0.6, and it is optional. Not
	 *	 all displays support click feedback.
	 */
	void (*clickCallback)(CFPropertyListRef clickContext);
};

#pragma mark -
#pragma mark Easy initialisers

/*!	@defined	InitGrowlDelegate
 *	@abstract	Callable macro. Initializes a Growl delegate structure to defaults.
 *	@discussion	Call with a pointer to a struct Growl_Delegate. All of the
 *	 members of the structure will be set to 0 or NULL, except for size (which
 *	 will be set to sizeof(struct Growl_Delegate)) and referenceCount (which
 *	 will be set to 1).
 */
#define InitGrowlDelegate(delegate) \
	do { \
		if((delegate) != NULL) { \
			(delegate)->size = sizeof(struct Growl_Delegate); \
			(delegate)->applicationName = NULL; \
			(delegate)->registrationDictionary = NULL; \
			(delegate)->applicationIconData = NULL; \
			(delegate)->growlInstallationWindowTitle = NULL; \
			(delegate)->growlInstallationInformation = NULL; \
			(delegate)->growlUpdateWindowTitle = NULL; \
			(delegate)->growlUpdateInformation = NULL; \
			(delegate)->referenceCount = 1U; \
			(delegate)->retain = NULL; \
			(delegate)->release = NULL; \
			(delegate)->growlIsReady = NULL; \
			(delegate)->growlNotificationWasClicked = NULL; \
		} \
	} while(0)

/*!	@defined	InitGrowlNotification
 *	@abstract	Callable macro. Initializes a Growl notification structure to defaults.
 *	@discussion	Call with a pointer to a struct Growl_Notification. All of
 *	 the members of the structure will be set to 0 or NULL, except for size
 *	 (which will be set to sizeof(struct Growl_Notification)).
 */
#define InitGrowlNotification(notification) \
	do { \
		if((notification) != NULL) { \
			(notification)->size = sizeof(struct Growl_Notification); \
			(notification)->name = NULL; \
			(notification)->title = NULL; \
			(notification)->description = NULL; \
			(notification)->iconData = NULL; \
			(notification)->priority = 0; \
			(notification)->reserved = 0U; \
			(notification)->isSticky = false; \
			(notification)->clickContext = NULL; \
		} \
	} while(0)

#pragma mark -
#pragma mark Public API

/*!	@function	Growl_SetDelegate
 *	@abstract	Replaces the current Growl delegate with a new one, or removes
 *	 the Growl delegate.
 *	@param	newDelegate
 *	@result	Returns false and does nothing else if a pointer that was passed in
 *	 is unsatisfactory (because it is non-NULL, but at least one required
 *	 member of it is NULL). Otherwise, sets or unsets the delegate and returns
 *	 true.
 *	@discussion	When <code>newDelegate</code> is non-NULL, sets the delegate to
 *	 <code>newDelegate</code>. When it is NULL, the current delegate will be
 *	 unset, and no delegate will be in place.
 *
 *	 It is legal for <code>newDelegate</code> to be the current delegate;
 *	 nothing will happen, and Growl_SetDelegate will return true. It is also
 *	 legal for it to be NULL, as described above; again, it will return true.
 *
 *	 If there was a delegate in place before the call, Growl_SetDelegate will
 *	 call the old delegate's release member if it was non-NULL. If
 *	 <code>newDelegate</code> is non-NULL, Growl_SetDelegate will call
 *	 <code>newDelegate->retain</code>, and set the delegate to its return value.
 *
 *	 If you are using Growl-WithInstaller.framework, and an older version of
 *	 Growl is installed on the user's system, the user will automatically be
 *	 prompted to update.
 *
 *	 GrowlApplicationBridge currently does not copy this structure, nor does it
 *	 retain any of the CF objects in the structure (it regards the structure as
 *	 a container that retains the objects when they are added and releases them
 *	 when they are removed or the structure is destroyed). Also,
 *	 GrowlApplicationBridge currently does not modify any member of the
 *	 structure, except possibly the referenceCount by calling the retain and
 *	 release members.
 */
Boolean Growl_SetDelegate(struct Growl_Delegate *newDelegate);

/*!	@function	Growl_GetDelegate
 *	@abstract	Returns the current Growl delegate, if any.
 *	@result	The current Growl delegate.
 *	@discussion	Returns the last pointer passed into Growl_SetDelegate, or NULL
 *	 if no such call has been made.
 *
 *	 This function follows standard Core Foundation reference-counting rules.
 *	 Because it is a Get function, not a Copy function, it will not retain the
 *	 delegate on your behalf. You are responsible for retaining and releasing
 *	 the delegate as needed.
 */
struct Growl_Delegate *Growl_GetDelegate(void);

/*!	@function	Growl_PostNotification
 *	@abstract	Posts a Growl notification.
 *	@param	notification	The notification to post.
 *	@discussion	This is the preferred means for sending a Growl notification.
 *	 The notification name and at least one of the title and description are
 *	 required (all three are preferred). All other parameters may be NULL (or 0
 *	 or false as appropriate) to accept default values.
 *
 *	 If using the Growl-WithInstaller framework, if Growl is not installed the
 *	 user will be prompted to install Growl.
 *	 If the user cancels, this method will have no effect until the next
 *	 application session, at which time when it is called the user will be
 *	 prompted again. The user is also given the option to not be prompted again.
 *	 If the user does choose to install Growl, the requested notification will
 *	 be displayed once Growl is installed and running.
 */
void Growl_PostNotification(const struct Growl_Notification *notification);

/*!	@function Growl_PostNotificationWithDictionary
*	@abstract	Notifies using a userInfo dictionary suitable for passing to
*	 CFDistributedNotificationCenter.
*	@param	userInfo	The dictionary to notify with.
*	@discussion	Before Growl 0.6, your application would have posted
*	 notifications using CFDistributedNotificationCenter by creating a userInfo
*	 dictionary with the notification data. This had the advantage of allowing
*	 you to add other data to the dictionary for programs besides Growl that
*	 might be listening.
*	 
*	 This method allows you to use such dictionaries without being restricted
*	 to using CFDistributedNotificationCenter. The keys for this dictionary
 *	 can be found in GrowlDefinesCarbon.h.
*/
void Growl_PostNotificationWithDictionary(CFDictionaryRef userInfo);

/*!	@function	Growl_NotifyWithTitleDescriptionNameIconPriorityStickyClickContext
 *	@abstract	Posts a Growl notification using parameter values.
 *	@param	title	The title of the notification.
 *	@param	description	The description of the notification.
 *	@param	notificationName	The name of the notification as listed in the
 *	 Growl delegate.
 *	@param	iconData	Data representing a notification icon. Can be NULL.
 *	@param	priority	The priority of the notification (-2 to +2, with -2
 *	 being Very Low and +2 being Very High).
 *	@param	isSticky	If true, requests that this notification wait for a
 *	 response from the user.
 *	@param	clickContext	An object to pass to the clickCallback, if any. Can
 *	 be NULL, in which case the clickCallback is not called.
 *	@discussion	Creates a temporary Growl_Notification, fills it out with the
 *	 supplied information, and calls Growl_PostNotification on it.
 *	 See struct Growl_Notification and Growl_PostNotification for more
 *	 information.
 *
 *	 The icon data can be in any format supported by NSImage. As of Mac OS X
 *	 10.3, this includes the .icns, TIFF, JPEG, GIF, PNG, PDF, and PICT formats.
 */
void Growl_NotifyWithTitleDescriptionNameIconPriorityStickyClickContext(
 /*inhale*/
	CFStringRef title,
	CFStringRef description,
	CFStringRef notificationName,
	CFDataRef iconData,
	signed int priority,
	Boolean isSticky,
	CFPropertyListRef clickContext);

/*!	@function	Growl_Reregister
 *	@abstract	Updates your registration with Growl.
 *	@discussion	If your application changes the contents of the
 *	 GROWL_NOTIFICATIONS_ALL key in the registrationDictionary member of the
 *	 Growl delegate, or if it changes the value of that member, call this
 *	 function to have Growl update its registration information for your
 *	 application.
 *
 *	 This function does not normally need to be called. Your application will
 *	 be registered when you set the delegate if both the delegate and its
 *	 registrationDictionary member are non-NULL.
 */
void Growl_Reregister(void);

/*!	@function	Growl_IsInstalled
 *	@abstract	Determines whether the Growl prefpane and its helper app are
 *	 installed.
 *	@result	Returns true if Growl is installed, false otherwise.
 */
Boolean Growl_IsInstalled(void);

/*!	@function	Growl_IsRunning
 *	@abstract	Cycles through the process list to find whether GrowlHelperApp
 *	 is running.
 *	@result	Returns true if Growl is running, false otherwise.
 */
Boolean Growl_IsRunning(void);

/*!	@typedef	GrowlLaunchCallback
 *	@abstract	Callback to notify you that Growl is running.
 *	@param	context	The context pointer passed to Growl_LaunchIfInstalled.
 *	@discussion	Growl_LaunchIfInstalled calls this callback function if Growl
 *	 was already running or if it launched Growl successfully.
 */
typedef void (*GrowlLaunchCallback)(void *context);

/*!	@function	Growl_LaunchIfInstalled
 *	@abstract	Launches GrowlHelperApp if it is not already running.
 *	@param	callback	A callback function which will be called if Growl was successfully
 *	 launched or was already running. Can be NULL.
 *	@param	context	The context pointer to pass to the callback. Can be NULL.
 *	@result	Returns true if Growl was successfully launched or was already
 *	 running; returns false and does not call the callback otherwise.
 *	@discussion	Returns true and calls the callback (if the callback is not
 *	 NULL) if the Growl helper app began launching or was already running.
 *	 Returns false and performs no other action if Growl could not be launched
 *	 (e.g. because the Growl preference pane is not properly installed).
 *
 *	 If a delegate has been set with Growl_SetDelegate, and if the delegate has
 *	 a registration dictionary (see struct Growl_Delegate above), this function
 *	 will register with Growl atomically.
 *
 *	 The callback should take a single argument; this is to allow applications
 *	 to have context-relevant information passed back. It is perfectly
 *	 acceptable for context to be NULL. The callback itself can be NULL if you
 *	 don't want one.
 */
Boolean Growl_LaunchIfInstalled(GrowlLaunchCallback callback, void *context);

#pragma mark -
#pragma mark Deprecated API

/*!	@function	LaunchGrowlIfInstalled
 *	@abstract	Older name for Growl_LaunchIfInstalled.
 *	@param	callback	A callback function which will be called if Growl was successfully
 *	 launched or was already running. Can be NULL.
 *	@param	context	The context pointer to pass to the callback. Can be NULL.
 *	@result	Returns true if Growl was successfully launched or was already
 *	 running; returns false and does not call the callback otherwise.
 *	@discussion	The name of this function changed in Growl 0.6 to be uniform
 *	 with the functions that were added. The old name is preserved for
 *	 compatibility with GrowlAppBridge.framework from Growl 0.5.
 *	@deprecated	in Growl 0.6
 */
Boolean LaunchGrowlIfInstalled(GrowlLaunchCallback callback, void *context);

#pragma mark -
#pragma mark Constants

/*!	@defined	GROWL_PREFPANE_BUNDLE_IDENTIFIER
 *	@abstract	The CFBundleIdentifier of the Growl preference pane bundle.
 *	@discussion	GrowlApplicationBridge uses this to determine whether Growl is
 *	 currently installed, by searching for the Growl preference pane. Your
 *	 application probably does not need to use this macro itself.
 */
#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	CFSTR("com.growl.prefpanel")

__END_DECLS

#endif /* _GROWLAPPLICATIONBRIDGE_CARBON_H_ */

