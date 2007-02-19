/*	NSMutableDictionary+Intersection.h
 *
 *	Created by Peter Hosey on 2006-04-20.
 *	Copyright 2006 Peter Hosey. All rights reserved.
 */

#import <Cocoa/Cocoa.h>


@interface NSMutableDictionary (BZIntersection)

- (void)intersectWithSetOfKeys:(NSSet *)keys;

@end
