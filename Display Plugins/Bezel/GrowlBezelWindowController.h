//
//  GrowlBezelWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlBezelWindowController : FadingWindowController {
	int				priority;
	double			scaleFactor;
	BOOL			flipIn;
	BOOL			flipOut;
}

+ (GrowlBezelWindowController *) bezel;
+ (GrowlBezelWindowController *) bezelWithTitle:(NSString *)title text:(NSString *)text
		icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky;

- (id) initWithTitle:(NSString *)title text:(NSString *)text icon:(NSImage *)icon priority:(int)priority sticky:(BOOL)sticky;

- (int) priority;
- (void) setPriority:(int)newPriority;

- (void) _fadeIn:(NSTimer *)timer;
- (void) _fadeOut:(NSTimer *)timer;

- (void) setFlipIn:(BOOL)flag;
- (void) setFlipOut:(BOOL)flag;

@end
