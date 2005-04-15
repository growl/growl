//
//  GrowlWebKitWindowController.h
//  Growl
//
//  Created by Ingmar Stein on Thu Apr 14 2005.
//  Copyright 2005 The Growl Project. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlWebKitWindowController : FadingWindowController {
	unsigned				depth;
}

+ (GrowlWebKitWindowController *) notifyWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky;
- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky;

@end
