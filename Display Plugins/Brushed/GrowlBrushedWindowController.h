//
//  GrowlBrushedWindowController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlBrushedWindowController : FadingWindowController {
	unsigned	depth;
	unsigned	identifier;
	id			plugin; // the GrowlBrushedDisplay object which created us
}

+ (GrowlBrushedWindowController *) notify;
+ (GrowlBrushedWindowController *) notifyWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky depth:(unsigned) depth;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int) priority sticky:(BOOL) sticky depth:(unsigned)depth;

- (unsigned) depth;
@end
