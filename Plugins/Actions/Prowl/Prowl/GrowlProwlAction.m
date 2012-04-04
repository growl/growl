#import "GrowlProwlAction.h"
#import "GrowlProwlPreferencePane.h"

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
		preferencePane = [[GrowlProwlPreferencePane alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"com.prowlapp.Prowl"]];
	
	return preferencePane;
}

@end
