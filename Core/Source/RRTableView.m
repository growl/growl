//
//  RRTableView.m
//  Growl
//
//  Created by Rudy Richter on 11/12/04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "RRTableView.h"

@implementation RRTableView

- (BOOL) becomeFirstResponder {
	BOOL accept = [super becomeFirstResponder];

	id delegate = [self delegate];
	if ([delegate respondsToSelector:@selector(tableViewDidClickInBody:)]) {
		[delegate tableViewDidClickInBody:self];
	}

	return accept;
}

- (void)deleteSelection {
	[deleteControl performClick:self];
}

- (void)deleteBackward:(id)inSender {
	[self deleteSelection];
}

- (void)deleteForward:(id)inSender {
	[self deleteSelection];
}

- (void)keyDown:(NSEvent*)event {
	BOOL deleteKeyEvent = NO;
    
	if ([event type] == NSKeyDown) {
		NSString* pressedChars = [event characters];
		if ([pressedChars length] == 1) {
			unichar pressed = [pressedChars characterAtIndex:0];
            if ( (pressed == NSDeleteCharacter) || 
                (pressed == NSDeleteFunctionKey) )
				deleteKeyEvent = YES;
		}
	}
    
	if (deleteKeyEvent) {
		[self interpretKeyEvents:[NSArray arrayWithObject:event]];
	}
	else {
		[super keyDown:event];
	}
}
@end
