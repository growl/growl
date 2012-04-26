#import <Foundation/Foundation.h>
#import "PRAPIKey.h"

@class PRValidator;
@protocol PRValidatorDelegate <NSObject>
- (void)validator:(PRValidator *)validator didValidateApiKey:(PRAPIKey *)apiKey;
- (void)validator:(PRValidator *)validator didInvalidateApiKey:(PRAPIKey *)apiKey;
- (void)validator:(PRValidator *)validator didFailWithError:(NSError *)error forApiKey:(PRAPIKey *)apiKey;
@end

@interface PRValidator : NSObject

- (id)initWithDelegate:(id<PRValidatorDelegate>)delegate;
@property (nonatomic, assign, readonly) id<PRValidatorDelegate> delegate;

- (void)validateApiKey:(PRAPIKey *)apiKey;
- (BOOL)isValidatingApiKey:(PRAPIKey *)apiKey;

@end
