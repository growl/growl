//
//  GrowlBrushedWindowView.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrowlBrushedWindowView : NSView {
	NSImage				*icon;
	NSString			*title;
	NSString			*text;
	float				textHeight;
	float				titleHeight;
	SEL					action;
	id					target;

	NSFont				*titleFont;
	NSFont				*textFont;
	NSLayoutManager		*layoutManager;
	NSShadow			*textShadow;
	NSTextStorage		*textStorage;
	NSTextContainer		*textContainer;
	
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
