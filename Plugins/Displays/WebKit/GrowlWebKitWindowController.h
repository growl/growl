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
	NSString		*templateHTML;
	NSURL			*baseURL;

	NSImage			*image;
	BOOL			positioned;
	float			paddingX;
	float			paddingY;
}

- (id) initWithBridge:(GrowlNotificationDisplayBridge *)displayBridge;

@end
