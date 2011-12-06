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
#import "iTunes+iTunesAdditions.h"
#import "TrackMetadata.h"

@interface ITunesConductor : NSObject <SBApplicationDelegate> {
    @private
    
    BOOL _running;
    TrackMetadata* _metaTrack;
    TrackMetadata* _currentTrack;
    NSString* _currentPersistentID;
    ITunesEPlS _currentPlayerState;
}

@property(readonly, nonatomic, assign) BOOL isRunning;
@property(readonly, nonatomic, assign) BOOL isPlaying;
@property(readonly, nonatomic, assign) BOOL isPaused;
@property(readonly, nonatomic, assign) BOOL isStopped;
@property(readonly, nonatomic, assign) BOOL isFastForwarding;
@property(readonly, nonatomic, assign) BOOL isRewinding;
@property(readonly, nonatomic, assign) ITunesEPlS currentPlayerState;
@property(readonly, nonatomic, retain) NSString* currentPersistentID;
@property(readonly, nonatomic, retain) TrackMetadata* currentTrack;

+ (void)setLogLevel:(int)level;
+ (int)logLevel;

- (void)bootstrap;

- (IBAction)playPause:(id)sender;
- (IBAction)nextTrack:(id)sender;
- (IBAction)previousTrack:(id)sender;

- (IBAction)run:(id)sender;
- (IBAction)quit:(id)sender;

- (IBAction)activate:(id)sender;

@end
