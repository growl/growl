//
//  GrowlViewTransition.m
//  Growl
//
//  Created by Ofri Wolfus on 01/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "GrowlViewTransition.h"


@implementation GrowlViewTransition

- (id) init {
	self = [super init];
	
	if (self) {
		view = nil;
	}
	
	return self;
}

- (id) initWithView:(NSView *)aView {
	self = [self init];
	
	if (self) {
		[self setView:aView];
	}
	
	return self;
}

- (NSView *) view {
	return view;
}

- (void) setView:(NSView *)aView {
	[view release];
	view = [aView retain];
}

- (void) drawFrame:(GrowlAnimationProgress)progress {
	[self drawTransitionWithView:view progress:progress];
}

- (void) drawTransitionWithView:(NSView *)aView progress:(GrowlAnimationProgress)progress {
	//
}

@end
