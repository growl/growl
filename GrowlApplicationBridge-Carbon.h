//
//  GrowlApplicationBridge-Carbon.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on Wed Jun 18 2004.
//  Based on GrowlApplicationBridge.h by Evan Schoenberg.
//  This source code is in the public domain. You may freely link it into any
//    program.
//

#include <Carbon/Carbon.h>

typedef struct GrowlDelegate {
	size_t size; //should be sizeof(struct GrowlDelegate).

	/*Required attributes. Setting the Growl delegate will fail if any of these
	 *	is NULL.
	 */
	CFStringRef applicationName;

	//Optional attributes. These can be NULL.

	/*registrationDictionary
	 *
	 *Must contain at least these keys:
	 *	GROWL_NOTIFICATIONS_ALL (CFArray):
	 *		Contains the *names* of all notifications your app can post.
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
	 */
	CFDictionaryRef registrationDictionary;

	/*applicationIconData
	 *
	 *Contains image data in .icns, TIFF, JPEG, GIF, PNG, PDF, or PICT format.
	 *(Possibly others - whatever Cocoa's NSImage class supports.)
	 *If this is not supplied, Growl will look up your application's icon by
	 *	its application name.
	 */
	CFDataRef applicationIconData;

	/*Installer display attributes
	 *
	 *These four attributes are used by the Growl installer, if this framework
	 *	supports it.
	 *For any of these being NULL, a localised default will be supplied.
	 */
	CFStringRef growlInstallationWindowTitle;
	CFStringRef growlInstallationInformation;
	CFStringRef growlUpdateWindowTitle;
	CFStringRef growlUpdateInformation;

	/*referenceCount
	 *
	 *This member is provided for use by your retain and release callbacks
	 *	(see below).
	 *GrowlApplicationBridge does not use this member ever.
	 */
	unsigned referenceCount;

	//Functions. Currently all of these are optional (any of them can be NULL).

	/*retain and release
	 *
	 *When you call Growl_SetDelegate(newDelegate), it will call
	 *	oldDelegate->release(oldDelegate), and then it will call
	 *	newDelegate->retain(newDelegate), and the return value from retain
	 *	is what will be set as the delegate.
	 *(This means it works like CFRetain and -[NSObject retain].)
	 *These members are optional (they can be NULL).
	 *For a delegate allocated with malloc, retain would be NULL, and
	 *	release would be free(3).
	 */
	(void *)(*retain)(void *);
	void (*release)(void *);

	/*growlIsReady
	 *
	 *Informs the delegate that Growl (specifically, the GrowlHelperApp) was
	 *	launched successfully (or was already running). The application can take
	 *	actions with the knowlege that Growl is installed and functional.
	 */
	void (*growlIsReady)(void);

	/*growlNotificationWasClicked
	 *
	 *Informs the delegate that a Growl notification was clicked. It is only
	 *	sent for notifications sent with a non-NULL clickContext, so if you want
	 *	to receive a message when a notification is clicked, clickContext must
	 *	not be NULL when calling Growl_PostNotification.
	 */
	void (*growlNotificationWasClicked)(CFPropertyListRef clickContext);
} GrowlDelegate;

typedef struct GrowlNotification {
	size_t size; //should be sizeof(struct GrowlNotification)

	/*The name is used to uniquely identify the notification, e.g.
	 *	'Download finished'.
	 *
	 *It should be human-readable, as it will be displayed in the Growl
	 *	preference pane.
	 */
	CFStringRef name;
	/*The title is a short synopsis of the notification, e.g.
	 *	'Downloaded Growl-0.6.dmg'.
	 *The title can be the same as the name.
	 */
	CFStringRef title;

	/*The description generally supplements the title, e.g. '4 MB in 5 minutes'.
	 */
	CFStringRef description;

	/*iconData contains image data in .icns, TIFF, JPEG, GIF, PNG, PDF, or PICT format.
	 *(Possibly others - whatever Cocoa's NSImage class supports.)
	 */
	CFDataRef iconData;

	/*The priority of the notification. The default value is 0; positive values
	 *	are higher priority and negative values are lower priority.
	 *Not all Growl displays support priority.
	 */
	signed int priority;

	/*These bits should be set to 0.
	 */
	unsigned reserved: 31;

	/*A sticky notification stays on-screen until it is dismissed explicitly by
	 *	the user.
	 *Not all Growl displays support sticky notifications.
	 */
	unsigned isSticky: 1;

	/*This value will be passed to your growlNotificationWasClicked callback
	 *	(see GrowlDelegate above) when your notification is clicked by the user.
	 *It can safely be NULL.
	 */
	CFPropertyListRef clickContext;

	/*If this member is not NULL, it will be called instead of the
	 *	GrowlDelegate's growlNotificationWasClicked member.
	 */
	void (*clickCallback)(CFPropertyListRef clickContext);
} GrowlNotification;

#pragma mark -
#pragma mark Easy initialisers

/*InitGrowlDelegate(struct GrowlDelegate *delegate)
 *
 *Sets the delegate's size to sizeof(struct GrowlDelegate) and all its other
 *	members to 0/NULL, except referenceCount, which it sets to 1.
 */
#define InitGrowlDelegate(delegate) \
	do { \
		if((delegate) != NULL) { \
			(delegate)->size = sizeof(struct GrowlDelegate); \
			(delegate)->applicationName = NULL; \
			(delegate)->registrationDictionary = NULL; \
			(delegate)->iconData = NULL; \
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

/*InitGrowlNotification(struct GrowlNotification *notification)
 *
 *Sets the notification's size to sizeof(struct GrowlNotification) and all its
 *	other members to 0/NULL.
 */
#define InitGrowlNotification(notification) \
	do { \
		if((notification) != NULL) { \
			(notification)->size = sizeof(struct GrowlNotification);
			(notification)->name = NULL;
			(notification)->title = NULL;
			(notification)->description = NULL;
			(notification)->iconData = NULL;
			(notification)->priority = 0;
			(notification)->reserved = 0U;
			(notification)->isSticky = false;
			(notification)->clickContext = NULL;
		} \
	} while(0)

#pragma mark -
#pragma mark Public API

/*Growl_SetDelegate
 *
 *Set the object which will be responsible for providing and receiving Growl
 *	information.
 *This must be called before otherwise using GrowlApplicationBridge.  
 *
 *It is legal to pass NULL to this function.
 *
 *When this method is called, if newDelegate is non-NULL, Growl will be launched
 *	if it is not already running, and the application will be registered with
 *	Growl.
 *
 *If using the Growl-WithInstaller framework, if Growl is already installed but
 *	this copy of the framework has an updated version of Growl, the user will be
 *	prompted to update automatically.
 *
 *GrowlApplicationDelegate currently does not copy this structure; it calls the
 *	structure's retain callback (if there is one), and relies on you not to
 *	release the CF objects in the structure.
 *
 *If any of the required members of the structure are not present (that is, the
 *	size member is too short or the required members are NULL), this function
 *	will fail and return false. Otherwise, it will return true.
 */
Boolean Growl_SetDelegate(struct GrowlDelegate *newDelegate);

/*Growl_GetDelegate
 *
 *Returns the last pointer passed into Growl_SetDelegate (or NULL if no such
 *	call has been made).
 *
 *This function follows standard Core Foundation reference-counting rules.
 *Because it is a Get function, not a Copy function, it will not retain the
 *	delegate on your behalf. You are responsible for retaining and releasing
 *	the delegate as needed.
 */
void Growl_GetDelegate(void);

/*Growl_PostNotification
 *
 *This is the preferred means for sending a Growl notification. The notification
 *	name and at least one of the title and description are required (all three
 *	are preferred). All other parameters may be NULL (or 0 or false as
 *	appropriate) to accept default values.
 *
 *If using the Growl-WithInstaller framework, if Growl is not installed the user
 *	will be prompted to install Growl. 
 *If the user cancels, this method will have no effect until the next
 *	application session, at which time when it is called the user will be
 *	prompted again. The user is also given the option to not be prompted again.
 *If the user does choose to install Growl, the requested notification will be
 *	displayed once Growl is installed and running.
 */
void Growl_PostNotification(const struct GrowlNotification *notification);

/*Growl_NotifyWithTitleDescriptionNameIconPriorityStickyClickContext
 *
 *Creates a temporary GrowlNotification, fills it out with the supplied
 *	information, and calls Growl_PostNotification on it.
 *See struct GrowlNotification and Growl_PostNotification for more information.
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

/*Growl_Reregister
 *
 *This method does not normally need to be called.  If your application changes
 *	what notifications it is registering with Growl (in the
 *	registrationDictionary member of the GrowlDelegate structure), call this
 *	method to have the Growl registration information updated.
 */
void Growl_Reregister(void);

/*Growl_IsInstalled
 *
 *Determines whether the Growl prefpane and its helper app are installed.
 *Returns true if Growl is installed, false otherwise.
 */
Boolean Growl_IsInstalled(void);

/*Growl_IsRunning
 *
 *Cycles through the process list to find whether GrowlHelperApp is running.
 *Returns true if Growl is running, false otherwise.
 */
Boolean Growl_IsRunning(void);

#pragma mark -
#pragma mark Deprecated API

typedef void (*GrowlLaunchCallback)(void *context);

/*Growl_LaunchIfInstalled
 *
 *Returns TRUE if the Growl helper app began launching or was already running.
 *Returns FALSE and performs no other action if the Growl prefPane is not
 *	properly installed.
 *callback will be called when Growl is ready for use (this will only occur when
 *	LaunchGrowlIfInstalled returns TRUE).
 *If a delegate has been set with Growl_SetDelegate, and if the delegate has a
 *	registration dictionary (see struct GrowlDelegate above), this function will
 *	register with Growl atomically.
 *Note: callback should take a single argument; this is to allow applications to
 *	have context-relevant information passed back. It is perfectly acceptable
 *	for context to be NULL.
 *Note: callback can be NULL.
 */
Boolean Growl_LaunchIfInstalled(GrowlLaunchCallback callback, void *context);

/*LaunchGrowlIfInstalled
 *
 *Older name for Growl_LaunchIfInstalled.
 */
Boolean LaunchGrowlIfInstalled(GrowlLaunchCallback callback, void *context);

#pragma mark -
#pragma mark Constants

#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	CFSTR("com.growl.prefpanel")
