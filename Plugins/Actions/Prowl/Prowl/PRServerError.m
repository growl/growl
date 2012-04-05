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
	NSString *localizedDescription = nil;
	
	switch((PRStatusCode)self.code) {
		case PRStatusCodeNotAuthorized:
		case PRStatusCodeBadRequest:
		case PRStatusCodeNotAcceptable:
			localizedDescription = NSLocalizedString(@"The application sent a command the server didn't understand. Please try again.", nil);
			break;
		case PRStatusCodeNotApproved:
			localizedDescription = NSLocalizedString(@"You didn't log in and allow an API key to be generated.", nil);
			break;
		case PRStatusCodeInternalError:
			localizedDescription = NSLocalizedString(@"An error occurred on the server. Please try again.", nil);
			break;
		default:
			localizedDescription = NSLocalizedString(@"An unknown error occured. Please try again.", nil);
			break;
	}
	
	return localizedDescription;
}

- (NSString *)localizedFailureReason
{
	return [NSString stringWithFormat:@"%d", self.code];
}

@end
