//
//  GrowlAppBridge.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-01-29.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>
#import <Growl/GrowlApplicationBridge-Carbon.h>

/*!	@class	GrowlAppBridge
 *	@superclass	GrowlApplicationBridge
 *	@abstract	Compatibility subclass.
 *	@deprecated	in version 0.6
 *	@discussion	In Growl 0.5, the Growl framework was named GrowlAppBridge.
 *	 framework, and its principal class was GrowlAppBridge. In 0.6, the
 *	 framework became Growl.framework, and its principal class was expanded
 *	 and was renamed to GrowlApplicationBridge. This subclass exists for
 *	 compatibility with the old framework: it inherits from the new
 *	 GrowlApplicationBridge class, and issues a warning using NSLog when it is
 *	 initialized (see +[NSObject initialize]).
 *
 *	 You should use GrowlApplicationBridge instead for all further Growl
 *	 development. If you absolutely must support GrowlAppBridge, you can use
 *	 NSClassFromString to try to get GrowlApplicationBridge, and if it does not
 *	 exist, disable 0.6- specific functionality and use NSClassFromString again
 *	 to get the GrowlAppBridge class.
 */

@class GrowlApplicationBridge;

@interface GrowlAppBridge: GrowlApplicationBridge
{

}

@end
