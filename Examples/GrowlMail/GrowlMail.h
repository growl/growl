
#import <Cocoa/Cocoa.h>
#import "MailHeaders.h"

@interface GrowlMail : MVMailBundle
{
}
+ (void)initialize;
+ (NSString *)bundleVersion;
- (id)init;
- (void)gabResponse:(id)context;
@end
