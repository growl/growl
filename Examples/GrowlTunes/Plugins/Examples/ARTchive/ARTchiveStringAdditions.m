//
//  ARTchiveStringAdditions.m
//  ARTchive
//
//  Created by Kevin Ballard on 10/5/04.
//  Copyright 2004 Kevin Ballard. All rights reserved.
//

#import "ARTchiveStringAdditions.h"


@implementation NSString (ARTchiveStringAdditions)
- (NSString *)stringByMakingPathSafe {
	NSMutableString *temp = [self mutableCopy];
	[temp replaceOccurrencesOfString:@":" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
	[temp replaceOccurrencesOfString:@"/" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
	return [NSString stringWithString:temp];
}
@end
