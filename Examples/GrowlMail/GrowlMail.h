
#import <Cocoa/Cocoa.h>
#import "MailHeaders.h"

@interface GrowlMail : MVMailBundle
{
}
+ (void)initialize;
+ (NSString *)bundleVersion;
+ (BOOL)hasPreferencesPanel;
+ (NSString *)preferencesOwnerClassName;
+ (NSString *)preferencesPanelName;
- (id)init;
- (void)gabResponse:(id)context;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)yesOrNo;
- (BOOL)isIgnoreJunk;
- (void)setIgnoreJunk:(BOOL)yesOrNo;
@end
