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
#import "GrowlDefines.h"
#import <GrowlAppBridge/GrowlApplicationBridge.h>
#import "NSGrowlAdditions.h"

#define ONLINE_HELP_URL		    @"http://growl.info/documentation/growltunes.php"

#define EXTENSION_GROWLTUNES_TRACK_LENGTH  @"Extended Info - GrowlTunes Track Length"
#define EXTENSION_GROWLTUNES_TRACK_RATING  @"Extended Info - GrowlTunes Track Rating"

// sticking this here for a bit of version checking while setting the menu icon
#ifndef NSAppKitVersionNumber10_2
#define NSAppKitVersionNumber10_2 663
#endif

@interface GrowlTunesController (PRIVATE)
- (NSAppleScript *)appleScriptNamed:(NSString *)name;
- (void) addTuneToRecentTracks:(NSString *)inTune fromPlaylist:(NSString *)inPlaylist;
- (NSMenu *) buildiTunesMenu;
- (void) jumpToTune:(id) sender;
@end

static NSString *appName		= @"GrowlTunes";
static NSString *iTunesAppName	= @"iTunes.app";
static NSString *iTunesBundleID = @"com.apple.itunes";

static NSString *pollIntervalKey = @"Poll interval";
static NSString *noMenuKey = @"GrowlTunesWithoutMenu";
static NSString *recentTrackCount = @"Recent Tracks Count";

//status item menu item tags.
enum {
	onlineHelpTag = -5,
	quitGrowlTunesTag,
	launchQuitiTunesTag,
	quitBothTag,
	togglePollingTag,
};

@implementation GrowlTunesController

- (id)init {
	self = [super init];

	if(self) {
		[GrowlAppBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(registerGrowl:) context:NULL];
		

		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithDouble:DEFAULT_POLL_INTERVAL], pollIntervalKey,
			[NSNumber numberWithInt:20], recentTrackCount,
			nil]];
		
		state = itUNKNOWN;
		playlistName = [[NSString alloc] init];
		recentTracks = [[NSMutableArray alloc] init];
		archivePlugin = nil;
		plugins = [[self loadPlugins] retain];
		trackID = 0;
		trackURL = @"";
	}
	
	return self;
}

- (void)registerGrowl:(void *)context {
	NSArray			* allNotes = [NSArray arrayWithObjects: 
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

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION object:nil userInfo:regDict];
}

- (void)setPolling:(BOOL)flag {
	_polling = flag;
}

- (void)applicationWillFinishLaunching: (NSNotification *)notification {
	pollScript       = [self appleScriptNamed:@"jackItunesInfo"];
	quitiTunesScript = [self appleScriptNamed:@"quitiTunes"];
	getInfoScript = [self appleScriptNamed:@"jackItunesArtwork"];
	
	if (_polling) {
		pollInterval = [[NSUserDefaults standardUserDefaults] floatForKey:pollIntervalKey];
	
		if( [self iTunesIsRunning] ) [self startTimer];
	
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
- (void)applicationWillTerminate:(NSNotification *)notification {
	[self release]; //the one in main() is never reached, and we have some important things in -dealloc.
}

- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[self stopTimer];
	[self tearDownStatusItem];
	
	[pollScript release];
	[playlistName release];
	[recentTracks release];

	[plugins release];
	if (archivePlugin)
		[archivePlugin release];

	[super dealloc];
}

#pragma mark -

- (NSString *)starsForRating:(unsigned)rating {
	enum {
		BLACK_STAR = 0x2605, WHITE_STAR = 0x2606,
		numStars = 5,
	};
	unichar stars[2] = { WHITE_STAR, BLACK_STAR };
	unichar starBuffer[numStars] = {
		stars[rating >=  20],
		stars[rating >=  40],
		stars[rating >=  60],
		stars[rating >=  80],
		stars[rating >= 100],
	};
	return [NSString stringWithCharacters:starBuffer length:numStars];
}

- (void)songChanged:(NSNotification *)aNotification {
	NSString				* playerState = nil;
	iTunesState				newState = itUNKNOWN;
	NSString				* newTrackURL = nil;
	NSDictionary			* userInfo = [aNotification userInfo];
	
	playerState = [[aNotification userInfo] objectForKey:@"Player State"];
	if ( [playerState isEqualToString:@"Paused"] ) {
		newState = itPAUSED;
	} else if( [playerState isEqualToString:@"Stopped"] ) {
		newState = itSTOPPED;
	} else {
		newState = itPLAYING;
		// For radios and files, the ID is the location.
		// While on the iTMS, it's the Store URL
		// For Rendezvous shares we're gonna hash a compilation of a bunch of info
		if ([userInfo objectForKey:@"Location"]) {
			newTrackURL = [userInfo objectForKey:@"Location"];
		} else if ([userInfo objectForKey:@"Store URL"]) {
			newTrackURL = [userInfo objectForKey:@"Store URL"];
		} else {
			// Lets make a hash out of all the info we can, but do it such that the empty fields
			// are blank rather than (null)
			// Then lets hash it ans turn that into our identifier string
			// That way a track name of "file://foo" won't confuse our code later on
			NSArray *args = [userInfo objectsForKeys:
				[NSArray arrayWithObjects:@"Name", @"Artist", @"Album", @"Composer", @"Genre",
					@"Year",@"Track Number", @"Track Count", @"Disc Number", @"Disc Count",
					@"Total Time", nil]
									  notFoundMarker:@""];
			newTrackURL = [NSString stringWithFormat:@"%@|%@|%@|%@|%@|%@|%@|%@|%@|%@|%@",
				[args objectAtIndex:0], [args objectAtIndex:1], [args objectAtIndex:2],
				[args objectAtIndex:3], [args objectAtIndex:4], [args objectAtIndex:5],
				[args objectAtIndex:6], [args objectAtIndex:7], [args objectAtIndex:8],
				[args objectAtIndex:9], [args objectAtIndex:10]];
			newTrackURL = [[NSNumber numberWithUnsignedLong:[newTrackURL hash]] stringValue];
		}
	}
	
	if( newTrackURL && ![newTrackURL isEqualToString:trackURL] ) { // this is different from previous note
		NSString		*track = nil;
		NSString		*length = nil;
		NSString		*artist = @"";
		NSString		*album = @"";
		BOOL			compilation = NO;
		NSNumber		*rating = nil;
		NSString		*ratingString = nil;
		NSImage			*artwork = nil;
		NSString		*displayString = nil;
		NSDictionary	*noteDict;
		NSDictionary	*error = nil;
		
		if ([userInfo objectForKey:@"Artist"])
			artist = [userInfo objectForKey:@"Artist"];
		if ([userInfo objectForKey:@"Album"])
			album = [userInfo objectForKey:@"Album"];
		track = [userInfo objectForKey:@"Name"];
		
		length = [userInfo objectForKey:@"Total Time"];
		// need to format a bit the length as it is returned in ms
		int lv = [length intValue];
		int min = lv/60000;
		int sec = lv/1000 - 60*min;
		length = [NSString stringWithFormat:@"%d:%02d", min, sec];
		
		if ([userInfo objectForKey:@"Compilation"])
			compilation = YES;
		
		if ([newTrackURL hasPrefix:@"file:/"]) {
			NSAppleEventDescriptor	* theDescriptor = [getInfoScript executeAndReturnError:&error];
			NSAppleEventDescriptor  * curDescriptor;

			int ratingInt = [[userInfo objectForKey:@"Rating"] intValue];
			rating = [NSNumber numberWithInt:ratingInt];
			if(ratingInt < 0) ratingInt = 0;
			ratingString = [self starsForRating:ratingInt];

			curDescriptor = [theDescriptor descriptorAtIndex:2];
			playlistName = [curDescriptor stringValue];
			curDescriptor = [theDescriptor descriptorAtIndex:1];
			const OSType type = [curDescriptor typeCodeValue];
		
			if( type != 'null' ) {
				artwork = [[[NSImage alloc] initWithData:[curDescriptor data]] autorelease];
			}
		} 
		
		//get artwork via plugins if needed (for file:/ and itms:/ id only)
		if (!artwork && ![newTrackURL hasPrefix:@"http://"]) {
				NSEnumerator *pluginEnum = [plugins objectEnumerator];
				id <GrowlTunesPlugin> plugin;
				while ( !artwork && ( plugin = [pluginEnum nextObject] ) ) {
					artwork = [plugin artworkForTitle:track
											byArtist:artist
											onAlbum:album
										isCompilation:(compilation ? compilation : NO)];
					if (artwork && [plugin usesNetwork]) {
						[archivePlugin archiveImage:artwork	track:track artist:artist album:album compilation:compilation];
					}
				}
			
			}
		
		if( !artwork ) {
			if ( !error && !![newTrackURL hasPrefix:@"http://"]) {
				NSLog(@"Error getting artwork: %@", [error objectForKey:NSAppleScriptErrorMessage]);
				if ( [plugins count] ) NSLog(@"No plug-ins found anything either, or you wouldn't have this message.");
			}
			
			// Use the iTunes icon instead
			artwork = [[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes"];
			[artwork setSize:NSMakeSize( 128.0, 128.0 )];
		}
		if ([newTrackURL hasPrefix:@"http://"]) { //If we're streaming music, display only the name of the station and genre
			displayString = [NSString stringWithFormat:@"%@",[userInfo objectForKey:@"Genre"]];
		} else if ([newTrackURL hasPrefix:@"itms:/"]) {
			displayString = [NSString stringWithFormat:@"%@\n%@",artist,album];
		} else if ([newTrackURL hasPrefix:@"file://"]) {
			displayString = [NSString stringWithFormat:@"%@ - %@\n%@\n%@",length,ratingString,artist,album];
		} else {
			displayString = [NSString stringWithFormat:@"%@\n%@\n%@", length, artist, album];
		}
		// Tell growl
		noteDict = [NSDictionary dictionaryWithObjectsAndKeys:
			( state == itPLAYING ? ITUNES_TRACK_CHANGED : ITUNES_PLAYING ), GROWL_NOTIFICATION_NAME,
			appName, GROWL_APP_NAME,
			track, GROWL_NOTIFICATION_TITLE,
			displayString, GROWL_NOTIFICATION_DESCRIPTION,
					  artwork ? [artwork TIFFRepresentation] : nil, GROWL_NOTIFICATION_ICON,
			length, EXTENSION_GROWLTUNES_TRACK_LENGTH,
			rating, EXTENSION_GROWLTUNES_TRACK_RATING,
			nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:noteDict];
		
		// set up us some state for next time
		state = newState;
		[trackURL release];
		trackURL = [newTrackURL retain];
		
		// Recent Tracks
		[self addTuneToRecentTracks:track fromPlaylist:playlistName];
	}
}

#pragma mark Poll timer

- (void)poll:(NSTimer *)timer {
	NSDictionary			* error = nil;
	NSAppleEventDescriptor	* theDescriptor = [pollScript executeAndReturnError:&error];
	NSAppleEventDescriptor  * curDescriptor;
	NSString				* playerState;
	iTunesState				newState = itUNKNOWN;
	int						newTrackID = -1;
	
	curDescriptor = [theDescriptor descriptorAtIndex:1];
	playerState = [curDescriptor stringValue];
	
	if ( [playerState isEqualToString:@"paused"] ) {
		newState = itPAUSED;
	} else if( [playerState isEqualToString:@"stopped"] ) {
		newState = itSTOPPED;
	} else {
		newState = itPLAYING;
		newTrackID = [curDescriptor int32Value];
	}
	
	if(state == itUNKNOWN) {
		state = newState;
		trackID = newTrackID;
		return;
	}
	
	if( newTrackID != 0 && trackID != newTrackID ) { // this is different from previous note
		NSString		*track = nil;
		NSString		*length = nil;
		NSString		*artist = nil;
		NSString		*album = nil;
		BOOL			 compilation = NO;
		NSNumber		*rating = nil;
		NSString		*ratingString = nil;
		NSImage			*artwork = nil;
		NSDictionary	*noteDict;
		
		curDescriptor = [theDescriptor descriptorAtIndex:9];
		playlistName = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:2] )
			track = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:3] )
			length = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:4] )
			artist = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:5] )
			album = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:6] )
			compilation = (BOOL)[curDescriptor booleanValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:7] ) {
			int ratingInt = [[curDescriptor stringValue] intValue];
			rating = [NSNumber numberWithInt:ratingInt];
			if(rating < 0) rating = 0;
			ratingString = [self starsForRating:ratingInt];
		}
		
		curDescriptor = [theDescriptor descriptorAtIndex:8];
		const OSType type = [curDescriptor typeCodeValue];
		
		if( type != 'null' ) {
			artwork = [[[NSImage alloc] initWithData:[curDescriptor data]] autorelease];
		} else {
			NSEnumerator *pluginEnum = [plugins objectEnumerator];
			id <GrowlTunesPlugin> plugin;
			while ( !artwork && ( plugin = [pluginEnum nextObject] ) ) {
				artwork = [plugin artworkForTitle:track
										 byArtist:artist
										  onAlbum:album
									isCompilation:compilation];
				if (artwork && [plugin usesNetwork]) {
					[archivePlugin archiveImage:artwork	track:track artist:artist album:album compilation:compilation];
				}
			}
			
		}
		
		if( !artwork ) {
			if ( !error ) {
				NSLog(@"Error getting artwork: %@", [error objectForKey:NSAppleScriptErrorMessage]);
				if ( [plugins count] ) NSLog(@"No plug-ins found anything either, or you wouldn't have this message.");
			}
			
			// Use the iTunes icon instead
			artwork = [[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes"];
			[artwork setSize:NSMakeSize( 128.0, 128.0 )];
		}
		
		// Tell growl
		noteDict = [NSDictionary dictionaryWithObjectsAndKeys:
			( state == itPLAYING ? ITUNES_TRACK_CHANGED : ITUNES_PLAYING ), GROWL_NOTIFICATION_NAME,
			appName, GROWL_APP_NAME,
			track, GROWL_NOTIFICATION_TITLE,
			[NSString stringWithFormat:@"%@ - %@\n%@\n%@",length,ratingString,artist,album], GROWL_NOTIFICATION_DESCRIPTION,
					  artwork ? [artwork TIFFRepresentation] : nil, GROWL_NOTIFICATION_ICON,
			length, EXTENSION_GROWLTUNES_TRACK_LENGTH,
			rating, EXTENSION_GROWLTUNES_TRACK_RATING,
			nil];
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_NOTIFICATION
																	   object:nil
																	 userInfo:noteDict];
			
		// set up us some state for next time
		state = newState;
		trackID = newTrackID;
		
		// Recent Tracks
		[self addTuneToRecentTracks:track fromPlaylist:playlistName];
	}
}

- (void)startTimer {
	if(pollTimer == nil) {
		pollTimer = [[NSTimer scheduledTimerWithTimeInterval:pollInterval 
													  target:self
													selector:@selector(poll:)
													userInfo:nil
													 repeats:YES] retain];
		NSLog(@"Polling started");
		[self poll:nil];
	}
}

- (void)stopTimer {
	if(pollTimer){
		[pollTimer invalidate];
		[pollTimer release];
		pollTimer = nil;
		NSLog(@"Polling stopped");
	}
}

#pragma mark Status item

- (void)createStatusItem {
	if(!statusItem) {
		NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
		statusItem = [[statusBar statusItemWithLength:NSSquareStatusItemLength] retain];
		if(statusItem) {
			[statusItem setMenu:[self statusItemMenu]];
            
			[statusItem setHighlightMode:YES];
			[statusItem setImage:[NSImage imageNamed:@"growlTunes.tif"]];
            if(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_2)  {
              [statusItem setAlternateImage:[NSImage imageNamed:@"growlTunes-selected.tif"]];
            }
		}
	}
}

- (void)tearDownStatusItem {
	if(statusItem) {
		[[NSStatusBar systemStatusBar] removeStatusItem:statusItem]; //otherwise we leave a hole
		[statusItem release];
		statusItem = nil;
	}
}

- (NSMenu *)statusItemMenu {
	NSMenu *menu = [[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"GrowlTunes"];
	if(menu) {
		id <NSMenuItem> item;
		NSString *empty = @""; //used for the key equivalent of all the menu items.

		item = [menu addItemWithTitle:@"Online Help" action:@selector(onlineHelp:) keyEquivalent:empty];
		[item setTarget:self];
		[item setTag:onlineHelpTag];

		item = [NSMenuItem separatorItem];
		[menu addItem:item];

		item = [menu addItemWithTitle:@"iTunes" action:NULL keyEquivalent:empty];
		
		// Set us up a submenu
		[item setSubmenu:[self buildiTunesMenu]];
		
		// Back to our regularly scheduled Status Menu
		item = [NSMenuItem separatorItem];
		[menu addItem:item];
		
		item = [menu addItemWithTitle:@"Quit GrowlTunes" action:@selector(quitGrowlTunes:) keyEquivalent:empty];
		[item setTarget:self];
		[item setTag:quitGrowlTunesTag];
		item = [menu addItemWithTitle:@"Quit Both" action:@selector(quitBoth:) keyEquivalent:empty];
		[item setTarget:self];
		[item setTag:quitBothTag];
		
		if (_polling) {
			item = [NSMenuItem separatorItem];
			[menu addItem:item];
			
			item = [menu addItemWithTitle:@"Toggle Polling" action:@selector(togglePolling:) keyEquivalent:empty];
			[item setTarget:self];
			[item setTag:togglePollingTag];
		}
	}

	return [menu autorelease];
}

- (IBAction)togglePolling:(id)sender {
    if(pollTimer)
	[self stopTimer];
    else
	[self startTimer];
}

- (NSMenu *) buildiTunesMenu {
	id <NSMenuItem> item;
	if ( ! iTunesSubMenu ) 
		iTunesSubMenu = [[[NSMenu allocWithZone:[NSMenu menuZone]] initWithTitle:@"iTunes"] autorelease];
	
	// Out with the old
	NSArray *items = [iTunesSubMenu itemArray];
	NSEnumerator *itemEnumerator = [items objectEnumerator];
	while ( item = [itemEnumerator nextObject] ) {
		[iTunesSubMenu removeItem:item];
	}
	
	// In With The New
	item = [iTunesSubMenu addItemWithTitle:@"Recently Played Tunes" action:NULL keyEquivalent:@""];
	NSEnumerator *tunesEnumerator = [recentTracks objectEnumerator];
	NSDictionary *aTuneDict = nil;
	int k = 0;
	
	while ( aTuneDict = [tunesEnumerator nextObject] ) {
		item = [iTunesSubMenu addItemWithTitle:[aTuneDict objectForKey:@"name"]
										action:@selector(jumpToTune:) 
								 keyEquivalent:@""];
		[item setTarget:self];
		[item setIndentationLevel:1];
		[item setTag:k++];
	}
	
	[iTunesSubMenu addItem:[NSMenuItem separatorItem]];
	item = [iTunesSubMenu addItemWithTitle:@"Launch iTunes" action:@selector(launchQuitiTunes:) keyEquivalent:@""];
	[item setTarget:self];
	[item setTag:launchQuitiTunesTag];
	
	return iTunesSubMenu;
}


- (BOOL)validateMenuItem:(NSMenuItem *)item {
	BOOL retVal = YES;
	
	switch([item tag]) {
		case launchQuitiTunesTag:;
			if([self iTunesIsRunning])
				[item setTitle:@"Quit iTunes"];
			else
				[item setTitle:@"Launch iTunes"];
			break;
		case quitBothTag:
			retVal = [self iTunesIsRunning];
			break;
		case togglePollingTag:
			if(pollTimer)
				[item setTitle:@"Stop Polling"];
			else
				[item setTitle:@"Start Polling"];
			return YES;
		case quitGrowlTunesTag:
		case onlineHelpTag:
			retVal = YES;
			break;
		}
	
	return retVal;
}

- (IBAction)onlineHelp:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:ONLINE_HELP_URL]];
}
    
- (void) addTuneToRecentTracks:(NSString *)inTune fromPlaylist:(NSString *)inPlaylist {
	int trackLimit = [[[NSUserDefaults standardUserDefaults] objectForKey:recentTrackCount] intValue];
	NSDictionary *tuneDict = [NSDictionary dictionaryWithObjectsAndKeys:inTune, @"name",
																		inPlaylist, @"playlist", nil];
	[recentTracks addObject:tuneDict];
	if ( [recentTracks count] > trackLimit ) {
		int len = [recentTracks count] - trackLimit;
		[recentTracks removeObjectsInRange:NSMakeRange( 0, len )];
	}
	
	if (![[NSUserDefaults standardUserDefaults] boolForKey:noMenuKey])
		[self buildiTunesMenu];
}

- (IBAction)quitGrowlTunes:(id)sender {
	[NSApp terminate:sender];
}

- (IBAction)launchQuitiTunes:(id)sender {
	if(![self quitiTunes]) {
		//quit failed, so it wasn't running: launch it.
		[[NSWorkspace sharedWorkspace] launchApplication:iTunesAppName];
	}
}

- (IBAction)quitBoth:(id)sender {
	[self quitiTunes];
	[self quitGrowlTunes:sender];
}

- (BOOL)quitiTunes {
	NSDictionary *iTunes = [self iTunesProcess];
	BOOL success = (iTunes != nil);
	if(success) {
		//first disarm the timer. we don't want to launch iTunes right after we quit it if the timer fires.
		[self stopTimer];
		
		//now quit iTunes.
		NSDictionary *errorInfo = nil;
		[quitiTunesScript executeAndReturnError:&errorInfo];
	}
	return success;
}

#pragma mark AppleScript

- (NSAppleScript *)appleScriptNamed:(NSString *)name
{
	NSURL			* url;
	NSDictionary	* error;
	
	url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:name ofType:@"scpt"]];
	
	return [[NSAppleScript alloc] initWithContentsOfURL:url error:&error];
}

- (BOOL)iTunesIsRunning {
	return [self iTunesProcess] != nil;
}
- (NSDictionary *)iTunesProcess {
	NSEnumerator *processesEnum = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	NSDictionary *process;
	
	while(process = [processesEnum nextObject]) {
		if([iTunesBundleID caseInsensitiveCompare:[process objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
			break; //this is iTunes!
	}

	return process;
}

- (void) jumpToTune:(id) sender {
	NSDictionary *tuneDict = [recentTracks objectAtIndex:[sender tag]];
	NSString *jumpScript = [NSString stringWithFormat:@"tell application \"iTunes\"\nplay track \"%@\" of playlist \"%@\"\nend tell", 
									[tuneDict objectForKey:@"name"],
									[tuneDict objectForKey:@"playlist"]];
	NSAppleScript *as = [[[NSAppleScript alloc] initWithSource:jumpScript] autorelease];
	[as executeAndReturnError:NULL];
}

- (void)handleAppLaunch:(NSNotification *)notification {
	if([iTunesBundleID caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
		[self startTimer];
}
- (void)handleAppQuit:(NSNotification *)notification {
	if([iTunesBundleID caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
		[self stopTimer];
}

#pragma mark Plug-ins

// This function is used to sort plugins, trying first the local ones, and then the network ones
int comparePlugins(id <GrowlTunesPlugin> plugin1, id <GrowlTunesPlugin> plugin2, void *context) {
	BOOL b1 = [plugin1 usesNetwork];
	BOOL b2 = [plugin2 usesNetwork];
	if ((b1 && b2) || (!b1 && !b2)) //both plugins have the same behaviour
		return NSOrderedSame;
	else if (b1 && !b2) // b1 is using network but not b2 so plugin2 should be smaller than 1
		return NSOrderedDescending;
	else
		return NSOrderedAscending;
}

- (NSMutableArray *)loadPlugins {
	NSMutableArray *newPlugins = [[NSMutableArray alloc] init];
	NSMutableArray *lastPlugins = [[NSMutableArray alloc] init];
	if(newPlugins) {
		NSBundle *myBundle = [NSBundle mainBundle];
		NSString *pluginsPath = [myBundle builtInPlugInsPath];
		NSString *applicationSupportPath = [@"~/Library/Application Support/GrowlTunes/Plugins" stringByExpandingTildeInPath];
		NSArray *loadPathsArray = [NSArray arrayWithObjects:pluginsPath, applicationSupportPath, nil];
		NSEnumerator *loadPathsEnum = [loadPathsArray objectEnumerator];
		NSString *loadPath;
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		static NSString *pluginPathExtension = @"plugin";
		while (loadPath = [loadPathsEnum nextObject]) {
			NSEnumerator *pluginEnum = [[[NSFileManager defaultManager] directoryContentsAtPath:loadPath] objectEnumerator];
			NSString *curPath;
			while(curPath = [pluginEnum nextObject]) {
				if([[curPath pathExtension] isEqualToString:pluginPathExtension]) {
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
	NSLog(@"Dummy plug-in %p called for artwork", self);
	return nil;
}

@end
