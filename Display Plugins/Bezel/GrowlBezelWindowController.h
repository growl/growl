//
//  GrowlBezelWindowController.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrowlBezelWindowController : NSWindowController {
	id				_delegate;
	NSTimer			*_animationTimer;
	BOOL			_autoFadeOut;
	SEL				_action;
	id				_target;
	id				_representedObject;
	short			_displayTime;
}

+ (GrowlBezelWindowController *)bezel;
+ (GrowlBezelWindowController *)bezelWithTitle:(NSString *)title text:(id)text icon:(NSImage *)icon sticky:(BOOL)sticky;

- (id)initWithTitle:(NSString *)title text:(id)text icon:(NSImage *)icon sticky:(BOOL)sticky;

- (void)startFadeIn;
- (void)startFadeOut;

- (BOOL)automaticallyFadeOut;
- (void)setAutomaticallyFadesOut:(BOOL) autoFade;

- (id)target;
- (void)setTarget:(id)object;

- (SEL)action;
- (void)setAction:(SEL)selector;

- (id)representedObject;
- (void)setRepresentedObject:(id)object;

- (id)delegate;
- (void)setDelegate:(id)delegate;

@end

@interface NSObject (GrowlBezelWindowControllerDelegate)
- (void)bezelWillFadeIn:(GrowlBezelWindowController *)bezel;
- (void)bezelDidFadeIn:(GrowlBezelWindowController *)bezel;

- (void)bezelWillFadeOut:(GrowlBezelWindowController *)bezel;
- (void)bezelDidFadeOut:(GrowlBezelWindowController *)bezel;
@end