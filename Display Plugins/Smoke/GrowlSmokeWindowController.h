//
//  GrowlSmokeWindowController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlSmokeWindowController : NSWindowController {
	id				_delegate;
	NSTimer			*_animationTimer;
	unsigned int	_depth;
	BOOL			_autoFadeOut;
	SEL				_action;
	id				_target;
	id				_representedObject;
	short			_displayTime;
}

+ (GrowlSmokeWindowController *) notify;
+ (GrowlSmokeWindowController *) notifyWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon sticky:(BOOL) sticky;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon sticky:(BOOL) sticky;

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

@interface NSObject (GrowlSmokeWindowControllerDelegate)
- (void) notificationWillFadeIn:(GrowlSmokeWindowController *) notification;
- (void) notificationDidFadeIn:(GrowlSmokeWindowController *) notification;

- (void) notificationWillFadeOut:(GrowlSmokeWindowController *) notification;
- (void) notificationDidFadeOut:(GrowlSmokeWindowController *) notification;

@end
