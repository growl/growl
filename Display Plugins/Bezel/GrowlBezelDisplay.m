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
	notificationQueue = [[NSMutableArray alloc] init];
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
	return [NSDictionary dictionaryWithObjectsAndKeys:
		B_NAME, @"Name",
		B_AUTHOR, @"Author",
		B_VERSION, @"Version",
		B_DESCRIPTION, @"Description",
		nil];
}

- (NSPreferencePane *) preferencePane {
	return bezelPrefPane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlBezelWindowController *nuBezel = [GrowlBezelWindowController bezelWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[nuBezel setDelegate:self];
	if ( [notificationQueue count] > 0U ) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlBezelWindowController *aNotification;
		BOOL	inserted = NO;
		int		theIndex = 0;
		
		while (!inserted && (aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuBezel priority]) {
				[notificationQueue insertObject: nuBezel atIndex:theIndex];
				if (theIndex == 0) {
					[aNotification stopFadeOut];
					[nuBezel startFadeIn];
				}
				inserted = YES;
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
	[notificationQueue removeObjectAtIndex:0U];
	if ( [notificationQueue count] > 0U ) {
		olBezel = [notificationQueue objectAtIndex:0U];
		[olBezel startFadeIn];
	}
}

@end
