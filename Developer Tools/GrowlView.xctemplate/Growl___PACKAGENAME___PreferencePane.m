//
//  ___FILENAME___
//  ___PACKAGENAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright (c) ___YEAR___ ___ORGANIZATIONNAME___. All rights reserved.
//

#import "Growl___PACKAGENAME___PreferencePane.h"

@implementation Growl___PACKAGENAME___PreferencePane

-(NSString*)mainNibName {
	return @"___PACKAGENAME___PrefPane";
}

- (NSSet*)bindingKeys {
	static NSSet *keys = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		keys = [[NSSet set] retain];
	});
	return keys;
}

@end
