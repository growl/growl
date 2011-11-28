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
    TrackMetadata* _currentTrack;
}

@property(readonly, nonatomic, assign) BOOL running;
@property(readonly, nonatomic, retain) TrackMetadata* currentTrack;

+ (void)setLogLevel:(int)level;
+ (int)logLevel;

@end
