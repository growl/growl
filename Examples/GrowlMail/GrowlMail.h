
#import <Cocoa/Cocoa.h>
#import "MailHeaders.h"

@interface GrowlMail : MVMailBundle
{
}
+ (void)initialize;
+ (NSBundle *)bundle;
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
- (BOOL)isAccountEnabled:(NSString *)path;
- (void)setAccountEnabled:(BOOL)yesOrNo path:(NSString *)path;
- (BOOL)showSummary;
- (void)setShowSummary:(BOOL)yesOrNo;
@end
