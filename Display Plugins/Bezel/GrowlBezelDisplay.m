//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlNSLogDisplay.h"
#define B_AUTHOR @"Jorge Salvador Caffarena"
#define B_NAME @"Bezel"
#define B_DESCRIPTION @"Bezel like notifications, with a twist"
#define B_VERSION @"0.1.0"

@implementation GrowlNSLogDisplay

- (void) loadPlugin {}
- (NSString *) author {return B_AUTHOR; }
- (NSString *) name { return B_NAME; }
- (NSString *) userDescription { return B_DESCRIPTION;}
- (NSString *) version { return B_VERSION; }
- (void) unloadPlugin {}
- (NSDictionary*) pluginInfo {
	NSMutableDictionary * info = [NSMutableDictionary dictionary];
	[info setObject:B_NAME forKey:@"Name"];
	[info setObject:B_AUTHOR forKey:@"Author"];
	[info setObject:B_VERSION forKey:@"Version"];
	[info setObject:B_DESCRIPTION forKey:@"Description"];
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
