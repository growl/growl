//
//  GrowlAppBridge.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-01-29.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#include <Growl/GrowlAppBridge-Carbon.h>

#if __OBJC__

#import <Cocoa/Cocoa.h>
#import <Growl/GrowlApplicationBridge.h>

/*!	@header	GrowlAppBridge.h
 *	@abstract	Compatibility header for Growl.framework; master header for
 *	 GrowlAppBridge.framework.
 *	@deprecated	in Growl 0.6.
 *	@discussion	Applications expecting GrowlAppBridge.framework from Growl 0.5
 *	 will include <GrowlAppBridge/GrowlAppBridge.h>, thereby getting this
 *	 header. (Yes, this header is part of Growl.framework, but in Growl 0.6,
 *	 Growl.framework is installed under the old name to preserve this
 *	 compatibility. Growl.framework is not installed under the new name; it is
 *	 designed to be bundled into applications.)
 *	 
 *	 This header defines the GrowlAppBridge class (implemented now as a
 *	 subclass of GrowlApplicationBridge that still has all the old behavior,
 *	 but logs a message when its first method is called), and also imports the
 *	 GrowlApplicationBridge-Carbon.h header for Carbon applications.
 */

/*!	@class	GrowlAppBridge
 *	@superclass	GrowlApplicationBridge
 *	@abstract	Compatibility subclass.
 *	@deprecated	in Growl 0.6.
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

@interface GrowlAppBridge: GrowlApplicationBridge
{

}

@end

#endif //__OBJC__
