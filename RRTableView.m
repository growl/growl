//
//  RRTableView.m
//  Growl
//
//  Created by Rudy Richter on 11/12/04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "RRTableView.h"


@implementation RRTableView

+ (void) load {
	[super load];
	[self poseAsClass:[NSTableView class]];
}

- (BOOL) becomeFirstResponder {
	[super becomeFirstResponder];
	
	if ([[self delegate] respondsToSelector:@selector(tableViewDidClickInBody:)]) {
		[[self delegate] tableViewDidClickInBody:self];
	}
	
	return YES;
}

@end
