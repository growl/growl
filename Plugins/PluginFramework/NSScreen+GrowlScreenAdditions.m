//
//  NSScreen+GrowlScreenAdditions.m
//  Growl
//
//  Created by Daniel Siemer on 4/6/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "NSScreen+GrowlScreenAdditions.h"

@implementation NSScreen (GrowlScreenAdditions)

-(NSUInteger)screenID {
	return [[[self deviceDescription] valueForKey:@"NSScreenNumber"] unsignedIntegerValue];
}

-(NSString*)screenIDString {
	return [NSString stringWithFormat:@"%lu", [self screenID]];
}

@end
