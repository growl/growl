/*
 Copyright (c) The Growl Project, 2004 
 All rights reserved.
 
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Growl nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.
 
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

//
//  GrowlTunesController.h
//  GrowlTunes
//
//  Created by Nelson Elhage on Mon Jun 21 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlTunesPlugin.h"

#define ITUNES_TRACK_CHANGED	@"Changed Tracks"
#define ITUNES_PAUSED			@"Paused"
#define ITUNES_STOPPED			@"Stopped"
#define ITUNES_PLAYING			@"Started Playing"

#define DEFAULT_POLL_INTERVAL	2

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
	id <GrowlTunesPluginArchive> archivePlugin;
	
	iTunesState			state;
	BOOL				polling;
	double				pollInterval;
	int					trackID;
	NSString			* trackURL;		//The file location of the last-known track in iTunes, @"" for none
}

- (BOOL)iTunesIsRunning;
- (NSDictionary *)iTunesProcess;
- (BOOL)quitiTunes;

#ifdef USE_OLD_GAB
- (void)registerGrowl:(void *)context;
#endif

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
