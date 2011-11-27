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
    
    ITunesApplication* _iTunes;
    BOOL _running;
    NSInteger _trackID;
    ITunesEPlS _playerState;
    NSMutableDictionary* _itemData;
}

@property(readonly, nonatomic, assign, getter = isRunning) BOOL running;
@property(readonly, nonatomic, assign) ITunesEPlS playerState;
@property(readonly, nonatomic, copy) NSDictionary* itemData;

+ (void)setLogLevel:(int)level;
+ (int)logLevel;
- (BOOL)running;

@end
