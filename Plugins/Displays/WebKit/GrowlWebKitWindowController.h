//
//  GrowlWebKitWindowController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@class WebView, GrowlApplicationNotification, GrowlNotificationDisplayBridge;

@interface GrowlWebKitWindowController : GrowlDisplayWindowController {
	NSString                        *templateHTML;
	CFURLRef                        baseURL;

	unsigned	                    depth;
	NSImage		                    *image;
	BOOL		                    positioned;		// This should live in the super class
	float		                    paddingX;
	float		                    paddingY;
}

- (id) initWithBridge:(GrowlNotificationDisplayBridge *)displayBridge;

@end
