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
	@discussion Determies if the Growl prefpane and its helper app are installed
	@result Returns YES if Growl is installed, NO otherwise
 */
+ (BOOL) isGrowlInstalled;

/*!
	@method isGrowlRunning
	@abstract Detects whether GrowlHelperApp is currently running
	@discussion Cycles through the process list to find if GrowlHelperApp is running and returns the status
	@result Returns YES if GrowlHelperApp is running, NO otherwise
*/
+ (BOOL) isGrowlRunning;

/************************
 *setGrowlDelegate: must be called before otherwise using GrowlApplicationBridge.
 *The methods in the GrowlApplicationBridgeDelegate protocol are required;
 * 	other methods defined in the informal protocol are optional.
 ************************
 */
//XXX - Needs documentation
+ (void) setGrowlDelegate:(NSObject<GrowlApplicationBridgeDelegate> *)inDelegate;
+ (NSObject<GrowlApplicationBridgeDelegate> *) growlDelegate;

//XXX - Needs documentation
+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData 
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext;
@end

@interface GrowlApplicationBridge (GrowlInstallationPrompt_private)

+ (void) _userChoseNotToInstallGrowl;

@end

//------------------------------------------------------------------------------
#pragma mark -

//XXX - Needs documentation
@protocol GrowlApplicationBridgeDelegate

//XXX - Needs documentation
- (NSString *) applicationName;

//XXX - Needs documentation
- (NSDictionary *) growlRegistrationDictionary;

@end

//------------------------------------------------------------------------------
#pragma mark -

//XXX - Needs documentation
@interface NSObject (GrowlApplicationBridgeDelegate_InformalProtocol)

/*The delegate may optionally return an NSData object to use as the application
 *	icon; if this is not implemented, the application's own icon is used.
 */
//XXX - Needs documentation
- (NSData *) applicationIconData;

//called when GrowlHelperApp launches.
//XXX - Needs documentation
- (void) growlIsReady;

//Informs the delegate that a growl notification with the passed clickContext was clicked
//XXX - Needs documentation
- (void) growlNotificationWasClicked:(id)clickContext;

@end

//XXX - Needs documentation
@interface NSObject (GrowlApplicationBridgeDelegate_Installation_InformalProtocol)

//XXX - Needs documentation
- (NSString *)growlInstallationWindowTitle;

//XXX - Needs documentation
- (NSString *)growlUpdateWindowTitle;

//XXX - Needs documentation
- (NSAttributedString *)growlInstallationInformation;

//XXX - Needs documentation
- (NSAttributedString *)growlUpdateInformation;

@end
