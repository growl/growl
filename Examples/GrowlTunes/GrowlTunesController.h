//
//  GrowlTunesController.h
//  GrowlTunes
//
//  Created by Nelson Elhage on Mon Jun 21 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#define ITUNES_TRACK_CHANGED	@"iTunes-ChangedTracks"
#define ITUNES_PAUSED			@"iTunes-Paused"
#define ITUNES_STOPPED			@"iTunes-Stopped"
#define ITUNES_PLAYING			@"iTunes-Playing"

#define DEFAULT_POLL_INTERVAL	3

typedef enum {
	itPLAYING,
	itPAUSED,
	itSTOPPED,
	itUNKNOWN
} iTunesState;

@interface GrowlTunesController : NSObject {
	NSTimer				* pollTimer;
	double				  pollInterval;
	NSAppleScript		* pollScript;
	
	NSAppleScript		* getTrackScript;
	NSAppleScript		* getArtistScript;
	NSAppleScript		* getArtworkScript;
	NSAppleScript		* getAlbumScript;
	NSAppleScript		* quitiTunesScript;

	NSStatusItem		* statusItem;

	iTunesState			  state;
	int					  trackID;		//The "database ID" of the last-polled track in iTunes, -1 for none

	NSMutableArray		* plugins;
}

- (BOOL)iTunesIsRunning;
- (NSDictionary *)iTunesProcess;
- (BOOL)quitiTunes;

- (void)registerGrowl:(void *)context;

#pragma mark Poll timer

- (void)poll: (NSTimer *)timer;
- (void)startTimer;
- (void)stopTimer;

#pragma mark Status item

- (void)createStatusItem;
- (void)tearDownStatusItem;
- (NSMenu *)statusItemMenu;

#pragma mark Plug-ins

- (NSMutableArray *)loadPlugins;

@end
