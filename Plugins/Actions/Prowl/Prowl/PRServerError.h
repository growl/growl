#import <Foundation/Foundation.h>

extern NSString *const PRServerErrorDomain;

typedef enum {
	PRStatusCodeSuccess = 200,
	PRStatusCodeBadRequest = 400, 
	PRStatusCodeNotAuthorized = 401,
	PRStatusCodeNotAcceptable = 406,
	PRStatusCodeNotApproved = 409,
	PRStatusCodeInternalError = 500,
} PRStatusCode;

@interface PRServerError : NSError

+ (id)serverErrorWithStatusCode:(NSInteger)statusCode;

@end
