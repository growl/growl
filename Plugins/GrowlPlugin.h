//
//  GrowlPlugin.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-01.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*!	@class	GrowlPlugin
 *	@abstract	The base plug-in protocol.
 *	@discussion	The methods declared in this protocol are supported by all
 *	 Growl plug-ins.
 */
@interface GrowlPlugin : NSObject {
	NSPreferencePane *preferencePane;
}

/*!	@method	preferencePane
 *	@abstract	Return an <code>NSPreferencePane</code> instance that manages
 *	 the plugin's preferences.
 *	@discussion	Your plug-in should put the controls for its preferences in
 *	 this preference pane.
 *
 *	 Currently, the size of the preference pane's view should be 354 pixels by
 *	 289 pixels, but you should set the springs of the view and its subviews
 *	 under the assumption that it can be resized horizontally and vertically to
 *	 any size.
 *	@result	The preference pane. Can be <code>nil</code>.
 */
- (NSPreferencePane *) preferencePane;

@end
