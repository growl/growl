//
//  GrowlBrushedWindowController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlBrushedWindowController : FadingWindowController {
	unsigned	depth;
	SEL			action;
	id			target;
	unsigned	identifier;
	id			plugin; // the GrowlBrushedDisplay object which created us
}

+ (GrowlBrushedWindowController *) notify;
+ (GrowlBrushedWindowController *) notifyWithTitle:(NSString *) title text:(id) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky depth:(unsigned) depth;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int) priority sticky:(BOOL) sticky depth:(unsigned)depth;

- (id) target;
- (void) setTarget:(id) object;

- (SEL) action;
- (void) setAction:(SEL) selector;

- (unsigned) depth;
@end
