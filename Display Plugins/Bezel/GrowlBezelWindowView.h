//
//  GrowlBezelWindowView.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlBezelPrefs.h"

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

- (float)descriptionHeight:(NSAttributedString *)text inRect:(NSRect)theRect;
- (int)descriptionRowCount:(NSAttributedString *)text inRect:(NSRect)theRect;

- (id)target;
- (void)setTarget:(id)object;

- (SEL)action;
- (void)setAction:(SEL)selector;

@end
