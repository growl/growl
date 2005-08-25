//
//  GrowlMusicVideoWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"

@class GrowlMusicVideoWindowView;

@interface GrowlMusicVideoWindowController : GrowlDisplayFadingWindowController {
	float						frameHeight;
	float						frameY;
	int							priority;
	GrowlMusicVideoWindowView	*subview;
	NSString					*identifier;
}

- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority identifier:(NSString *)ident;

- (NSString *) identifier;
- (int) priority;
- (void) setPriority:(int)newPriority;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;
- (void) setIcon:(NSImage *)icon;

@end
