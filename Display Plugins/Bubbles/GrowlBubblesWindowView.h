//
//  GrowlBubblesWindowView.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowView.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import <AppKit/NSView.h>

// to get the limit pref
#import "GrowlBubblesPrefsController.h"

@interface GrowlBubblesWindowView : NSView {
	NSImage		*icon;
	NSString	*title;
	NSString	*text;
	float		textHeight;
	float		titleHeight;
	SEL			action;
	id			target;
    NSColor		*bgColor;
    NSColor		*textColor;
	NSColor		*borderColor;
}

- (void) setPriority:(int)priority;
- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;

- (void) sizeToFit;
- (float) titleHeight;
- (float) descriptionHeight;
- (int) descriptionRowCount;
	
- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;
@end

