//
//  BubblePrefsController.m
//  Growl
//
//  Created by Kevin Ballard on 9/7/04.
//  Copyright 2004 TildeSoft. All rights reserved.
//

#import "BubblePrefs.h"

@implementation BubblePrefs
- (NSString *) mainNibName {
	return @"BubblesPrefs";
}

- (void) mainViewDidLoad {
	BOOL limitPref = YES;
	READ_GROWL_PREF_BOOL(KALimitPref, @"com.growl.BubblesNotificationView", &limitPref);
	if (limitPref) {
		[limitCheck setState:NSOnState];
	} else {
		[limitCheck setState:NSOffState];
	}
}

- (IBAction) setLimit:(id)sender {
	BOOL limit;
	if ([sender state] == NSOnState) {
		limit = YES;
	} else {
		limit = NO;
	}
	WRITE_GROWL_PREF_BOOL(KALimitPref, limit, @"com.growl.BubblesNotificationView");
	UPDATE_GROWL_PREFS();
}
@end
