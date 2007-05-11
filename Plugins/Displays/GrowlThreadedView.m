//
//  GrowlThreadedView.m
//  Growl
//
//  Created by Ofri Wolfus on 01/10/05.
//  Copyright 2005-2006 Ofri Wolfus. All rights reserved.
//

#import "GrowlThreadedView.h"
#import "GrowlApplicationController.h"

@interface GrowlThreadedView (PRIVATE)
- (void) threadedDrawRectWithRectValue:(NSValue *)aRect;
@end

@implementation GrowlThreadedView

//init and store the main thread
- (id) initWithFrame:(NSRect)frameRect {
	if ((self = [super initWithFrame:frameRect]))
		mainThread = [[[GrowlApplicationController sharedInstance] mainThread] retain];

	return self;
}

- (void) release {
	//only really release when we have no active threads. it would be Very Bad if we were released while things were happening.
	[NSObject cancelPreviousPerformRequestsWithTarget:self
											 selector:@selector(release)
											   object:nil];
	if (numberOfThreads) {
		NSLog(@"Tying again...");
		[self performSelector:@selector(release)
		           withObject:nil
		           afterDelay:0.1];
	} else {
		[super release];
	}
}
- (void) dealloc {
	[mainThread release];
	[super dealloc];
}

- (BOOL) dispatchDrawingToThread:(NSRect)aRect {
	BOOL isMain = [NSThread currentThread] == mainThread;
	if (isMain) {
		++numberOfThreads;
		[NSApplication detachDrawingThread:@selector(threadedDrawRectWithRectValue:)
								  toTarget:self
								withObject:[NSValue valueWithRect:aRect]];
	}
	return !isMain;
}

//Convert the value back to a rect, then lock focus (ordinarily done for us, but this is no ordinary view!) and draw. And unlock focus, of course.
- (void) threadedDrawRectWithRectValue:(NSValue *)aRect {
	[self lockFocus];
	[self drawRect:[aRect rectValue]];
	[self unlockFocus];
	--numberOfThreads;
}

@end
