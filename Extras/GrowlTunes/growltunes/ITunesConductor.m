//
//  ITunesConductor.m
//  growltunes
//
//  Created by Travis Tilley on 11/4/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "ITunesConductor.h"
#import "iTunes+iTunesAdditions.h"
#import "macros.h"
#import "NSObject+DRYDescription.h"


@interface ITunesConductor ()

@property(readwrite, nonatomic, assign) BOOL running;

- (void)didLaunchOrTerminateNotification:(NSNotification*)note;
- (void)playerInfo:(NSNotification*)note;
- (void)sourceSaved:(NSNotification*)note;

@end


static int _LogLevel = LOG_LEVEL_ERROR;

@implementation ITunesConductor

@synthesize currentTrack = _currentTrack;

+ (void)initialize
{
    if (self == [ITunesConductor class]) {
        setLogLevel("ITunesConductor");
    }
}

+ (void)setLogLevel:(int)level
{
    _LogLevel = level;
}

+ (int)logLevel
{
    return _LogLevel;
}

- (id)init
{
    self = [super init];
    
    ITunesApplication* ita = [ITunesApplication sharedInstance];
    [ita setDelegate:self];
    
    _currentTrack = [[TrackMetadata alloc] init];
    _currentTrack.neverEvaluate = YES;
        
    self.running = ita.isRunning;
    
    if (self.running && ita.playerState == StatePlaying) {
        LogVerbose(@"iTunes already running and playing; sending fake 'playerInfo' notification");
        [self playerInfo:[NSNotification notificationWithName:PLAYER_INFO_ID 
                                                       object:$dict(@"source", @"init")]];
    }
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(playerInfo:)
                                                            name:PLAYER_INFO_ID
                                                          object:nil];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(sourceSaved:)
                                                            name:SOURCE_SAVED_ID
                                                          object:nil];
    
    return self;
}

- (void)dealloc
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{    
    Handle xx;
    AEPrintDescToHandle(event, &xx);
    LogErrorTag(@"eventDidFail:", @"event: \n%s\nerror: %@", *xx, error);
    DisposeHandle(xx);
    
    return nil;
}

- (void)didLaunchOrTerminateNotification:(NSNotification*)note
{
    NSString* appID = [[note userInfo] valueForKey:@"NSApplicationBundleIdentifier"];
    if ([appID isEqualToString:ITUNES_BUNDLE_ID]) {
        LogVerboseTag(@"Launch/Terminate", @"note: %@", note);

        NSString* noteType = [note name];
        if ([noteType isEqualToString:NSWorkspaceDidLaunchApplicationNotification]) {
            self.running = YES;
        } else {
            self.running = NO;
        }
    }
}

- (void)playerInfo:(NSNotification*)note
{
    LogInfoTag(@"playerInfo", @"note: %@", note);
    [self willChangeValueForKey:@"currentTrack"];
    [self didChangeValueForKey:@"currentTrack"];
}

// TODO: determine how to filter out notifications caused by a play count increase
// TODO: something useful
- (void)sourceSaved:(NSNotification*)note
{
    LogInfoTag(@"sourceSaved", @"note: %@", note);
}

- (void)setRunning:(BOOL)running
{
    NSString* watchType;
    NSString* unWatchType;
    
    NSNotificationCenter* wsnc = [[NSWorkspace sharedWorkspace] notificationCenter];
    
    if (running) {
        watchType = NSWorkspaceDidTerminateApplicationNotification;
        unWatchType = NSWorkspaceDidLaunchApplicationNotification;
    } else {
        watchType = NSWorkspaceDidLaunchApplicationNotification;
        unWatchType = NSWorkspaceDidTerminateApplicationNotification;
    }
    
    [wsnc removeObserver:self 
                    name:unWatchType 
                  object:nil];

    LogInfoTag(@"Launch/Terminate", 
               @"iTunes %@ currently running, registering for %@",
               running?@"is":@"is not", watchType);
    
    [wsnc addObserver:self 
             selector:@selector(didLaunchOrTerminateNotification:) 
                 name:watchType 
               object:nil];
    
    _running = running;
}

- (BOOL)isRunning
{
    return _running;
}

- (BOOL)running
{
    return _running;
}

- (NSString*)description
{
    return [self dryDescriptionForProperties];
}


@end
