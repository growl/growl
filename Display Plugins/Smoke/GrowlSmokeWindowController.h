//
//  GrowlSmokeWindowController.h
//  Display Plugins
//
//  Created by Matthew Walton on 11/09/2004.
//  Copyright 2004 The Growl Project. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlSmokeWindowController : FadingWindowController {
	unsigned	depth;
	unsigned	identifier;
	id			plugin; // the GrowlSmokeDisplay object which created us
}

+ (GrowlSmokeWindowController *) notifyWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky depth:(unsigned) depth;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int) priority sticky:(BOOL) sticky depth:(unsigned)depth;

- (unsigned) depth;
@end
