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
//  GrowlTunesController.m
//  GrowlTunes
//
//  Created by Nelson Elhage on Mon Jun 21 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlTunesController.h"
#import <Growl/Growl.h>
#import "NSWorkspaceAdditions.h"

#define ONLINE_HELP_URL		    @"http://growl.info/documentation/growltunes.php"

@interface GrowlTunesController (PRIVATE)
- (NSAppleScript *) appleScriptNamed:(NSString *)name;
- (void) addTuneToRecentTracks:(NSString *)inTune fromPlaylist:(NSString *)inPlaylist;
- (NSMenu *) buildiTunesSubmenu;
- (NSMenu *) buildRatingSubmenu;
- (void) jumpToTune:(id) sender;
@end

static NSString *appName		= @"GrowlTunes";
static NSString *iTunesAppName	= @"iTunes.app";
static NSString *iTunesBundleID = @"com.apple.itunes";

static NSString *pollIntervalKey  = @"Poll interval";
static NSString *noMenuKey        = @"GrowlTunesWithoutMenu";
static NSString *recentTrackCount = @"Recent Tracks Count";

static const unsigned defaultRecentTracksLimit = 20U;

//status item menu item tags.
enum {
	ratingTag = -11,
	onlineHelpTag = -5,
	quitGrowlTunesTag,
	launchQuitiTunesTag,
	quitBothTag,
	togglePollingTag,
};

@implementation GrowlTunesController

- (id)init {
	if ((self = [super init])) {
		[GrowlApplicationBridge setGrowlDelegate:self];

		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble:DEFAULT_POLL_INTERVAL], pollIntervalKey,
			[NSNumber numberWithInt:20], recentTrackCount,
			nil]];

		state = itUNKNOWN;
		NSNumber *recentTrackCountNum = [defaults objectForKey:recentTrackCount];
		recentTracks = [[NSMutableArray alloc] initWithCapacity:(recentTrackCountNum ? [recentTrackCountNum unsignedIntValue] : defaultRecentTracksLimit)];
		archivePlugin = nil;
		plugins = [[self loadPlugins] retain];
		trackID = 0;
		trackURL = @"";
	}

	return self;
}

- (void) applicationWillFinishLaunching: (NSNotification *)notification {
#pragma unused(notification)
	getInfoScript = [self appleScriptNamed:@"jackItunesArtwork"];

	NSString *itunesPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"];
	if ([[[NSBundle bundleWithPath:itunesPath] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] floatValue] > 4.6f) {
		[self setPolling:NO];
	} else {
		[self setPolling:YES];
	}

	if (polling) {
		pollScript   = [self appleScriptNamed:@"jackItunesInfo"];
		pollInterval = [[NSUserDefaults standardUserDefaults] floatForKey:pollIntervalKey];

		if ([self iTunesIsRunning]) [self startTimer];

		NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
		[workspaceCenter addObserver:self
							selector:@selector(handleAppLaunch:)
								name:NSWorkspaceDidLaunchApplicationNotification
							  object:nil];

		[workspaceCenter addObserver:self
							selector:@selector(handleAppQuit:)
								name:NSWorkspaceDidTerminateApplicationNotification
							  object:nil];
	} else {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(songChanged:)
																name:@"com.apple.iTunes.playerInfo"
															  object:nil];
	}
	if (![[NSUserDefaults standardUserDefaults] boolForKey:noMenuKey])
		[self createStatusItem];
}

- (void) applicationWillTerminate:(NSNotification *)notification {
#pragma unused(notification)
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[self stopTimer];
	[self tearDownStatusItem];

	[pollScript    release]; 
	[getInfoScript release];
	[recentTracks  release];

	[plugins release];
	if (archivePlugin) {
		[archivePlugin release];
	}
}

#pragma mark -
#pragma mark Growl delegate conformance

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray	*allNotes = [[NSArray alloc] initWithObjects:
		ITUNES_TRACK_CHANGED,
//		ITUNES_PAUSED,
//		ITUNES_STOPPED,
		ITUNES_PLAYING,
		nil];
	NSImage			* iTunesIcon = [[NSWorkspace sharedWorkspace] iconForApplication:iTunesAppName];
	NSDictionary	* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		appName, GROWL_APP_NAME,
		[iTunesIcon TIFFRepresentation], GROWL_APP_ICON,
		allNotes, GROWL_NOTIFICATIONS_ALL,
		allNotes, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	[allNotes release];
	return regDict;
}

- (NSString *) applicationNameForGrowl {
	return appName;
}

- (void) setPolling:(BOOL)flag {
	polling = flag;
}

#pragma mark -

- (NSString *) starsForRating:(NSNumber *)aRating {
	int rating = aRating ? [aRating intValue] : 0;

	enum {
		BLACK_STAR  = 0x2605, SPACE          = 0x0020, MIDDLE_DOT   = 0x00B7,
		ONE_HALF    = 0x00BD,
		ONE_QUARTER = 0x00BC, THREE_QUARTERS = 0x00BE,
		ONE_THIRD   = 0x2153, TWO_THIRDS     = 0x2154,
		ONE_FIFTH   = 0x2155, TWO_FIFTHS     = 0x2156, THREE_FIFTHS = 0x2157, FOUR_FIFTHS   = 0x2158,
		ONE_SIXTH   = 0x2159, FIVE_SIXTHS    = 0x215a,
		ONE_EIGHTH  = 0x215b, THREE_EIGHTHS  = 0x215c, FIVE_EIGHTHS = 0x215d, SEVEN_EIGHTHS = 0x215e,

		//rating <= 0: dot, space, dot, space, dot, space, dot, space, dot (five dots).
		//higher ratings mean fewer characters. rating >= 100: five black stars.
		numChars = 9,
	};

	static unichar fractionChars[] = {
		/*0/20*/ 0,
		/*1/20*/ ONE_FIFTH, TWO_FIFTHS, THREE_FIFTHS,
		/*4/20 = 1/5*/ ONE_FIFTH,
		/*5/20 = 1/4*/ ONE_QUARTER,
		/*6/20*/ ONE_THIRD, FIVE_EIGHTHS,
		/*8/20 = 2/5*/ TWO_FIFTHS, TWO_FIFTHS,
		/*10/20 = 1/2*/ ONE_HALF, ONE_HALF,
		/*12/20 = 3/5*/ THREE_FIFTHS,
		/*13/20 = 0.65; 5/8 = 0.625*/ FIVE_EIGHTHS,
		/*14/20 = 7/10*/ FIVE_EIGHTHS, //highly approximate, of course, but it's as close as I could get :)
		/*15/20 = 3/4*/ THREE_QUARTERS,
		/*16/20 = 4/5*/ FOUR_FIFTHS, FOUR_FIFTHS,
		/*18/20 = 9/10*/ SEVEN_EIGHTHS, SEVEN_EIGHTHS, //another approximation
	};

	unichar starBuffer[numChars];
	int     wholeStarRequirement = 20;
	unsigned starsRemaining = 5U;
	unsigned i = 0U;
	for (; starsRemaining--; ++i) {
		if (rating >= wholeStarRequirement) {
			starBuffer[i] = BLACK_STAR;
			rating -= 20;
		} else {
			/*examples:
			 *if the original rating is 95, then rating = 15, and we get 3/4.
			 *if the original rating is 80, then rating = 0,  and we get MIDDLE DOT.
			 */
			starBuffer[i] = fractionChars[rating];
			if (!starBuffer[i]) {
				//add a space if this isn't the first 'star'.
				if (i) starBuffer[i++] = SPACE;
				starBuffer[i] = MIDDLE_DOT;
			}
			rating = 0; //ensure that remaining characters are MIDDLE DOT.
		}
	}

	return [NSString stringWithCharacters:starBuffer length:i];
}

#pragma mark -
#pragma mark iTunes 4.7 notifications

- (void) songChanged:(NSNotification *)aNotification {
	NSString     *playerState = nil;
	iTunesState   newState    = itUNKNOWN;
	NSString     *newTrackURL = nil;
	NSDictionary *userInfo    = [aNotification userInfo];

	playerState = [[aNotification userInfo] objectForKey:@"Player State"];
	if ([playerState isEqualToString:@"Paused"]) {
		newState = itPAUSED;
	} else if ([playerState isEqualToString:@"Stopped"]) {
		newState = itSTOPPED;
	} else if ([playerState isEqualToString:@"Playing"]){
		newState = itPLAYING;
		/*For radios and files, the ID is the location.
		 *For iTMS purchases, it's the Store URL.
		 *For Rendezvous shares, we'll hash a compilation of a bunch of info.
		 */
		if ([userInfo objectForKey:@"Location"]) {
			newTrackURL = [userInfo objectForKey:@"Location"];
		} else if ([userInfo objectForKey:@"Store URL"]) {
			newTrackURL = [userInfo objectForKey:@"Store URL"];
		} else {
			/*Get all the info we can, in such a way that the empty fields are
			 *	blank rather than (null).
			 *Then we hash it and turn that into our identifier string.
			 *That way a track name of "file://foo" won't confuse our code later on.
			 */
			NSArray *args = [userInfo objectsForKeys:
				[NSArray arrayWithObjects:@"Name", @"Artist", @"Album", @"Composer", @"Genre",
					@"Year",@"Track Number", @"Track Count", @"Disc Number", @"Disc Count",
					@"Total Time", nil]
									  notFoundMarker:@""];
			newTrackURL = [args componentsJoinedByString:@"|"];
			newTrackURL = [[NSNumber numberWithUnsignedLong:[newTrackURL hash]] stringValue];
		}
	}

	if (newTrackURL && ![newTrackURL isEqualToString:trackURL]) { // this is different from previous notification
		NSString		*track         = nil;
		NSString		*length        = nil;
		NSString		*artist        = @"";
		NSString		*album         = @"";
		BOOL			compilation    = NO;
		NSNumber		*rating        = nil;
		NSString		*ratingString  = nil;
		NSImage			*artwork       = nil;
		NSString		*displayString = nil;
		NSDictionary	*error         = nil;

		if ([userInfo objectForKey:@"Artist"])
			artist = [userInfo objectForKey:@"Artist"];
		if ([userInfo objectForKey:@"Album"])
			album = [userInfo objectForKey:@"Album"];
		track = [userInfo objectForKey:@"Name"];

		length  = [userInfo objectForKey:@"Total Time"];
		// need to format a bit the length as it is returned in ms
		int sec  = [length intValue] / 1000;
		int hr  = sec/3600;
		sec -= 3600*hr;
		int min = sec/60;
		sec -= 60*min;
		if (hr > 0)
			length = [NSString stringWithFormat:@"%d:%02d:%02d", hr, min, sec];
		else
			length = [NSString stringWithFormat:@"%d:%02d", min, sec];

		compilation = ([userInfo objectForKey:@"Compilation"] != nil);

		if ([newTrackURL hasPrefix:@"file:/"] || [newTrackURL hasPrefix:@"itms:/"]) {
			NSAppleEventDescriptor	*theDescriptor = [getInfoScript executeAndReturnError:&error];
			NSAppleEventDescriptor  *curDescriptor;

			rating = [userInfo objectForKey:@"Rating"];
			ratingString = [self starsForRating:rating];

			curDescriptor = [theDescriptor descriptorAtIndex:2L];
			playlistName = [curDescriptor stringValue];
			curDescriptor = [theDescriptor descriptorAtIndex:1L];
			const OSType type = [curDescriptor typeCodeValue];

			if (type != 'null') {
				artwork = [[[NSImage alloc] initWithData:[curDescriptor data]] autorelease];
			}
		}

		//get artwork via plugins if needed (for file:/ and itms:/ id only)
		if (!artwork && ![newTrackURL hasPrefix:@"http://"]) {
			NSEnumerator *pluginEnum = [plugins objectEnumerator];
			id <GrowlTunesPlugin> plugin;
			while (!artwork && (plugin = [pluginEnum nextObject])) {
				artwork = [plugin artworkForTitle:track
										 byArtist:artist
										  onAlbum:album
									isCompilation:(compilation ? compilation : NO)];
				if (artwork && [plugin usesNetwork]) {
					[archivePlugin archiveImage:artwork	track:track artist:artist album:album compilation:compilation];
				}
			}
		}

		if (!artwork) {
			if (!error && !![newTrackURL hasPrefix:@"http://"]) {
				NSLog(@"Error getting artwork: %@", [error objectForKey:NSAppleScriptErrorMessage]);
				if ([plugins count]) NSLog(@"No plug-ins found anything either, or you wouldn't have this message.");
			}

			// Use the iTunes icon instead
			artwork = [[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes"];
			[artwork setSize:NSMakeSize(128.0f, 128.0f)];
		}
		if ([newTrackURL hasPrefix:@"http://"]) {
			//If we're streaming music, display only the name of the station and genre
			displayString = [NSString stringWithFormat:NSLocalizedString(@"Display-string format for streams", /*comment*/ nil), [userInfo objectForKey:@"Genre"]];
		} else {
			if (!artist) artist = @"";
			if (!album)  album  = @"";
			displayString = [NSString stringWithFormat:NSLocalizedString(@"Display-string format", /*comment*/ nil), length, ratingString, artist, album];
		}

		// Tell Growl
		NSDictionary *noteDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			(state == itPLAYING ? ITUNES_TRACK_CHANGED : ITUNES_PLAYING), GROWL_NOTIFICATION_NAME,
			appName,       GROWL_APP_NAME,
			track,         GROWL_NOTIFICATION_TITLE,
			displayString, GROWL_NOTIFICATION_DESCRIPTION,
			[artwork TIFFRepresentation], GROWL_NOTIFICATION_ICON,
			nil];
		[GrowlApplicationBridge notifyWithDictionary:noteDict];
		[noteDict release];

		// set up us some state for next time
		state = newState;
		[trackURL release];
		trackURL = [newTrackURL retain];

		// Recent Tracks
		[self addTuneToRecentTracks:track fromPlaylist:playlistName];
	}
}

#pragma mark Poll timer

- (void) poll:(NSTimer *)timer {
#pragma unused(timer)
	NSDictionary			* error = nil;
	NSAppleEventDescriptor	* theDescriptor = [pollScript executeAndReturnError:&error];
	NSAppleEventDescriptor  * curDescriptor;
	NSString				* playerState;
	iTunesState				newState = itUNKNOWN;
	int						newTrackID = -1;

	curDescriptor = [theDescriptor descriptorAtIndex:1L];
	playerState = [curDescriptor stringValue];

	if ([playerState isEqualToString:@"paused"]) {
		newState = itPAUSED;
	} else if ([playerState isEqualToString:@"stopped"]) {
		newState = itSTOPPED;
	} else {
		newState = itPLAYING;
		newTrackID = [curDescriptor int32Value];
	}

	if (state == itUNKNOWN) {
		state = newState;
		trackID = newTrackID;
		return;
	}

	if (newTrackID != 0 && trackID != newTrackID) { // this is different from previous note
		NSString		*track = nil;
		NSString		*length = nil;
		NSString		*artist = nil;
		NSString		*album = nil;
		BOOL			 compilation = NO;
		NSNumber		*rating = nil;
		NSString		*ratingString = nil;
		NSImage			*artwork = nil;
		NSDictionary	*noteDict;

		curDescriptor = [theDescriptor descriptorAtIndex:9L];
		playlistName = [curDescriptor stringValue];

		if ((curDescriptor = [theDescriptor descriptorAtIndex:2L]))
			track = [curDescriptor stringValue];

		if ((curDescriptor = [theDescriptor descriptorAtIndex:3L]))
			length = [curDescriptor stringValue];

		if ((curDescriptor = [theDescriptor descriptorAtIndex:4L]))
			artist = [curDescriptor stringValue];

		if ((curDescriptor = [theDescriptor descriptorAtIndex:5L]))
			album = [curDescriptor stringValue];

		if ((curDescriptor = [theDescriptor descriptorAtIndex:6L]))
			compilation = (BOOL)[curDescriptor booleanValue];

		if ((curDescriptor = [theDescriptor descriptorAtIndex:7L])) {
			int ratingInt = [[curDescriptor stringValue] intValue];
			if (ratingInt < 0) ratingInt = 0;
			rating = [NSNumber numberWithInt:ratingInt];
			ratingString = [self starsForRating:rating];
		}

		curDescriptor = [theDescriptor descriptorAtIndex:8L];
		const OSType type = [curDescriptor typeCodeValue];

		if (type != 'null') {
			artwork = [[[NSImage alloc] initWithData:[curDescriptor data]] autorelease];
		} else {
			NSEnumerator *pluginEnum = [plugins objectEnumerator];
			id <GrowlTunesPlugin> plugin;
			while (!artwork && (plugin = [pluginEnum nextObject])) {
				artwork = [plugin artworkForTitle:track
										 byArtist:artist
										  onAlbum:album
									isCompilation:compilation];
				if (artwork && [plugin usesNetwork]) {
					[archivePlugin archiveImage:artwork	track:track artist:artist album:album compilation:compilation];
				}
			}

		}

		if (!artwork) {
			if (!error) {
				NSLog(@"Error getting artwork: %@", [error objectForKey:NSAppleScriptErrorMessage]);
				if ([plugins count]) NSLog(@"No plug-ins found anything either, or you wouldn't have this message.");
			}

			// Use the iTunes icon instead
			artwork = [[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes"];
			[artwork setSize:NSMakeSize(128.0f, 128.0f)];
		}

		// Tell growl
		noteDict = [[NSDictionary alloc] initWithObjectsAndKeys:
			(state == itPLAYING ? ITUNES_TRACK_CHANGED : ITUNES_PLAYING), GROWL_NOTIFICATION_NAME,
			appName, GROWL_APP_NAME,
			track,   GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:@"%@ - %@\n%@\n%@",length,ratingString,artist,album], GROWL_NOTIFICATION_DESCRIPTION,
			(artwork ? [artwork TIFFRepresentation] : nil), GROWL_NOTIFICATION_ICON,
			nil];
		[GrowlApplicationBridge notifyWithDictionary:noteDict];
		[noteDict release];

		// set up us some state for next time
		state = newState;
		trackID = newTrackID;

		// Recent Tracks
		[self addTuneToRecentTracks:track fromPlaylist:playlistName];
	}
}

- (void) startTimer {
	if (!pollTimer) {
		pollTimer = [[NSTimer scheduledTimerWithTimeInterval:pollInterval
													  target:self
													selector:@selector(poll:)
													userInfo:nil
													 repeats:YES] retain];
		NSLog(@"%@", @"Polling started - upgrade to iTunes 4.7 or later already, would you?!");
		[self poll:nil];
	}
}

- (void) stopTimer {
	if (pollTimer){
		[pollTimer invalidate];
		[pollTimer release];
		pollTimer = nil;
		NSLog(@"%@", @"Polling stopped");
	}
}

#pragma mark Status item

- (void) createStatusItem {
	if (!statusItem) {
		NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
		statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
		if (statusItem) {
			[statusItem setMenu:[self statusItemMenu]];
			[statusItem setHighlightMode:YES];
			[statusItem setImage:[NSImage imageNamed:@"growlTunes.tif"]];
			[statusItem setAlternateImage:[NSImage imageNamed:@"growlTunes-selected.tif"]];
			[statusItem setToolTip:NSLocalizedString(@"Status item tooltip", /*comment*/ nil)];
		}
	}
}

- (void) tearDownStatusItem {
	if (statusItem) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem]; //otherwise we leave a hole
		[statusItem release];
		statusItem = nil;
	}
}

- (NSMenu *) statusItemMenu {
	NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"GrowlTunes"];
	if (menu) {
		id <NSMenuItem> item;
		NSString *empty = @""; //used for the key equivalent of all the menu items.

		item = [menu addItemWithTitle:@"Online Help" action:@selector(onlineHelp:) keyEquivalent:empty];
		[item setTarget:self];
		[item setTag:onlineHelpTag];
		[item setToolTip:NSLocalizedString(@"Status item Online Help item tooltip", /*comment*/ nil)];

		item = [NSMenuItem separatorItem];
		[menu addItem:item];

		item = [menu addItemWithTitle:@"iTunes" action:NULL keyEquivalent:empty];

		// Set us up a submenu
		[item setSubmenu:[self buildiTunesSubmenu]];

		// The rating submenu
		item = [menu addItemWithTitle:@"Rating" action:NULL keyEquivalent:empty];
		[item setSubmenu:[self buildRatingSubmenu]];

		// Back to our regularly scheduled Status Menu
		item = [NSMenuItem separatorItem];
		[menu addItem:item];

		item = [menu addItemWithTitle:@"Quit GrowlTunes" action:@selector(quitGrowlTunes:) keyEquivalent:empty];
		[item setTarget:self];
		[item setTag:quitGrowlTunesTag];
		item = [menu addItemWithTitle:@"Quit Both" action:@selector(quitBoth:) keyEquivalent:empty];
		[item setTarget:self];
		[item setTag:quitBothTag];
		[item setToolTip:NSLocalizedString(@"Status item Quit Both item tooltip", /*comment*/ nil)];

		if (polling) {
			item = [NSMenuItem separatorItem];
			[menu addItem:item];

			item = [menu addItemWithTitle:@"Toggle Polling" action:@selector(togglePolling:) keyEquivalent:empty];
			[item setTarget:self];
			[item setTag:togglePollingTag];
			[item setToolTip:NSLocalizedString(@"Status item Toggle Polling item tooltip", /*comment*/ nil)];
		}
	}

	return [menu autorelease];
}

- (IBAction) togglePolling:(id)sender {
#pragma unused(sender)
	if (pollTimer)
		[self stopTimer];
	else
		[self startTimer];
}

- (NSMenu *) buildiTunesSubmenu {
	id <NSMenuItem> item;
	if (!iTunesSubMenu)
		iTunesSubMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"iTunes"] autorelease];

	// Out with the old
	NSArray *items = [iTunesSubMenu itemArray];
	NSEnumerator *itemEnumerator = [items objectEnumerator];
	while ((item = [itemEnumerator nextObject])) {
		[iTunesSubMenu removeItem:item];
	}

	// In with the new
	item = [iTunesSubMenu addItemWithTitle:@"Recently Played Tunes" action:NULL keyEquivalent:@""];
	NSEnumerator *tunesEnumerator = [recentTracks objectEnumerator];
	NSDictionary *aTuneDict = nil;
	int k = 0;

	while ((aTuneDict = [tunesEnumerator nextObject])) {
		item = [iTunesSubMenu addItemWithTitle:[aTuneDict objectForKey:@"name"]
										action:@selector(jumpToTune:)
								 keyEquivalent:@""];
		[item setTarget:self];
		[item setIndentationLevel:1];
		[item setTag:k++];
		[item setToolTip:NSLocalizedString(@"Status item recent track tooltip", /*comment*/ nil)];
	}

	[iTunesSubMenu addItem:[NSMenuItem separatorItem]];
	item = [iTunesSubMenu addItemWithTitle:@"Launch iTunes" action:@selector(launchQuitiTunes:) keyEquivalent:@""];
	[item setTarget:self];
	[item setTag:launchQuitiTunesTag];
	//tooltip set by validateMenuItem

	return iTunesSubMenu;
}

- (NSMenu *) buildRatingSubmenu {
	id <NSMenuItem> item;
	if (!ratingSubMenu) {
		ratingSubMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"Rating"] autorelease];
		NSString *rating0 = [[NSString alloc] initWithUTF8String:"\xe2\x98\x86\xe2\x98\x86\xe2\x98\x86\xe2\x98\x86\xe2\x98\x86"];
		NSString *rating1 = [[NSString alloc] initWithUTF8String:"\xe2\x98\x85\xe2\x98\x86\xe2\x98\x86\xe2\x98\x86\xe2\x98\x86"];
		NSString *rating2 = [[NSString alloc] initWithUTF8String:"\xe2\x98\x85\xe2\x98\x85\xe2\x98\x86\xe2\x98\x86\xe2\x98\x86"];
		NSString *rating3 = [[NSString alloc] initWithUTF8String:"\xe2\x98\x85\xe2\x98\x85\xe2\x98\x85\xe2\x98\x86\xe2\x98\x86"];
		NSString *rating4 = [[NSString alloc] initWithUTF8String:"\xe2\x98\x85\xe2\x98\x85\xe2\x98\x85\xe2\x98\x85\xe2\x98\x86"];
		NSString *rating5 = [[NSString alloc] initWithUTF8String:"\xe2\x98\x85\xe2\x98\x85\xe2\x98\x85\xe2\x98\x85\xe2\x98\x85"];
		item = [ratingSubMenu addItemWithTitle:rating0 action:@selector(setRating:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:ratingTag+0];
		item = [ratingSubMenu addItemWithTitle:rating1 action:@selector(setRating:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:ratingTag+1];
		item = [ratingSubMenu addItemWithTitle:rating2 action:@selector(setRating:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:ratingTag+2];
		item = [ratingSubMenu addItemWithTitle:rating3 action:@selector(setRating:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:ratingTag+3];
		item = [ratingSubMenu addItemWithTitle:rating4 action:@selector(setRating:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:ratingTag+4];
		item = [ratingSubMenu addItemWithTitle:rating5 action:@selector(setRating:) keyEquivalent:@""];
		[item setTarget:self];
		[item setTag:ratingTag+5];
		[rating0 release];
		[rating1 release];
		[rating2 release];
		[rating3 release];
		[rating4 release];
		[rating5 release];
	}

	return ratingSubMenu;
}
	
- (BOOL) validateMenuItem:(NSMenuItem *)item {
	BOOL retVal = YES;

	switch ([item tag]) {
		case launchQuitiTunesTag:
			if ([self iTunesIsRunning])
				[item setTitle:@"Quit iTunes"];
			else
				[item setTitle:@"Launch iTunes"];
			break;

		case quitBothTag:
			retVal = [self iTunesIsRunning];
			break;

		case togglePollingTag:
			if (pollTimer) {
				[item setTitle:@"Stop Polling"];
				[item setToolTip:NSLocalizedString(@"Status item Stop Polling item tooltip", /*comment*/ nil)];
			} else {
				[item setTitle:@"Start Polling"];
				[item setToolTip:NSLocalizedString(@"Status item Start Polling item tooltip", /*comment*/ nil)];
			}

		case quitGrowlTunesTag:
		case onlineHelpTag:
			break;
	}

	return retVal;
}

- (IBAction) onlineHelp:(id)sender{
#pragma unused(sender)
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ONLINE_HELP_URL]];
}

- (void) addTuneToRecentTracks:(NSString *)inTune fromPlaylist:(NSString *)inPlaylist {
	NSNumber *recentTrackCountNum = [[NSUserDefaults standardUserDefaults] objectForKey:recentTrackCount];
	unsigned trackLimit = recentTrackCountNum ? [recentTrackCountNum unsignedIntValue] : defaultRecentTracksLimit;
	NSDictionary *tuneDict = [[NSDictionary alloc] initWithObjectsAndKeys:
		inTune,     @"name",
		inPlaylist, @"playlist",
		nil];
	signed long delta = ([recentTracks count] + 1U) - (signed long)trackLimit;
	if (delta > 0L)
		[recentTracks removeObjectsInRange:NSMakeRange(0U, delta)];
	[recentTracks addObject:tuneDict];
	[tuneDict release];

	if (![[NSUserDefaults standardUserDefaults] boolForKey:noMenuKey])
		[self buildiTunesSubmenu];
}

- (IBAction) quitGrowlTunes:(id)sender {
	[NSApp terminate:sender];
}

- (IBAction) launchQuitiTunes:(id)sender {
#pragma unused(sender)
	if (![self quitiTunes]) {
		//quit failed, so it wasn't running: launch it.
		[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:iTunesBundleID
															 options:NSWorkspaceLaunchDefault
									  additionalEventParamDescriptor:nil
													launchIdentifier:NULL];
	}
}

- (IBAction) quitBoth:(id)sender {
	[self quitiTunes];
	[self quitGrowlTunes:sender];
}

- (BOOL) quitiTunes {
	NSDictionary *iTunes = [self iTunesProcess];
	BOOL success = (iTunes != nil);
	if (success) {
		//first disarm the timer. we don't want to launch iTunes right after we quit it if the timer fires.
		[self stopTimer];

		//now quit iTunes.
		NSAppleEventDescriptor *target = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplicationBundleID data:[iTunesBundleID dataUsingEncoding:NSUTF8StringEncoding]];
		NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass
		                                                                         eventID:kAEQuitApplication
		                                                                targetDescriptor:target
		                                                                        returnID:kAutoGenerateReturnID
		                                                                   transactionID:kAnyTransactionID];
		OSStatus err = AESend([event aeDesc],
		                      /*reply*/ NULL,
		                      /*sendMode*/ kAENoReply | kAEDontReconnect | kAENeverInteract | kAEDontRecord,
		                      kAENormalPriority,
		                      kAEDefaultTimeout,
		                      /*idleProc*/ NULL,
		                      /*filterProc*/ NULL);
		success = ((err == noErr) || (err == procNotFound));
		if (!success) {
			//XXX this should be an alert panel (with a better message)
			NSLog(@"Could not quit iTunes: AESend returned %li", (long)err);
		}
	}
	return success;
}

- (IBAction) setRating:(id)sender {
	int rating = ([sender tag] - ratingTag) * 20;
	NSString *ratingScript = [[NSString alloc] initWithFormat:@"tell application \"iTunes\" to set rating of current track to %d", rating];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:ratingScript];
	[as executeAndReturnError:NULL];
	[as release];
	[ratingScript release];
}

#pragma mark AppleScript

- (NSAppleScript *) appleScriptNamed:(NSString *)name {
	NSURL			*url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:name ofType:@"scpt"]];
	NSDictionary	*error;

	return [[NSAppleScript alloc] initWithContentsOfURL:url error:&error];
}

- (BOOL) iTunesIsRunning {
	return [self iTunesProcess] != nil;
}
- (NSDictionary *) iTunesProcess {
	NSEnumerator *processesEnum = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	NSDictionary *process;

	while ((process = [processesEnum nextObject])) {
		if ([iTunesBundleID caseInsensitiveCompare:[process objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
			break; //this is iTunes!
	}

	return process;
}

- (void) jumpToTune:(id) sender {
	NSDictionary *tuneDict = [recentTracks objectAtIndex:[sender tag]];
	NSString *jumpScript = [[NSString alloc] initWithFormat:@"tell application \"iTunes\"\nplay track \"%@\" of playlist \"%@\"\nend tell",
									[tuneDict objectForKey:@"name"],
									[tuneDict objectForKey:@"playlist"]];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource:jumpScript];
	[as executeAndReturnError:NULL];
	[as release];
	[jumpScript release];
}

- (void) handleAppLaunch:(NSNotification *)notification {
	if ([iTunesBundleID caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
		[self startTimer];
}

- (void) handleAppQuit:(NSNotification *)notification {
	if ([iTunesBundleID caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
		[self stopTimer];
}

#pragma mark Plug-ins

// This function is used to sort plugins, trying first the local ones, and then the network ones
static int comparePlugins(id <GrowlTunesPlugin> plugin1, id <GrowlTunesPlugin> plugin2, void *context) {
#pragma unused(context)
	BOOL b1 = [plugin1 usesNetwork];
	BOOL b2 = [plugin2 usesNetwork];
	if (b2 && !b1) //b1 is local; b2 is network
		return NSOrderedAscending;
	else if (b1 && !b2) //b1 is network; b2 is local
		return NSOrderedDescending;
	else //both have the same behaviour
		return NSOrderedAscending;
}

- (NSMutableArray *) loadPlugins {
	NSMutableArray *newPlugins = [[NSMutableArray alloc] init];
	NSMutableArray *lastPlugins = [[NSMutableArray alloc] init];
	if (newPlugins) {
		NSBundle *myBundle = [NSBundle mainBundle];
		NSString *pluginsPath = [myBundle builtInPlugInsPath];
		NSString *applicationSupportPath = [@"~/Library/Application Support/GrowlTunes/Plugins" stringByExpandingTildeInPath];
		NSArray *loadPathsArray = [NSArray arrayWithObjects:pluginsPath, applicationSupportPath, nil];
		NSEnumerator *loadPathsEnum = [loadPathsArray objectEnumerator];
		NSString *loadPath;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		static NSString *pluginPathExtension = @"plugin";

		while ((loadPath = [loadPathsEnum nextObject])) {
			NSEnumerator *pluginEnum = [[[NSFileManager defaultManager] directoryContentsAtPath:loadPath] objectEnumerator];
			NSString *curPath;

			while ((curPath = [pluginEnum nextObject])) {
				if ([[curPath pathExtension] isEqualToString:pluginPathExtension]) {
					curPath = [pluginsPath stringByAppendingPathComponent:curPath];
					NSBundle *plugin = [NSBundle bundleWithPath:curPath];

					if ([plugin load]) {
						Class principalClass = [plugin principalClass];

						if ([principalClass conformsToProtocol:@protocol(GrowlTunesPlugin)]) {
							id instance = [[principalClass alloc] init];
							[newPlugins addObject:instance];

							if (!archivePlugin && ([principalClass conformsToProtocol:@protocol(GrowlTunesPluginArchive)])) {
								archivePlugin = [instance retain];
//								NSLog(@"plug-in %@ is archive-Plugin with id %p", [curPath lastPathComponent], instance);
							}
							[instance release];
//							NSLog(@"Loaded plug-in \"%@\" with id %p", [curPath lastPathComponent], instance);
						} else {
							NSLog(@"Loaded plug-in \"%@\" does not conform to protocol", [curPath lastPathComponent]);
						}
					} else {
						NSLog(@"Could not load plug-in \"%@\"", [curPath lastPathComponent]);
					}
				}
			}
		}

		[pool release];
		[newPlugins addObjectsFromArray:lastPlugins];
		[lastPlugins release];
		[newPlugins autorelease];
	}
	// sort the plugins, putting the one that uses network last
	return (NSMutableArray *)[newPlugins sortedArrayUsingFunction:comparePlugins context:NULL];
}

@end

@implementation NSObject(GrowlTunesDummyPlugin)

- (NSImage *)artworkForTitle:(NSString *)track
					byArtist:(NSString *)artist
					 onAlbum:(NSString *)album
			   isCompilation:(BOOL)compilation
{
#pragma unused(track,artist,album,compilation)
	NSLog(@"Dummy plug-in %p called for artwork", self);
	return nil;
}

@end
