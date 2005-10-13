//
//	GrowlDisplayPlugin.h
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-06-01.
//	Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlPlugin.h"

@class GrowlApplicationNotification, GrowlNotificationDisplayBridge;

/*!
 * @class GrowlDisplayPlugin
 * @abstract Base class for all display plugins.
 */
@interface GrowlDisplayPlugin : GrowlPlugin {
	//for non-queueing displays
	NSMutableArray *activeBridges; //GrowlNotificationDisplayBridges currently being displayed

	//for queueing displays
	GrowlNotificationDisplayBridge *bridge;
	NSMutableArray *queue;           //GrowlNotificationDisplayBridges yet to be displayed
}

/*!	@method	displayNotification:
 *	@abstract	Display a notification to the user.
 *	@param	notification	The notification to display.
 *	@discussion	This is where the magic happens. Whatever your display does to
 *	 get a notification to the user, it does it here.
 *
 *	 Your implementation of this method should call up to <code>super</code> at
 *	 the beginning of the method.
 */
- (void) displayNotification:(GrowlApplicationNotification *)notification;

/*!	@method	windowNibName
 *	@abstract	Returns the name of the display's sole nib file (resulting in
 *	 the creation of a window controller for the window in that file).
 *	@discussion	When subclassing <code>GrowlDisplayPlugin</code>, override this
 *	 method and return the name of the nib (without the ".nib" extension) that
 *	 contains the display window. This method is called by
 *	 <code>displayNotification:</code> to create a
 *	 <code>GrowlNotificationDisplayBridge</code>, which is the File's Owner for
 *	 the nib.
 *
 *	 The default implementation returns the value of
 *	 <code>GrowlDisplayWindowNibName</code> in the Info.plist of the bundle for
 *	 the display plug-in.
 *	@result	The name of the window nib.
 */
- (NSString *) windowNibName;

@end
