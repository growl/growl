//
//  GrowlMusicVideoWindowView.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlMusicVideoPrefs.h"

@interface GrowlMusicVideoWindowView : NSView {
	NSImage				*icon;
	NSString			*title;
	NSString			*text;
	float				textHeight;
	SEL					action;
	id					target;
}

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;

- (float) descriptionHeight:(NSAttributedString *)text inRect:(NSRect)theRect;
- (int) descriptionRowCount:(NSAttributedString *)text inRect:(NSRect)theRect;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

@end
