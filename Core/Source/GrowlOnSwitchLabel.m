//
//  GrowlOnSwitchLabel.m
//  Growl
//
//  Created by Rudy Richter on 7/29/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlOnSwitchLabel.h"

@implementation GrowlOnSwitchLabel

- (void)mouseUp:(NSEvent*)sender
{
	if(![self isEnabled])
		return;
	
    if(CGRectContainsPoint([self frame], [self.superview convertPoint:[sender locationInWindow] fromView:nil]))
        [self sendAction:[self action] to:[self target]];
}

@end
