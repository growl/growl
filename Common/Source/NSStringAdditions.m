//
//  NSStringAdditions.m
//  Growl
//
//  Created by Ingmar Stein on 16.05.05.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import "NSStringAdditions.h"

@implementation NSString (GrowlAdditions)

//for greater polymorphism with NSNumber.
- (BOOL) boolValue {
	return [self intValue] != 0
		|| (CFStringCompare((CFStringRef)self, CFSTR("yes"), kCFCompareCaseInsensitive) == kCFCompareEqualTo)
		|| (CFStringCompare((CFStringRef)self, CFSTR("true"), kCFCompareCaseInsensitive) == kCFCompareEqualTo);
}

- (unsigned long) unsignedLongValue {
	return strtoul([self UTF8String], /*endptr*/ NULL, /*base*/ 0);
}

- (unsigned) unsignedIntValue {
	return [self unsignedLongValue];
}

- (BOOL) isSubpathOf:(NSString *)superpath {
	NSString *canonicalSuperpath = [superpath stringByStandardizingPath];
	NSString *canonicalSubpath = [self stringByStandardizingPath];
	return [canonicalSubpath isEqualToString:canonicalSuperpath]
		|| [canonicalSubpath hasPrefix:[canonicalSuperpath stringByAppendingString:@"/"]];
}

@end
