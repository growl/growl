//
//  GrowlBubblesWindowView.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowView.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004-2005 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrowlBubblesWindowView : NSView {
	BOOL				mouseOver;
	BOOL				haveText;
	BOOL				haveTitle;
	BOOL				closeOnMouseExit;
	NSFont				*titleFont;
	NSFont				*textFont;
	NSImage				*icon;
	float				iconSize;
	float				textHeight;
	float				titleHeight;
	float				lineHeight;
	SEL					action;
	id					target;
	NSColor				*textColor;
	NSColor				*bgColor;
	NSColor				*lightColor;
	NSColor				*borderColor;
	NSColor				*highlightColor;
	NSTrackingRectTag	trackingRectTag;

	NSLayoutManager		*textLayoutManager;
	NSTextStorage		*textStorage;
	NSTextContainer		*textContainer;
	NSRange				textRange;

	NSLayoutManager		*titleLayoutManager;
	NSTextStorage		*titleStorage;
	NSTextContainer		*titleContainer;
	NSRange				titleRange;
}

- (void) setPriority:(int)priority;
- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title isHTML:(BOOL)isHTML;
- (void) setText:(NSString *)text isHTML:(BOOL)isHTML;

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

