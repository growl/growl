//
//	NSSetAdditions.m
//	Growl
//
//	Created by Peter Hosey on 2005-09-08.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSSetAdditions.h"

@implementation NSSet (NSSetAdditions)

+ (id) setWithUnionOfSetsInArray:(NSArray *)array {
	NSMutableSet *unionSet = [[NSMutableSet alloc] init];

	NSEnumerator *arrayEnum = [array objectEnumerator];
	NSSet *setToAdd;
	while ((setToAdd = [arrayEnum nextObject]))
		[unionSet unionSet:setToAdd];

	NSSet *result = [self setWithSet:unionSet];
	[unionSet release];

	return result;
}

@end
