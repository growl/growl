//
//  GrowlAppBridge.h
//  Growl
//
//  Created by Evan Schoenberg on Wed Jun 16 2004.
//

/*!
    @header
    @abstract   Defines the GrowlApplicationBridge class
    @discussion This header defines the GrowlApplicationBridge class as well as
	the GROWL_PREFPANE_BUNDLE_IDENTIFIER constant.
 */

#import <Foundation/Foundation.h>

//Forward declarations
@protocol GrowlAppBridgeDelegate;

/*!
    @defined    GROWL_PREFPANE_BUNDLE_IDENTIFIER
    @discussion The bundle identifier for the Growl prefpane
 */
#define GROWL_PREFPANE_BUNDLE_IDENTIFIER	@"com.growl.prefpanel"
#define GROWL_PREFPANE_NAME					@"Growl.prefPane"

/*!
	@class      GrowlAppBridge
	@abstract   A class used to interface with Growl
	@discussion This class provides a means to interface with Growl.
	
	Currently it provides a way to detect if Growl is installed and launch the GrowlHelperApp
	if it's not already running.
 */
@interface GrowlAppBridge : NSObject {

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

/* ***********************
* This must be called before using GrowlAppBridge.  The methods in the GrowlAppBridgeDelegate are required;
* other methods defined in the informal protocol are optional.
* ***********************/
//XXX - Needs documentation
+ (void) setGrowlDelegate:(NSObject<GrowlAppBridgeDelegate> *)inDelegate;

//XXX - Needs documentation
+ (void) notifyWithTitle:(NSString *)title
			 description:(NSString *)description
		notificationName:(NSString *)notifName
				iconData:(NSData *)iconData 
				priority:(int)priority
				isSticky:(BOOL)isSticky
			clickContext:(id)clickContext;

@end

//XXX - Needs documentation
@protocol GrowlAppBridgeDelegate
//XXX - Needs documentation
- (NSString *) growlAppName;

//XXX - Needs documentation
- (NSDictionary *) growlRegistrationDict;
@end

//XXX - Needs documentation
@interface NSObject (GrowlAppBridgeDelegate_InformalProtocol)
/* The delegate may optionally return an NSData* object to use as the application icon;
* if this is not implemented, the application's own icon is used */
//XXX - Needs documentation
- (NSData *) growlAppIconData;

//XXX - Needs documentation
- (void)growlIsReady;

//Informs the delegate that a growl notification with the passed clickContext was clicked
//XXX - Needs documentation
- (void) growlNotificationWasClicked:(id)clickContext;
@end

