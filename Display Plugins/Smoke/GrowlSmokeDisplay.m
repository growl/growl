//
//  GrowlSmokeDisplay.m
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlSmokeDisplay.h"
#import "GrowlSmokeWindowController.h"
#import "GrowlSmokePrefsController.h"

static NSString *SmokeAuthor      = @"Matthew Walton";
static NSString *SmokeName        = @"Smoke";
static NSString *SmokeDescription = @"Dark translucent notifications";
static NSString *SmokeVersion     = @"1.0";

@implementation GrowlSmokeDisplay

- (id) init {
	if (self = [super init]) {
		preferencePane = [[GrowlSmokePrefsController alloc] initWithBundle:[NSBundle bundleForClass:[GrowlSmokePrefsController class]]];
	}
	return self;
}

- (void)loadPlugin {
}

- (NSString *)version {
	return SmokeVersion;
}

- (NSString *)author {
	return SmokeAuthor;
}

- (NSString *)name {
	return SmokeName;
}

- (NSString *)userDescription {
	return SmokeDescription;
}

- (void)unloadPlugin {
}

- (NSDictionary *)pluginInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		SmokeName,        @"Name",
		SmokeAuthor,      @"Author",
		SmokeVersion,     @"Version",
		SmokeDescription, @"Description",
		nil];
}

- (NSPreferencePane *)preferencePane {
	return preferencePane;
}

- (void) displayNotificationWithInfo:(NSDictionary *)noteDict {
	//NSLog(@"Smoke: displayNotificationWithInfo");
	GrowlSmokeWindowController *controller = [GrowlSmokeWindowController notifyWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[controller startFadeIn];
}

@end
