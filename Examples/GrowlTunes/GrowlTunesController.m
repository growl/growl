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
static NSString *recentTrackCount = @"Recent Tracks Count";

//status item menu item tags.
enum {
	onlineHelpTag = -5,
	quitGrowlTunesTag,
	launchQuitiTunesTag,
	quitBothTag,
	togglePollingTag,
};

@protocol GrowlTunesPlugin

//shuts up a warning gooder.
- (NSImage *)artworkForTitle:(NSString *)track
					byArtist:(NSString *)artist
					 onAlbum:(NSString *)album;

@end

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
		plugins = [[self loadPlugins] retain];
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

- (void)applicationWillFinishLaunching: (NSNotification *)notification {
	pollScript       = [self appleScriptNamed:@"jackItunesInfo"];
	quitiTunesScript = [self appleScriptNamed:@"quitiTunes"];
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

	[self createStatusItem];
}

- (void)dealloc {
	[self tearDownStatusItem];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[self stopTimer];
	
	[pollScript release];
	[playlistName release];
	[recentTracks release];

	[plugins release];

	[super dealloc];
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
		NSNumber		*rating = nil;
		NSString		*ratingString = nil;
		NSImage			*artwork = nil;
		NSDictionary	*noteDict;
		
		curDescriptor = [theDescriptor descriptorAtIndex:8];
		playlistName = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:2] )
			track = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:3] )
			length = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:4] )
			artist = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:5] )
			album = [curDescriptor stringValue];
		
		if ( curDescriptor = [theDescriptor descriptorAtIndex:6] ) {
			int ratingInt = [[curDescriptor stringValue] intValue];
			rating = [NSNumber numberWithInt:ratingInt]; 
			
			switch ( ratingInt / 20 ) {
				case 0:
					ratingString = [NSString stringWithUTF8String:"☆☆☆☆☆"];
					break;
				case 1:
					ratingString = [NSString stringWithUTF8String:"★☆☆☆☆"];
					break;
				case 2:
					ratingString = [NSString stringWithUTF8String:"★★☆☆☆"];
					break;
				case 3:
					ratingString = [NSString stringWithUTF8String:"★★★☆☆"];
					break;
				case 4:
					ratingString = [NSString stringWithUTF8String:"★★★★☆"];
					break;
				case 5:
					ratingString = [NSString stringWithUTF8String:"★★★★★"];
					break;
			}
		}
		
		curDescriptor = [theDescriptor descriptorAtIndex:7];
		const OSType type = [curDescriptor typeCodeValue];
		
		if( type != 'null' ) {
			artwork = [[[NSImage alloc] initWithData:[curDescriptor data]] autorelease];
		} else {
			NSEnumerator *pluginEnum = [plugins objectEnumerator];
			id <GrowlTunesPlugin> plugin;
			while ( !artwork && ( plugin = [pluginEnum nextObject] ) ) {
				artwork = [plugin artworkForTitle:track
										 byArtist:artist
										  onAlbum:album];
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
			
		// set us up some state for next time
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

	}

	return [menu autorelease];
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
	item = [iTunesSubMenu addItemWithTitle:@"Recent Tunes" action:NULL keyEquivalent:@""];
	NSEnumerator *tunesEnumerator = [recentTracks objectEnumerator];
	NSDictionary *aTuneDict = nil;
	int k = 0;
	
	while ( aTuneDict = [tunesEnumerator nextObject] ) {
		item = [iTunesSubMenu addItemWithTitle:[aTuneDict objectForKey:@"name"]
										action:@selector(jumpToTune:) 
								 keyEquivalent:@""];
		[item setTarget:self];
		[item setIndentationLevel:1];
		[item setTag:k];
		k++;
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

- (NSMutableArray *)loadPlugins {
	NSMutableArray *newPlugins = [[NSMutableArray alloc] init];
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
					id instance = [[[[plugin principalClass] alloc] init] autorelease];
					[newPlugins addObject:instance];
					NSLog(@"Loaded plug-in \"%@\" with id %p", [curPath lastPathComponent], instance);
				}
			}
		}

		[pool release];
		[newPlugins autorelease];
	}
	return newPlugins;
}

@end

@implementation NSObject(GrowlTunesDummyPlugin)

- (NSImage *)artworkForTitle:(NSString *)track
					byArtist:(NSString *)artist
					 onAlbum:(NSString *)album
{
	NSLog(@"Dummy plug-in %p called for artwork", self);
	return nil;
}

@end
