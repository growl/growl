//
//  RRTableView.m
//  Growl
//
//  Created by rudy on 11/12/04.
//  Copyright 2004 Rudy Richter. All rights reserved.
//

#import "RRTableView.h"


@implementation RRTableView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL)becomeFirstResponder {
	[super becomeFirstResponder];
	[[self delegate] tableViewDidClickInBody:self];
	return YES;
}

@end
