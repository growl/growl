//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlBezelDisplay.h"
#import "GrowlBezelWindowController.h"

#define B_AUTHOR @"Jorge Salvador Caffarena"
#define B_NAME @"Bezel"
#define B_DESCRIPTION @"Bezel like notifications, with a twist"
#define B_VERSION @"0.1.0"

@implementation GrowlBezelDisplay

- (void) loadPlugin {
	notificationQueue = [[NSMutableArray array] retain];
}

- (NSString *) author {
	return B_AUTHOR;
}

- (NSString *) name {
	return B_NAME;
}

- (NSString *) userDescription {
	return B_DESCRIPTION;
}

- (NSString *) version {
	return B_VERSION;
}

- (void) unloadPlugin {
	[notificationQueue release];
}

- (NSDictionary*) pluginInfo {
	NSMutableDictionary * info = [NSMutableDictionary dictionary];
	[info setObject:B_NAME forKey:@"Name"];
	[info setObject:B_AUTHOR forKey:@"Author"];
	[info setObject:B_VERSION forKey:@"Version"];
	[info setObject:B_DESCRIPTION forKey:@"Description"];
	return (NSDictionary*)info;	
}

- (NSPreferencePane *) preferencePane {
	return nil;
}

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlBezelWindowController *nuBezel = [GrowlBezelWindowController bezelWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[nuBezel setDelegate:self];
	[notificationQueue addObject:nuBezel];
	if ( [notificationQueue count] == 1 ) {
		[nuBezel startFadeIn];
	}
}

- (void)bezelWillFadeIn:(GrowlBezelWindowController *)bezel {
}

- (void)bezelDidFadeIn:(GrowlBezelWindowController *)bezel {
}


- (void)bezelWillFadeOut:(GrowlBezelWindowController *)bezel {
}

- (void)bezelDidFadeOut:(GrowlBezelWindowController *)bezel {
	GrowlBezelWindowController *olBezel;
	[notificationQueue removeObjectAtIndex:0];
	if ( [notificationQueue count] > 0 ) {
		olBezel = [notificationQueue objectAtIndex:0];
		[olBezel startFadeIn];
	}
}

@end
