//
//  GrowlMusicVideoDisplay.h
//  Growl Display Plugins
//
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//
#import "GrowlMusicVideoDisplay.h"
#import "GrowlMusicVideoWindowController.h"
#import "GrowlMusicVideoPrefs.h"

#define B_AUTHOR @"Jorge Salvador Caffarena"
#define B_NAME @"Music Video"
#define B_DESCRIPTION @"Music Video notifications, for your tunes"
#define B_VERSION @"0.1.0"

@class NSPreferencePane;

@implementation GrowlMusicVideoDisplay

- (id) init {
	if ( (self = [super init] ) ) {
		musicVideoPrefPane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlMusicVideoPrefs class]]];
	}
	return self;
}

- (void) dealloc {
	[musicVideoPrefPane release];
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
	return musicVideoPrefPane;
}

- (void) displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlMusicVideoWindowController *nuMusicVideo = [GrowlMusicVideoWindowController musicVideoWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
			text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
			icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
			priority:[[noteDict objectForKey:GROWL_NOTIFICATION_PRIORITY] intValue]
			sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[nuMusicVideo setDelegate:self];
	if ( [notificationQueue count] > 0 ) {
		NSEnumerator *enumerator = [notificationQueue objectEnumerator];
		GrowlMusicVideoWindowController *aNotification;
		BOOL	inserted = FALSE;
		int		theIndex = 0;
		
		while (!inserted && (aNotification = [enumerator nextObject])) {
			if ([aNotification priority] < [nuMusicVideo priority]) {
				[notificationQueue insertObject: nuMusicVideo atIndex:theIndex];
				if (theIndex == 0) {
					[aNotification stopFadeOut];
					[nuMusicVideo startFadeIn];
				}
				inserted = TRUE;
			}
			theIndex++;
		}
		
		if (!inserted) {
			[notificationQueue addObject:nuMusicVideo];
		}
	} else {
		[notificationQueue addObject:nuMusicVideo];
		[nuMusicVideo startFadeIn];
	}
}

- (void)didFadeOut:(id)sender {
	GrowlMusicVideoWindowController *olMusicVideo;
	[notificationQueue removeObjectAtIndex:0];
	if ( [notificationQueue count] > 0 ) {
		olMusicVideo = [notificationQueue objectAtIndex:0];
		[olMusicVideo startFadeIn];
	}
}

@end
