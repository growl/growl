//
//  GrowlSmokeWindowView.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlSmokeWindowView : NSView {
	NSImage				*_icon;
	NSString			*_title;
	NSString			*_text;
	float				_textHeight;
	SEL					_action;
	id					_target;

    NSColor             *_bgColor;
}

- (void)setIcon:(NSImage *)icon;
- (void)setTitle:(NSString *)title;
- (void)setText:(NSString *)text;

- (void)setPriority:(int)priority;

- (void)sizeToFit;
- (int)textAreaWidth;
- (float)titleHeight;
- (float)descriptionHeight;
- (int)descriptionRowCount;

- (id)target;
- (void)setTarget:(id)object;

- (SEL)action;
- (void)setAction:(SEL)selector;

@end
