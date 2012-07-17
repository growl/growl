#import <Foundation/Foundation.h>
#import "PRDefines.h"
#import "PRAPIKey.h"

@class PRGenerator;

@protocol PRGeneratorDelegate <NSObject>
- (void)generator:(PRGenerator *)generator didFetchTokenURL:(NSString *)retrieveURL;
- (void)generator:(PRGenerator *)generator didFetchApiKey:(PRAPIKey *)apiKey;
- (void)generator:(PRGenerator *)generator didFailWithError:(NSError *)error;
@end

@interface PRGenerator : NSObject

- (id)initWithProviderKey:(NSString *)providerKey
				 delegate:(id<PRGeneratorDelegate>)delegate;
@property (nonatomic, copy, readonly) NSString *providerKey;
@property (nonatomic, assign, readonly) id<PRGeneratorDelegate> delegate;

- (void)fetchToken;
@property (nonatomic, copy, readonly) NSString *token;
@property (nonatomic, copy, readonly) NSString *tokenURL;

- (void)fetchApiKey;
@property (nonatomic, retain, readonly) PRAPIKey *apiKey;

@end
