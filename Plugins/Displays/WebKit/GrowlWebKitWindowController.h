//
//  GrowlWebKitWindowController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"

@class WebView;

@interface GrowlWebKitWindowController : GrowlDisplayFadingWindowController {
	unsigned	depth;
	NSString	*identifier;
	NSImage		*image;
	BOOL		positioned;
	NSString    *style;
	NSString	*prefDomain;
	float		paddingX;
	float		paddingY;
}

- (id) initWithDictionary:(NSDictionary *)noteDict style:(NSString *)styleName;
- (void) setTitle:(NSString *)title titleHTML:(BOOL)titleIsHTML text:(NSString *)text textHTML:(BOOL)textIsHTML icon:(NSImage *)icon priority:(int)priority forView:(WebView *)view;

@end
