//
//  PRServerError.m
//  Prowl
//
//  Created by Zachary West on 2012-04-04.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PRServerError.h"

NSString *const PRServerErrorDomain = @"PRServerErrorDomain";

@implementation PRServerError

+ (id)serverErrorWithStatusCode:(NSInteger)statusCode
{
	return [[[self alloc] initWithDomain:PRServerErrorDomain
									code:statusCode
								userInfo:nil] autorelease];
}

- (NSString *)localizedDescription
{
	return [NSString stringWithFormat:@"%d", self.code];
}

- (NSString *)localizedFailureReason
{
	return [NSString stringWithFormat:@"%d", self.code];
}

@end
