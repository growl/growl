//
//  GrowlSmokeWindowController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlSmokeWindowController : FadingWindowController {
	unsigned	_depth;
	SEL			_action;
	id			_target;
	unsigned	_id;
	id			_plugin; // the GrowlSmokeDisplay object which created us
}

+ (GrowlSmokeWindowController *) notify;
+ (GrowlSmokeWindowController *) notifyWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky depth:(unsigned) depth;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int) priority sticky:(BOOL) sticky depth:(unsigned)depth;

- (id) target;
- (void) setTarget:(id) object;

- (SEL) action;
- (void) setAction:(SEL) selector;

- (unsigned) depth;
@end
