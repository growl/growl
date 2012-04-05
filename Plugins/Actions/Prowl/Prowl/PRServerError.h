#import <Foundation/Foundation.h>

extern NSString *const PRServerErrorDomain;

@interface PRServerError : NSError

+ (id)serverErrorWithStatusCode:(NSInteger)statusCode;

@end
