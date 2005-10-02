//
//  GrowlSmokeWindowView.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlNotificationView.h"

@interface GrowlSmokeWindowView : GrowlNotificationView {
	BOOL				mouseOver;
	BOOL				haveTitle;
	BOOL				haveText;
	BOOL				closeOnMouseExit;
	NSImage				*icon;
	float				iconSize;
	float				textHeight;
	float				titleHeight;
	float				lineHeight;
	SEL					action;
	id					target;
	NSTrackingRectTag	trackingRectTag;
	NSProgressIndicator	*progressIndicator;

	NSFont				*textFont;
	NSShadow			*textShadow;
	NSColor				*textColor;
	NSColor				*bgColor;

	NSLayoutManager		*textLayoutManager;
	NSTextStorage		*textStorage;
	NSTextContainer		*textContainer;
	NSRange				textRange;

	NSTextStorage		*titleStorage;
	NSTextContainer		*titleContainer;
	NSLayoutManager		*titleLayoutManager;
	NSRange				titleRange;
}

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title isHTML:(BOOL)isHTML;
- (void) setText:(NSString *)text isHTML:(BOOL)isHTML;

- (void) setPriority:(int)priority;
- (void) setProgress:(NSNumber *)value;

- (void) sizeToFit;
- (float) titleHeight;
- (float) descriptionHeight;
- (int) descriptionRowCount;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

- (BOOL) mouseOver;
- (void) setCloseOnMouseExit:(BOOL)flag;
@end
