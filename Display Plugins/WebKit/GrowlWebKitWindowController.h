//
//  GrowlWebKitWindowController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "FadingWindowController.h"

@class WebView;

@interface GrowlWebKitWindowController : FadingWindowController {
	unsigned	depth;
	NSString	*identifier;
	NSImage		*image;
	BOOL		positioned;
}

+ (GrowlWebKitWindowController *) notifyWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL)sticky identifier:(NSString *)ident;
- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL)sticky identifier:(NSString *)ident;
- (void) setTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority forView:(WebView *)view;

@end
