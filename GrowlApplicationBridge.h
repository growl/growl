//
//  GrowlApplicationBridge.h
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

/*!
    @header
    @abstract   Defines the GrowlApplicationBridge class
    @discussion This header defines the GrowlApplicationBridge class as well as
	the GROWL_PREFPANE_BUNDLE_IDENTIFIER constant.
 */

#import <Foundation/Foundation.h>
#import "GrowlDefines.h"

//Forward declarations
@protocol GrowlApplicationBridgeDelegate;

/*!
    @defined    GROWL_PREFPANE_BUNDLE_IDENTIFIER
    @discussion The bundle identifier for the Growl prefpane
 */
#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	@"com.growl.prefpanel"

/*!
	@defined    GROWL_PREFPANE_NAME
	@discussion The file name of the Growl prefpane
 */
#define GROWL_PREFPANE_NAME					@"Growl.prefPane"

//Internal notification when the user chooses not to install (to avoid continuing to cache notifications awaiting installation)
#define GROWL_USER_CHOSE_NOT_TO_INSTALL_NOTIFICATION @"User chose not to install"

//------------------------------------------------------------------------------
#pragma mark -

/*!
	@class      GrowlApplicationBridge
	@abstract   A class used to interface with Growl
	@discussion This class provides a means to interface with Growl.
	
	Currently it provides a way to detect if Growl is installed and launch the GrowlHelperApp
	if it's not already running.
 */
@interface GrowlApplicationBridge : NSObject {

}

/*!
	@method isGrowlInstalled
	@abstract Detects whether Growl is installed
	@discussion Determines if the Growl prefpane and its helper app are installed.
	@result Returns YES if Growl is installed, NO otherwise.
 */
+ (BOOL) isGrowlInstalled;

/*!
	@method isGrowlRunning
	@abstract Detects whether GrowlHelperApp is currently running
	@discussion Cycles through the process list to find whether GrowlHelperApp is running and returns its findings.
	@result Returns YES if GrowlHelperApp is running, NO otherwise.
*/
+ (BOOL) isGrowlRunning;

/*
	@method setGrowlDelegate:
	@abstract Set the object which will be responsible for providing and receiving Growl information.
	@discussion This must be called before using GrowlApplicationBridge.  
 
	The methods in the GrowlApplicationBridgeDelegate protocol are required and return the basic information
	needed to register with Growl.
 
	The methods in the GrowlApplicationBridgeDelegate_InformalProtocol informal protocol are individually optional.  They provide
	a greater degree of interaction between the application and growl such as informing the application when one of its
	Growl notifications is clicked by the user.
 
	The methods in the GrowlApplicationBridgeDelegate_Installation_InformalProtocol informal protocol are individually optional
	and are only applicable when using the Growl-WithInstaller.framework which allows for automated Growl installation.
 
	When this method is called, data will be collected from inDelegate, Growl will be launched if it is not already running,
	and the application will be registered with Growl.
 
	If using the Growl-WithInstaller framework, if Growl is already installed but this copy of the framework has an updated
	version of Growl, the user will be prompted to update automatically.
 
	@param inDelegate The delegate for the GrowlApplicationBridge. It must conform to the GrowlApplicationBridgeDelegate protocol.
 */
+ (void) setGrowlDelegate:(NSObject<GrowlApplicationBridgeDelegate> *)inDelegate;

/*
	@method growlDelegate
	@abstract Return the object responsible for providing and receiving Growl information.
	@discussion See setGrowlDelegate: for details
	@result The growl delegate
 */
+ (NSObject<GrowlApplicationBridgeDelegate> *) growlDelegate;

/*
	@method notifyWithTitle:description:notificationName:iconData:priority:isSticky:clickContext:
	@abstract Send a Growl notification
	@discussion This is the preferred means for sending a Growl notification.  The notification name and at least one of
	the title and description are required (all three are preferred).  All other parameters may be nil (or 0 or NO as appropriate)
	to accept default values.
 
	If using the Growl-WithInstaller framework, if Growl is not installed the user will be prompted to install Growl. 
	If the user cancels, this method will have no effect until the next application session, at which time when it is 
	called the user will be prompted again. The user is also given the option to not be prompted again.  If the user does
	choose to install Growl, the requested notification will be displayed once Growl is installed and running.
 
	@param title		The title of the notification displayed to the user.
	@param description	The full description of the notification displayed to the user.
	@param notifName	The internal name of the notification. Should be human-readable, as it will be displayed in the Growl preference pane.
	@param iconData		NSData object to show with the notification as its icon. If nil, the application's icon will be used instead.
	@param priority		The priority of the notification. The default value is 0; positive values are higher priority and negative values are lower priority. Not all Growl displays support priority.
	@param isSticky		If YES, the notification will remain on screen until clicked. Not all Growl displays support sticky notifications.
	@param clickContext	A context passed back to the growlAppDelegate if it implements -(void)growlNotificationWasClicked: and the notification is clicked. Not all display plugins support clicking. The clickContext must be plist-encodable (completely of NSString, NSArray, NSNumber, NSDictionary, and NSData types).
 */
+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData 
				priority:(signed int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext;

/*
	@method reregisterGrowlNotifications
	@abstract Reregister the notifications for this application
	@description This method does not normally need to be called.  If your application changes what notifications
	it is registering with Growl, call this method to have the growlDelegate's growlRegistrationDict method called
	again and the Growl registration information updated.
 */
+ (void) reregisterGrowlNotifications;

#pragma mark -
/*
	@protocol GrowlApplicationBridgeDelegate
	@abstract Required protocol for the GrowlApplicationBridge delegate
	@discussion The methods in this protocol are required and are called automatically as needed by GrowlApplicationBridge
 */
//------------------------------------------------------------------------------
@protocol GrowlApplicationBridgeDelegate

/*
	@method applicationNameForGrowl
	@abstract Return the name of this application which will be used for Growl bookkeeping.
	@discussion This name is used both internally and in the Growl preferences.
	@result The name of the application using Growl
 */
- (NSString *) applicationNameForGrowl;

/*
	@method growlRegistrationDictionary
	@abstract Return the dictionary used to register this applicaiton with Growl
	@discussion The returned dictionary gives Growl the complete list of notifications this application will ever send,
	and it also specifies which applications should be enabled by default.  Each is specified by an array of NSString objects.
	For most applications, these two arrays can be the same (if all sent notifications should be displayed by default).
 
	The NSString objects of these arrays will corresopnd to the notificationName: parameter passed in notifyWithTarget::::::: calls.
 
	The dictionary should have 2 key object pairs:
	key: GROWL_NOTIFICATIONS_ALL		object: NSArray of NSString objects
	key: GROWL_NOTIFICATIONS_DEFAULT	object: NSArray of NSString objects
 
	@result The NSDictionary to use for registration.
*/ 
- (NSDictionary *) growlRegistrationDictionary;

@end

#pragma mark -
/*
	@category NSObject(GrowlApplicationBridgeDelegate_InformalProtocol)
	@abstract Methods which may be optionally implemented by the GrowlApplicationBridgeDelegate
	@discusison The methods in this informal protocol will only be called if implemented by the delegate.
 */
@interface NSObject (GrowlApplicationBridgeDelegate_InformalProtocol)
/* 
	@method applicationIconData
	@abstract Return the NSData to treat as the application icon
	@discussion The delegate may optionally return an NSData object to use as the application icon;
	if this is not implemented, the application's own icon is used.  This is not generally needed.
	@result The NSData to treat as the application icon
 */
- (NSData *) applicationIconData;

/*
	@method growlIsReady
	@abstract Informs the delegate that Growl has launched
	@discussion Informs the delegate that Growl (specifically, the GrowlHelperApp) was launched successfully 
	(or was already running). The application can take actions with the knowlege that Growl is installed and functional.
 */
- (void) growlIsReady;

/*
	@method growlNotificationWasClicked:
	@abstract Informs the delegate that a Growl notification was clicked
	@discussion Informs the delegate that a Growl notification was clicked.  It is only sent for notifications sent with
	a non-nil clickContext, so if you want to receive a message when a notification is clicked, clickContext must not be nil when
	calling notifyWithTarget:::::::.
	@param clickContext The clickContext passed when displaying the notification originally via notifyWithTarget:::::::.
 */
- (void) growlNotificationWasClicked:(id)clickContext;

@end

#pragma mark -
/*
	@category NSObject(GrowlApplicationBridgeDelegate_Installation_InformalProtocol)
	@abstract Methods which may be optionally implemented by the GrowlApplicationBridgeDelegate when used with Growl-WithInstaller.framework
	@discusison The methods in this informal protocol will only be called if implemented by the delegatte. 
	They allow greater control of the information presented to the user when installing or upgrading Growl from within
	your application when using Growl-WithInstaller.framework.
 */
@interface NSObject (GrowlApplicationBridgeDelegate_Installation_InformalProtocol)

/*
	@method growlInstallationWindowTitle
	@abstract Return the title of the installation window
	@discussion If not implemented, Growl will use a default, localized title
	@result An NSString object to use as the title
 */
- (NSString *)growlInstallationWindowTitle;

/*
	@method growlUpdateWindowTitle
	@abstract Return the title of the upgrade window
	@discussion If not implemented, Growl will use a default, localized title
	@result An NSString object to use as the title
*/
- (NSString *)growlUpdateWindowTitle;

/*
	@method growlInstallationInformation
	@abstract Return the information to display when installing
	@discussion This information may be as long or short as desired (the window will be sized to fit it).  It will
	be displayed to the user as an explanation of what Growl is and what it can do in your application.  It should
	probably note that no download is required to install.
 
	If this is not implemented, Growl will use a default, localized explanation.

	@result An NSAttributedString object to display.
 */
- (NSAttributedString *)growlInstallationInformation;
	
/*
	@method growlUpdateInformation
	@abstract Return the information to display when upgrading
	@discussion This information may be as long or short as desired (the window will be sized to fit it).  It will
	be displayed to the user as an explanation that an updated version of Growl is included in your application and
	no download is required.
	 
	If this is not implemented, Growl will use a default, localized explanation.
	 
	@result An NSAttributedString object to display.
*/
- (NSAttributedString *)growlUpdateInformation;

@end

//private
@interface GrowlApplicationBridge (GrowlInstallationPrompt_private)
+ (void) _userChoseNotToInstallGrowl;
@end

