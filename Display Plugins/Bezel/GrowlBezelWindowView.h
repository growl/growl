//
//  GrowlBezelWindowView.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlBezelWindowView : NSView {
	NSImage				*_icon;
	NSString			*_title;
	NSString			*_text;
	float				_textHeight;
	SEL					_action;
	id					_target;
}

- (void)setIcon:(NSImage *)icon;
- (void)setTitle:(NSString *)title;
- (void)setText:(NSString *)text;

- (float)descriptionHeight:(NSAttributedString *)text;
- (int)descriptionRowCount:(NSAttributedString *)text;

- (id)target;
- (void)setTarget:(id)object;

- (SEL)action;
- (void)setAction:(SEL)selector;

@end
