#import <Foundation/Foundation.h>

@interface PRAPIKey : NSObject <NSCoding>

@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) BOOL validated;
@property (nonatomic, copy) NSString *apiKey;

@end
