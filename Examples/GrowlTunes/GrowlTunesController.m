//
//  GrowlTunesController.m
//  GrowlTunes
//
//  Created by Nelson Elhage on Mon Jun 21 2004.
//  Copyright (c) 2004 Nelson Elhage. All rights reserved.
//

#import "GrowlTunesController.h"
#import "GrowlDefines.h"
#import "GrowlApplicationBridge.h"
#import "NSGrowlAdditions.h"

@interface GrowlTunesController (PRIVATE)
- (NSAppleScript *)appleScriptNamed:(NSString *)name;
@end

static NSString *appName = @"GrowlTunes";
static NSString *iTunesBundleID = @"com.apple.itunes";

@implementation GrowlTunesController

- (id)init
{
	self = [super init];
	
	[GrowlApplicationBridge launchGrowlIfInstalledNotifyingTarget:self selector:@selector(registerGrowl:) context:NULL];
	state = itUNKNOWN;
	
	return self;
}

- (void)registerGrowl:(void *)context
{
	NSArray			* allNotes = [NSArray arrayWithObjects: 
		ITUNES_TRACK_CHANGED, 
//		ITUNES_PAUSED, 
//		ITUNES_STOPPED,
		ITUNES_PLAYING, 
		nil];
	NSImage			* iTunesIcon = [[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes.app"];
	NSDictionary	* regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		appName, GROWL_APP_NAME,
		[iTunesIcon TIFFRepresentation], GROWL_APP_ICON,
		allNotes, GROWL_NOTIFICATIONS_ALL,
		allNotes, GROWL_NOTIFICATIONS_DEFAULT,
		nil];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:GROWL_APP_REGISTRATION object:nil userInfo:regDict];
}

- (void)applicationWillFinishLaunching: (NSNotification *)notification
{
	pollScript = [self appleScriptNamed:@"polliTunes"];
	getTrackScript = [self appleScriptNamed:@"getTrack"];
	getArtistScript = [self appleScriptNamed:@"getArtist"];
	getArtworkScript = [self appleScriptNamed:@"getArtwork"];
	getAlbumScript = [self appleScriptNamed:@"getAlbum"];

	if([self iTunesIsRunning]) {
		pollTimer = [[NSTimer scheduledTimerWithTimeInterval:POLL_INTERVAL 
													  target:self
													selector:@selector(poll:)
													userInfo:nil
													 repeats:YES] retain];
		[self poll:nil];
	}

	NSNotificationCenter *workspaceCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[workspaceCenter addObserver:self
						selector:@selector(handleAppLaunch:)
							name:NSWorkspaceDidLaunchApplicationNotification
						  object:nil];
	[workspaceCenter addObserver:self
						selector:@selector(handleAppQuit:)
							name:NSWorkspaceDidTerminateApplicationNotification
						  object:nil];
}

- (void)poll: (NSTimer *)timer
{
	NSDictionary			* error;
	NSAppleEventDescriptor  * retVal;
	NSString				* playerState;
	iTunesState				newState;
	int						newTrackID = -1;
	
	retVal = [pollScript executeAndReturnError:&error];
	
	playerState = [retVal stringValue];

	if([playerState isEqualToString:@"paused"]) {
		newState = itPAUSED;
	} else if([playerState isEqualToString:@"stopped"]) {
		newState = itSTOPPED;
	} else {
		newState = itPLAYING;
		newTrackID = [retVal int32Value];
	}
	
	if(state == itUNKNOWN) {
		state = newState;
		trackID = newTrackID;
		return;
	}
	
	if(state != newState || trackID != newTrackID) {
		if(newState == itPLAYING) {
			if(state == itPLAYING || state == itSTOPPED) {
				NSString		* track = nil;
				NSString		* artist = nil;
				NSString		* album = nil;
				NSImage			* artwork = nil;
				NSDictionary	* noteDict;
				
				retVal = [getTrackScript executeAndReturnError:&error];
				if(retVal)
					track = [retVal stringValue];
				
				retVal = [getArtistScript executeAndReturnError:&error];
				if(retVal)
					artist = [retVal stringValue];
				
				retVal = [getAlbumScript executeAndReturnError:&error];
				if(retVal)
					album = [retVal stringValue];
				
				retVal = [getArtworkScript executeAndReturnError:&error];
				if(retVal)
					artwork = [[[NSImage alloc] initWithData:[retVal data]] autorelease];
				else
					NSLog(@"Error getting artwork: %@",[error objectForKey:NSAppleScriptErrorMessage]);
				
				noteDict = [NSDictionary dictionaryWithObjectsAndKeys:
									appName, GROWL_APP_NAME,
									track, GROWL_NOTIFICATION_TITLE,
									[NSString stringWithFormat:@"%@\n%@",artist,album], GROWL_NOTIFICATION_DESCRIPTION,
									artwork?[artwork TIFFRepresentation]:nil, GROWL_NOTIFICATION_ICON,
									nil];
				[[NSDistributedNotificationCenter defaultCenter] postNotificationName:(state == itPLAYING)?ITUNES_TRACK_CHANGED:ITUNES_PLAYING
																			   object:nil userInfo:noteDict];
			}
		}
		state = newState;
		trackID = newTrackID;
	}
}

- (void)dealloc
{
	[pollScript release];
	[getTrackScript release];
	[getArtistScript release];
	[getArtworkScript release];
	[getAlbumScript release];
	[pollTimer invalidate];
	[pollTimer release];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	
	[super dealloc];
}

- (NSAppleScript *)appleScriptNamed:(NSString *)name
{
	NSURL			* url;
	NSDictionary	* error;
	
	url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:name ofType:@"scpt"]];
	
	return [[NSAppleScript alloc] initWithContentsOfURL:url error:&error];
}

- (BOOL)iTunesIsRunning {
	NSEnumerator *processesEnum = [[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	NSDictionary *process;

	while(process = [processesEnum nextObject]) {
		if([iTunesBundleID caseInsensitiveCompare:[process objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame)
			return YES; //this is iTunes!
	}

	return NO;
}

- (void)handleAppLaunch:(NSNotification *)notification {
	if([iTunesBundleID caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame) {
		if(pollTimer == nil) {
			//it is fully possible that the user might launch more than one
			//  instance of iTunes, or that some fool might give his app
			//  the same bundle ID as iTunes.
			//hence the if(pollTimer == nil) statement.

			//this is the same code as in applicationWillFinishLaunching:.
			pollTimer = [[NSTimer scheduledTimerWithTimeInterval:POLL_INTERVAL 
														  target:self
														selector:@selector(poll:)
														userInfo:nil
														 repeats:YES] retain];
			[self poll:nil];
		}
	}
}
- (void)handleAppQuit:(NSNotification *)notification {
	if([iTunesBundleID caseInsensitiveCompare:[[notification userInfo] objectForKey:@"NSApplicationBundleIdentifier"]] == NSOrderedSame) {
		[pollTimer invalidate];
		[pollTimer release];
		pollTimer = nil;
	}
}

@end
