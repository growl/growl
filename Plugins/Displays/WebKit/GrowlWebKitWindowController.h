//
//  GrowlWebKitWindowController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"

@class WebView, GrowlApplicationNotification, GrowlNotificationDisplayBridge;

@interface GrowlWebKitWindowController : GrowlDisplayWindowController {
	NSString                        *templateHTML;
	NSURL                           *baseURL;

	unsigned	                    depth;
	NSImage		                    *image;
	BOOL		                    positioned;		// This should live in the super class
	float		                    paddingX;
	float		                    paddingY;
}

- (id) initWithBridge:(GrowlNotificationDisplayBridge *)displayBridge;

@end
