/*	NSMutableDictionary+Intersection.m
 *
 *	Created by Peter Hosey on 2006-04-20.
 *	Copyright 2006 Peter Hosey. All rights reserved.
 */

#import "NSMutableDictionary+Intersection.h"


@implementation NSMutableDictionary (BZIntersection)

- (void)intersectWithSetOfKeys:(NSSet *)keys {
	NSEnumerator *keyEnumerator = [self keyEnumerator];
	NSString *key;
	while((key = [keyEnumerator nextObject])) {
		if(![keys containsObject:key])
			[self removeObjectForKey:key];
	}
}

@end
