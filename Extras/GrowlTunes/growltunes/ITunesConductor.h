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
