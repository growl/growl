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

- (id)init {
	if (self = [super init]) {
		musicVideoPrefPane = [[GrowlMusicVideoPrefs alloc] initWithBundle:[NSBundle bundleForClass:[GrowlMusicVideoPrefs class]]];
	}
	return self;
}

- (void)dealloc {
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

- (void)  displayNotificationWithInfo:(NSDictionary *) noteDict {
	GrowlMusicVideoWindowController *nuMusicVideo = [GrowlMusicVideoWindowController musicVideoWithTitle:[noteDict objectForKey:GROWL_NOTIFICATION_TITLE] 
																									text:[noteDict objectForKey:GROWL_NOTIFICATION_DESCRIPTION] 
																									icon:[noteDict objectForKey:GROWL_NOTIFICATION_ICON]
																								  sticky:[[noteDict objectForKey:GROWL_NOTIFICATION_STICKY] boolValue]];
	[nuMusicVideo setDelegate:self];
	[notificationQueue addObject:nuMusicVideo];
	if ( [notificationQueue count] == 1 ) {
		[nuMusicVideo startFadeIn];
	}
}

- (void)musicVideoWillFadeIn:(GrowlMusicVideoWindowController *)musicVideo {
}

- (void)musicVideoDidFadeIn:(GrowlMusicVideoWindowController *)musicVideo {
}


- (void)musicVideoWillFadeOut:(GrowlMusicVideoWindowController *)musicVideo {
}

- (void)musicVideoDidFadeOut:(GrowlMusicVideoWindowController *)musicVideo {
	GrowlMusicVideoWindowController *olMusicVideo;
	[notificationQueue removeObjectAtIndex:0];
	if ( [notificationQueue count] > 0 ) {
		olMusicVideo = [notificationQueue objectAtIndex:0];
		[olMusicVideo startFadeIn];
	}
}

@end
