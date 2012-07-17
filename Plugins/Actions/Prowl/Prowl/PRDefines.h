#ifndef Prowl_PRDefines_h
#define Prowl_PRDefines_h

#import "PRAction.h" // so the localized string can be smart

#define PR_SELECTOR(name) NSStringFromSelector(@selector(name))

#define PRLocalizedString(string, hint) NSLocalizedStringFromTableInBundle(string, @"Localizable", [NSBundle bundleForClass:[PRAction class]], hint)

extern NSString *const PRProviderKey;

extern NSString *const PRPreferenceKeyAPIKeys;
extern NSString *const PRPreferenceKeyOnlyWhenIdle;
extern NSString *const PRPreferenceKeyMinimumPriority;
extern NSString *const PRPreferenceKeyMinimumPriorityEnabled;
extern NSString *const PRPreferenceKeyPrefix;
extern NSString *const PRPreferenceKeyPrefixEnabled;

#endif
