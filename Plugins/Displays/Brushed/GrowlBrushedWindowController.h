//
//  GrowlBrushedWindowController.h
//  Display Plugins
//
//  Created by Ingmar Stein on 12/01/2004.
//  Copyright 2004-2005 The Growl Project. All rights reserved.
//

#import "GrowlDisplayFadingWindowController.h"

@interface GrowlBrushedWindowController : GrowlDisplayFadingWindowController {
	unsigned	depth;
	NSString	*identifier;
	unsigned	uid;
	id			plugin; // the GrowlBrushedDisplay object which created us
}

- (id) initWithDictionary:(NSDictionary *)noteDict depth:(unsigned)depth;
- (unsigned) depth;
@end
