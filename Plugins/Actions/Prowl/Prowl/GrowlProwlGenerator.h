#import <Foundation/Foundation.h>
#import "PRDefines.h"
#import "PRAPIKey.h"

@class GrowlProwlGenerator;

@protocol GrowlProwlGeneratorDelegate <NSObject>
- (void)generator:(GrowlProwlGenerator *)generator didFetchTokenURL:(NSString *)retrieveURL;
- (void)generator:(GrowlProwlGenerator *)generator didFetchApiKey:(PRAPIKey *)apiKey;
- (void)generator:(GrowlProwlGenerator *)generator didFailWithError:(NSError *)error;
@end

@interface GrowlProwlGenerator : NSObject

- (id)initWithProviderKey:(NSString *)providerKey
				 delegate:(id<GrowlProwlGeneratorDelegate>)delegate;
@property (nonatomic, copy, readonly) NSString *providerKey;
@property (nonatomic, assign, readonly) id<GrowlProwlGeneratorDelegate> delegate;

- (void)fetchToken;
@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, copy, readonly) NSString *tokenURL;

- (void)fetchApiKey;
@property (nonatomic, retain, readonly) PRAPIKey *apiKey;

@end
