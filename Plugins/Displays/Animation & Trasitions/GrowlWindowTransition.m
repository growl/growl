//
//  GrowlWindowTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 27/07/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlWindowTransition.h"


@implementation GrowlWindowTransition

- (id) init {
	self = [super init];
	
	if (self) {
		window = nil;
	}
	
	return self;
}

- (id) initWithWindow:(NSWindow *)inWindow {
	self = [self init];	//Init with GrowlAnimation's default values
	
	if (self) {
		[self setWindow:inWindow];
	}
	
	return self;
}

- (NSWindow *) window {
	return window;
}

- (void) setWindow:(NSWindow *)inWindow {
	[window release];
	window = [inWindow retain];
}

- (void) dealloc {
	[window release];
	[super dealloc];
}


@end
