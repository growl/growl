#ifndef Prowl_PRDefines_h
#define Prowl_PRDefines_h

#define PR_SELECTOR(name) NSStringFromSelector(@selector(name))

extern NSString *const PRProviderKey;

extern NSString *const PRPreferenceKeyAPIKeys;
extern NSString *const PRPreferenceKeyOnlyWhenIdle;
extern NSString *const PRPreferenceKeyMinimumPriority;
extern NSString *const PRPreferenceKeyMinimumPriorityEnabled;
extern NSString *const PRPreferenceKeyPrefix;
extern NSString *const PRPreferenceKeyPrefixEnabled;

typedef enum {
	PRStatusCodeSuccess = 200,
	PRStatusCodeBadRequest = 400, 
	PRStatusCodeNotAuthorized = 401,
	PRStatusCodeNotAcceptable = 406,
	PRStatusCodeNotApproved = 409,
	PRStatusCodeInternalError = 500,
} PRStatusCode;

#endif
