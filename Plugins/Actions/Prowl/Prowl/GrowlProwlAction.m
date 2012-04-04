#import "GrowlProwlAction.h"
#import "GrowlProwlPreferencePane.h"

NSString *const PRPreferenceKeyAPIKeys = @"PRPreferenceKeyAPIKeys";
NSString *const PRPreferenceKeyOnlyWhenIdle = @"PRPreferenceKeyOnlyWhenIdle";
NSString *const PRPreferenceKeyMinimumPriority = @"PRPreferenceKeyMinimumPriority";
NSString *const PRPreferenceKeyMinimumPriorityEnabled = @"PRPreferenceKeyMinimumPriorityEnabled";
NSString *const PRPreferenceKeyPrefix = @"PRPreferenceKeyPrefix";
NSString *const PRPreferenceKeyPrefixEnabled = @"PRPreferenceKeyPrefixEnabled";

@implementation GrowlProwlAction

- (id)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)dispatchNotification:(NSDictionary *)notification
		  withConfiguration:(NSDictionary *)configuration
{
	
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[GrowlProwlPreferencePane alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.prowlapp.growl.Prowl"]];
	
	return preferencePane;
}

@end
