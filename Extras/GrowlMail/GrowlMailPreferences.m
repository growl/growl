//
//  GrowlMailPreferences.m
//  GrowlMail
//
//  Created by Ingmar Stein on 30.10.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlMailPreferences.h"
#import "GrowlMailPreferencesModule.h"
#import "GrowlMail.h"

@implementation GrowlMailPreferences
// we need to do posing as the other mail bundles do that too
+ (void) load
{
	[GrowlMailPreferences poseAsClass:[NSPreferences class]];
}

+ (id)sharedPreferences
{
	static BOOL	added = NO;
	id preferences = [super sharedPreferences];

	if(preferences && !added) {
		added = YES;
		[preferences addPreferenceNamed:[GrowlMail preferencesPanelName] owner:[GrowlMailPreferencesModule sharedInstance]];
	}

    return( preferences );
}
@end
