//
//  GrowlBezelDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlBezelDisplay.h"
#import "GrowlBezelWindowController.h"
#import "GrowlBezelPrefs.h"

#define B_AUTHOR @"Jorge Salvador Caffarena"
#define B_NAME @"Bezel"
#define B_DESCRIPTION @"Bezel like notifications, with a twist"
#define B_VERSION @"1.1.0a"

@class NSPreferencePane;

@implementation GrowlBezelDisplay

- (id) init {
	if ( (self = [super init] ) ) {
		bezelPrefPane = [[GrowlBezelPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlBezelPrefs class]]];
	}
	return self;
}

- (void) dealloc {
	[bezelPrefPane release];
	[super dealloc];
}

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
	return bezelPrefPane;
}

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlBezelWindowController *nuBezel = [GrowlBezelWindowController bezelWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[nuBezel setDelegate:self];
	if ( [notificationQueue count] > 0 ) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlBezelWindowController *aNotification;
		BOOL	inserted = FALSE;
		int		theIndex = 0;
		
		while (!inserted && (aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuBezel priority]) {
				[notificationQueue insertObject: nuBezel atIndex:theIndex];
				if (theIndex == 0) {
					[aNotification stopFadeOut];
					[nuBezel startFadeIn];
				}
				inserted = TRUE;
			}
			theIndex++;
		}
		
		if (!inserted) {
			[notificationQueue addObject:nuBezel];
		}
	} else {
		[notificationQueue addObject:nuBezel];
		[nuBezel startFadeIn];
	}
}

- (void) didFadeOut:(id)sender {
	GrowlBezelWindowController *olBezel;
	[notificationQueue removeObjectAtIndex:0];
	if ( [notificationQueue count] > 0 ) {
		olBezel = [notificationQueue objectAtIndex:0];
		[olBezel startFadeIn];
	}
}

@end
