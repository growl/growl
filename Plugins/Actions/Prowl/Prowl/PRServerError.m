#import "PRServerError.h"
#import "PRDefines.h"

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
			localizedDescription = PRLocalizedString(@"The application sent a command the server didn't understand. Please try again.", nil);
			break;
		case PRStatusCodeNotApproved:
			localizedDescription = PRLocalizedString(@"You didn't log in and allow an API key to be generated.", nil);
			break;
		case PRStatusCodeInternalError:
			localizedDescription = PRLocalizedString(@"An error occurred on the server. Please try again.", nil);
			break;
		default:
			localizedDescription = PRLocalizedString(@"An unknown error occured. Please try again.", nil);
			break;
	}
	
	return localizedDescription;
}

- (NSString *)localizedFailureReason
{
	return [NSString stringWithFormat:@"%ld", self.code];
}

@end
