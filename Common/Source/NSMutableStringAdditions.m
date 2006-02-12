//
//  NSMutableStringAdditions.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-11.
//  Copyright 2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details
//

#import "NSMutableStringAdditions.h"


@implementation NSMutableString (GrowlAdditions)

- (void) appendCharacter:(unichar)ch {
	NSString *tmp = [[NSString alloc] initWithCharactersNoCopy:&ch length:1U freeWhenDone:NO];
	[self appendString:tmp];
	[tmp release];
}

@end
