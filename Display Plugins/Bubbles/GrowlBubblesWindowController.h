//
//  GrowlBubblesWindowController.h
//  Growl
//
//  Created by Nelson Elhage on Wed Jun 09 2004.
//  Name changed from KABubbleWindowController.h by Justin Burns on Fri Nov 05 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "FadingWindowController.h"

@interface GrowlBubblesWindowController : FadingWindowController {
	unsigned	depth;
	SEL			action;
	id			target;
	NSString	*notificationID;
}

+ (GrowlBubblesWindowController *) bubble;
+ (GrowlBubblesWindowController *) bubbleWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky;

#pragma mark Regularly Scheduled Coding

- (id) initWithTitle:(NSString *) title text:(NSString *) text icon:(NSImage *) icon priority:(int)priority sticky:(BOOL) sticky;

- (id) target;
- (void) setTarget:(id) object;

- (SEL) action;
- (void) setAction:(SEL) selector;

- (NSString *) notificationID;
- (void) setNotificationID:(NSString *) notificationID;

@end
