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

#define POLL_INTERVAL			3

typedef enum {
	itPLAYING,
	itPAUSED,
	itSTOPPED,
	itUNKNOWN
} iTunesState;

@interface GrowlTunesController : NSObject {
	NSTimer				* pollTimer;
	NSAppleScript		* pollScript;
	
	NSAppleScript		* getTrackScript;
	NSAppleScript		* getArtistScript;
	NSAppleScript		* getArtworkScript;
	NSAppleScript		* getAlbumScript;
	
	iTunesState			  state;
	int					  trackID;		//The "database ID" of the last-polled track in iTunes, -1 for none
}

- (BOOL)iTunesIsRunning;
- (void)registerGrowl:(void *)context;
- (void)poll: (NSTimer *)timer;

@end
