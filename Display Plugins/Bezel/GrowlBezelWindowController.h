//
//  GrowlBezelWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlBezelWindowController : FadingWindowController {
	SEL				action;
	id				target;
	int				priority;
	NSString		*appName;
	id				clickContext;
}

+ (GrowlBezelWindowController *) bezel;
+ (GrowlBezelWindowController *) bezelWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky;

- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

- (int) priority;
- (void) setPriority:(int)newPriority;

- (NSString *) appName;
- (void) setAppName:(NSString *) inAppName;

- (id) clickContext;
- (void) setClickContext:(id) clickContext;

@end
