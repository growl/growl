#import <Foundation/Foundation.h>
#import "PRAPIKey.h"

@class GrowlProwlValidator;
@protocol GrowlProwlValidatorDelegate <NSObject>
- (void)validator:(GrowlProwlValidator *)validator didValidateApiKey:(PRAPIKey *)apiKey;
- (void)validator:(GrowlProwlValidator *)validator didInvalidateApiKey:(PRAPIKey *)apiKey;
- (void)validator:(GrowlProwlValidator *)validator didFailWithError:(NSError *)error forApiKey:(PRAPIKey *)apiKey;
@end

@interface GrowlProwlValidator : NSObject

- (id)initWithDelegate:(id<GrowlProwlValidatorDelegate>)delegate;
@property (nonatomic, assign, readonly) id<GrowlProwlValidatorDelegate> delegate;

- (void)validateApiKey:(PRAPIKey *)apiKey;

@end
