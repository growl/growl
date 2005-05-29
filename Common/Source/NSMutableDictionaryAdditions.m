//
//  NSMutableDictionaryAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 29.05.05.
//  Copyright 2005 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSMutableDictionaryAdditions.h"

@implementation NSMutableDictionary(GrowlAdditions)
- (void) setBool:(BOOL)value forKey:(NSString *)key {
	NSNumber *number = [[NSNumber alloc] initWithBool:value];
	[self setObject:number forKey:key];
	[number release];
}

- (void) setInteger:(int)value forKey:(NSString *)key {
	NSNumber *number = [[NSNumber alloc] initWithInt:value];
	[self setObject:number forKey:key];
	[number release];
}

@end
