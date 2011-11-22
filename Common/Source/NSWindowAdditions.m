//
//  NSWindowAdditions.m
//  Growl
//
//  Created by Ofri Wolfus on 21/08/05.
//  Copyright 2005 Ofri Wolfus. All rights reserved.
//

#import "NSWindowAdditions.h"


@implementation NSWindow (GrowlAdditions)

- (NSPoint)frameOrigin {
	return [self frame].origin;
}

- (NSSize)frameSize {
	return [self frame].size;
}

@end
