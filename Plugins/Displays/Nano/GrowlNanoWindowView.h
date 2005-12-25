//
//  GrowlNanoWindowView.h
//  Display Plugins
//
//  Created by Rudy Richter on 12/12/2005.
//  Copyright 2005, The Growl Project. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "GrowlNotificationView.h"

@interface GrowlNanoWindowView : GrowlNotificationView {
	NSImage				*icon;
	NSString			*title;
	NSString			*text;
	NSDictionary		*textAttributes;
	NSDictionary		*titleAttributes;
	NSColor				*textColor;
	NSColor				*backgroundColor;

	CGLayerRef			layer;
	NSImage				*cache;
	BOOL				needsDisplay;
}

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;
- (void) setPriority:(int)priority;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

@end
