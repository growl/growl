//
//  ___FILENAME___
//  ___PACKAGENAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright (c) ___YEAR___ ___ORGANIZATIONNAME___. All rights reserved.
//

#import "Growl___PACKAGENAME___Action.h"
#import "Growl___PACKAGENAME___PreferencePane.h"

@implementation Growl___PACKAGENAME___Action

-(void)dispatchNotification:(NSDictionary *)notification withConfiguration:(NSDictionary *)configuration {
	//Insert main code for dispatching the notification here!
}

- (GrowlPluginPreferencePane *) preferencePane {
	if (!preferencePane)
		preferencePane = [[Growl___PACKAGENAME___PreferencePane alloc] initWithBundle:[NSBundle bundleWithIdentifier:@"___VARIABLE_bundleIdentifierPrefix:bundleIdentifier___.___PACKAGENAME___"]];
	
	return preferencePane;
}

@end
