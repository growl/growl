//
//  GrowlNSLogDisplay.m
//  Growl Display Plugins
//
//  Created by Nelson Elhage on 8/23/04.
//  Copyright 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlNSLogDisplay.h"


@implementation GrowlNSLogDisplay

- (void) loadPlugin {}
- (NSString *) author {return @"Nelson Elhage"; }
- (NSString *) name { return @"NSLogging"; }
- (NSString *) userDescription { return @"NSLog()s notifications to the console";}
- (NSString *) version { return @"Testing"; }
- (void) unloadPlugin {}
- (NSDictionary*) pluginInfo {
	NSMutableDictionary * info = [NSMutableDictionary dictionary];
	[info setObject:@"NSLogging" forKey:@"Name"];
	[info setObject:@"Nelson Elhage" forKey:@"Author"];
	[info setObject:@"0.1" forKey:@"Version"];
	[info setObject:@"NSLog()s notifications to the console" forKey:@"Description"];
	return (NSDictionary*)info;	
}

- (NSView*) displayPrefView {
	return nil;
}

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
	NSLog(@"%@: %@ (%@)",[noteDict objectForKey:GROWL_APP_NAME], 
							[noteDict objectForKey:GROWL_NOTIFICATION_TITLE], 
							[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]);
}
@end
