//
//  ITunesConductor.h
//  growltunes
//
//  Created by Travis Tilley on 11/4/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ScriptingBridge/ScriptingBridge.h>
#import "iTunes.h"


#define StateStopped iTunesEPlSStopped
#define StatePlaying iTunesEPlSPlaying
#define StatePaused iTunesEPlSPaused
#define StateFastForward iTunesEPlSFastForwarding
#define StateRewind iTunesEPlSRewinding

#define RENOTIFY_STREAM_KEY @"ReNotifyOnStreamingTrackChange"

#define ITUNES_BUNDLE_ID @"com.apple.iTunes"
#define PLAYER_INFO_ID ITUNES_BUNDLE_ID ".playerInfo"
#define SOURCE_SAVED_ID ITUNES_BUNDLE_ID ".sourceSaved"

#define NotifierChangedTracks           @"Changed Tracks"
#define NotifierPaused                  @"Paused"
#define NotifierStopped                 @"Stopped"
#define NotifierStarted                 @"started"

#define NotifierChangedTracksReadable   NSLocalizedString(@"Changed Tracks", nil)
#define NotifierPausedReadable          NSLocalizedString(@"Paused", nil)
#define NotifierStoppedReadable         NSLocalizedString(@"Stopped", nil)
#define NotifierStartedReadable         NSLocalizedString(@"Started", nil)


@interface ITunesConductor : NSObject <SBApplicationDelegate> {
    @private
    
    iTunesApplication* _iTunes;
    BOOL _running;
    NSInteger _trackID;
    iTunesEPlS _playerState;
    NSMutableDictionary* _itemData;
}

@property(readonly, nonatomic, assign, getter = isRunning) BOOL running;
@property(readonly, nonatomic, assign) iTunesEPlS playerState;
@property(readonly, nonatomic, copy) NSDictionary* itemData;

+ (void)setLogLevel:(int)level;
+ (int)logLevel;
- (BOOL)running;

@end
