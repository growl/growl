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
	double			_displayTime;
	unsigned int	_id;
	id				_plugin; // the GrowlSmokeDisplay object which created us
}

+ (GrowlSmokeWindowController *) notify;
+ (GrowlSmokeWindowController *) notifyWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky depth:(unsigned int) depth;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon priority:(int) priority sticky:(BOOL) sticky depth:(unsigned int)depth;

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

- (unsigned int) depth;
@end

@interface NSObject (GrowlSmokeWindowControllerDelegate)
- (void) notificationWillFadeIn:(GrowlSmokeWindowController *) notification;
- (void) notificationDidFadeIn:(GrowlSmokeWindowController *) notification;

- (void) notificationWillFadeOut:(GrowlSmokeWindowController *) notification;
- (void) notificationDidFadeOut:(GrowlSmokeWindowController *) notification;

@end
