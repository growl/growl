//
//  GrowlTunesController.h
//  GrowlTunes
//
//  Created by Nelson Elhage on Mon Jun 21 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#define ITUNES_TRACK_CHANGED	@"Changed Tracks"
#define ITUNES_PAUSED			@"Paused"
#define ITUNES_STOPPED			@"Stopped"
#define ITUNES_PLAYING			@"Started Playing"

#define DEFAULT_POLL_INTERVAL	3

typedef enum {
	itPLAYING,
	itPAUSED,
	itSTOPPED,
	itUNKNOWN
} iTunesState;

@interface GrowlTunesController : NSObject {
	NSTimer				*pollTimer;
	NSAppleScript		*pollScript;
	NSAppleScript		*getInfoScript;
	NSAppleScript		*quitiTunesScript;
	NSMutableArray		*plugins;
	NSStatusItem		*statusItem;
	NSString			*playlistName;
	NSMutableArray		*recentTracks;
	NSMenu				*iTunesSubMenu;
	
	iTunesState			state;
	BOOL				_polling;
	double				pollInterval;
	int					trackID;
	NSString			* trackURL;		//The file location of the last-known track in iTunes, @"" for none
}

- (BOOL)iTunesIsRunning;
- (NSDictionary *)iTunesProcess;
- (BOOL)quitiTunes;

- (void)registerGrowl:(void *)context;

- (void)setPolling:(BOOL)flag;

#pragma mark Poll timer

- (void)poll:(NSTimer *)timer;
- (void)startTimer;
- (void)stopTimer;

#pragma mark Status item

- (void)createStatusItem;
- (void)tearDownStatusItem;
- (NSMenu *)statusItemMenu;

#pragma mark Plug-ins

- (NSMutableArray *)loadPlugins;

@end
