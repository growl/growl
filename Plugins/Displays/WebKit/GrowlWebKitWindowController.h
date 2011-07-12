//
//  GrowlWebKitWindowController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlDisplayWindowController.h"

@class WebView, GrowlNotification, GrowlNotificationDisplayBridge;

@interface GrowlWebKitWindowController : GrowlDisplayWindowController {
	NSString		*templateHTML;
	NSURL			*baseURL;

	BOOL			positioned;
	CGFloat			paddingX;
	CGFloat			paddingY;
}

- (id) initWithBridge:(GrowlNotificationDisplayBridge *)displayBridge;

@end
