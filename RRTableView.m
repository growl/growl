//
//  RRTableView.m
//  Growl
//
//  Created by rudy on 11/12/04.
//  Copyright 2004 Rudy Richter. All rights reserved.
//

#import "RRTableView.h"


@implementation RRTableView

+(void)load
{
	[super load];
	[self poseAsClass:[NSTableView class]];
}

- (BOOL)becomeFirstResponder {
	[super becomeFirstResponder];
	if([[self delegate] respondsToSelector:@selector(tableViewDidClickInBody:)]) {
		[[self delegate] tableViewDidClickInBody:self];
	}
	return YES;
}

@end
