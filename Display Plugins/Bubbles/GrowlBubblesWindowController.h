//
//  GrowlBubblesWindowController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import <AppKit/NSWindowController.h>

@class NSTimer;

@interface GrowlBubblesWindowController : NSWindowController {
	id				_delegate;
	NSTimer			*_animationTimer;
	unsigned int	_depth;
	BOOL			_autoFadeOut;
	SEL				_action;
	id				_target;
	id				_representedObject;
	short			_displayTime;
}

+ (GrowlBubblesWindowController *) bubble;
+ (GrowlBubblesWindowController *) bubbleWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky;

- (void) startFadeIn;
- (void) startFadeOut;

- (BOOL) automaticallyFadesOut;
- (void) setAutomaticallyFadesOut:(BOOL) autoFade;

- (id) target;
- (void) setTarget:(id) object;

- (SEL) action;
- (void) setAction:(SEL) selector;

- (id) representedObject;
- (void) setRepresentedObject:(id) object;

- (id) delegate;
- (void) setDelegate:(id) delegate;
@end

@interface NSObject (GrowlBubblesWindowControllerDelegate)
- (void) bubbleWillFadeIn:(GrowlBubblesWindowController *) bubble;
- (void) bubbleDidFadeIn:(GrowlBubblesWindowController *) bubble;

- (void) bubbleWillFadeOut:(GrowlBubblesWindowController *) bubble;
- (void) bubbleDidFadeOut:(GrowlBubblesWindowController *) bubble;
@end

