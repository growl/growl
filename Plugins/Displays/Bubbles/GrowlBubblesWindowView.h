//
//  GrowlBubblesWindowView.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowView.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004–2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlNotificationView.h"

@interface GrowlBubblesWindowView : GrowlNotificationView {
	BOOL				haveText;
	BOOL				haveTitle;
	NSFont				*titleFont;
	NSFont				*textFont;
	NSImage				*icon;
	CGFloat				iconSize;
	CGFloat				textHeight;
	CGFloat				titleHeight;
	CGFloat				lineHeight;
	NSColor				*textColor;
	NSColor				*bgColor;
	NSColor				*lightColor;
	NSColor				*borderColor;
	NSColor				*highlightColor;

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
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;

- (void) sizeToFit;
- (CGFloat) titleHeight;
- (CGFloat) descriptionHeight;
- (NSInteger) descriptionRowCount;

@property (nonatomic, retain) NSColor				*textColor;
@property (nonatomic, retain) NSColor				*bgColor;
@property (nonatomic, retain) NSColor				*lightColor;

@end

