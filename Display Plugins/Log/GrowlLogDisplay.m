//
//  GrowlLogDisplay.m
//  Growl Display Plugins
//
//  Created by Nelson Elhage on 8/23/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlLogDisplay.h"
@class NSPreferencePane;

@implementation GrowlLogDisplay

- (void) loadPlugin {}
- (NSString *) author {return @"Nelson Elhage"; }
- (NSString *) name { return @"Log"; }
- (NSString *) userDescription { return @"NSLog()s notifications to the console"; }
- (NSString *) version { return @"0.1"; }
- (void) unloadPlugin {}

- (NSDictionary*) pluginInfo {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		@"NSLogging", @"Name",
		@"Nelson Elhage", @"Author",
		@"0.1", @"Version",
		@"NSLog()s notifications to the console", @"Description",
		nil];
}

- (NSPreferencePane *) preferencePane {
	return nil;
}

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
	NSLog(@"%@ [%@]: %@ (%@)",[noteDict objectForKey:GROWL_APP_NAME], 
							[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY],
							[noteDict objectForKey:GROWL_NOTIFICATION_TITLE], 
							[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]);
}
@end
