//
//  GrowlMusicVideoWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlMusicVideoWindowController : FadingWindowController {
	SEL				action;
	id				target;
	float			topLeftPosition;
	float			frameHeight;
	int				priority;
	NSString		*appName;
	id				clickContext;
}

+ (GrowlMusicVideoWindowController *) musicVideo;
+ (GrowlMusicVideoWindowController *) musicVideoWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky;

- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

- (NSString *) appName;
- (void) setAppName:(NSString *) inAppName;

- (id) clickContext;
- (void) setClickContext:(id) clickContext;

- (int) priority;
- (void) setPriority:(int)newPriority;
@end
