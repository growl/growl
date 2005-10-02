//
//  GrowlNotificationView.m
//  Growl
//
//  Created by Ofri Wolfus on 01/10/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlNotificationView.h"
#import "GrowlApplicationController.h"


@interface GrowlNotificationView (private)
- (void) drawRectWithRectValue:(NSValue *)aRect;
@end


@implementation GrowlNotificationView

static NSThread *mainThread = nil;

//init and store the main thread
- (id) initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect]))
		mainThread = [[GrowlApplicationController sharedInstance] mainThread];
	
	return self;
}

//All drawings are done in a secondary thread
- (void) drawRect:(NSRect)aRect {
	if ([NSThread currentThread] == mainThread) {
		[NSApplication detachDrawingThread:@selector(drawRect:)
								  toTarget:self
								withObject:[NSValue valueWithRect:aRect]];
		return;
	}
}

//Convert the value back to a rect
- (void) drawRectWithRectValue:(NSValue *)aRect {
	[self lockFocus];
	[self drawRect:[aRect rectValue]];
	[self unlockFocus];
}

@end
