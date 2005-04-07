//
//  GrowlSmokeWindowView.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrowlSmokeWindowView : NSView {
	BOOL				mouseOver;
	BOOL				haveTitle;
	BOOL				haveText;
	NSImage				*icon;
	float				textHeight;
	float				titleHeight;
	float				lineHeight;
	SEL					action;
	id					target;
	NSTrackingRectTag	trackingRectTag;

	NSFont				*textFont;
	NSShadow			*textShadow;

	NSLayoutManager		*textLayoutManager;
	NSTextStorage		*textStorage;
	NSTextContainer		*textContainer;
	NSRange				textRange;

	NSTextStorage		*titleStorage;
	NSTextContainer		*titleContainer;
	NSLayoutManager		*titleLayoutManager;
	NSRange				titleRange;

	NSColor				*bgColor;
	NSColor				*textColor;
}

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;

- (void) setPriority:(int)priority;

- (void) sizeToFit;
- (float) titleHeight;
- (float) descriptionHeight;
- (int) descriptionRowCount;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

@end
