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

@property(readwrite, nonatomic, assign) BOOL isRunning;
@property(readwrite, nonatomic, assign) ITunesEPlS currentPlayerState;
@property(readwrite, nonatomic, retain) NSString* currentPersistentID;
@property(readwrite, nonatomic, retain) TrackMetadata* currentTrack;

- (void)didLaunchOrTerminateNotification:(NSNotification*)note;
- (void)playerInfo:(NSNotification*)note;
- (void)sourceSaved:(NSNotification*)note;

- (void)updatePlayerState;

@end


static int _LogLevel = LOG_LEVEL_ERROR;

@implementation ITunesConductor

@synthesize currentTrack = _currentTrack;
@synthesize currentPlayerState = _currentPlayerState;
@synthesize currentPersistentID = _currentPersistentID;

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

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    return NO;
}

- (void)bootstrap
{
    ITunesApplication* ita = [ITunesApplication sharedInstance];
    [ita setDelegate:self];
    
    self.isRunning = ita.isRunning;
    
    if (self.isRunning && self.currentPlayerState == StatePlaying) {
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
        LogInfoTag(@"Launch/Terminate", @"note: %@", note);

        NSString* noteType = [note name];
        if ([noteType isEqualToString:NSWorkspaceDidLaunchApplicationNotification]) {
            self.isRunning = YES;
        } else {
            self.isRunning = NO;
        }
    }
}

- (void)updatePlayerState
{
    BOOL updateState = NO;
    BOOL updateID = NO;
    BOOL updateTrack = NO;
    
    ITunesEPlS newState;
    NSString* newID;
    NSString* typeDescription;
    
    if (_running) {
        newState = [[ITunesApplication sharedInstance] playerState];
        newID = [self.currentTrack persistentID];
        typeDescription = [self.currentTrack typeDescription];
    } else {
        newState = -1;
        newID = nil;
        typeDescription = nil;
    }
    
    LogVerbose(@"previous state: %x new state: %x \nprevious ID: %@ new ID: %@ \ntype: %@",
               _currentPlayerState, newState, _currentPersistentID, newID, typeDescription);
    
    if (newState != _currentPlayerState) { updateState = YES; }
    if (![newID isEqualToString:_currentPersistentID]) { updateID = YES; }
    if ((updateState || updateID || [typeDescription isEqualToString:@"stream"]) && 
        ![typeDescription isEqualToString:@"error"]) { updateTrack = YES; }
    
    LogVerbose(@"update state: %@ \nupdate ID: %@ \nupdate track: %@",
               updateState?@"YES":@"NO",
               updateID?@"YES":@"NO",
               updateTrack?@"YES":@"NO");
    
    if (updateState) {
        [self willChangeValueForKey:@"currentPlayerState"];
        [self willChangeValueForKey:@"isPlaying"];
        [self willChangeValueForKey:@"isPaused"];
        [self willChangeValueForKey:@"isStopped"];
        [self willChangeValueForKey:@"isFastForwarding"];
        [self willChangeValueForKey:@"isRewinding"];
    }
    
    if (updateID) {
        [self willChangeValueForKey:@"currentPersistentID"];
    }
    
    if (updateTrack) {
        [self willChangeValueForKey:@"currentTrack"];
    }
    
    _currentPlayerState = newState;
    _currentPersistentID = newID;
    
    if (_running && !_currentTrack) {
        LogVerbose(@"initializing new currentTrack");
        _currentTrack = [[TrackMetadata alloc] init];
        _currentTrack.neverEvaluate = YES;
    }
    
    if (updateTrack) {
        [self didChangeValueForKey:@"currentTrack"];
    }
    
    if (updateID) {
        [self didChangeValueForKey:@"currentPersistentID"];
    }
    
    if (updateState) {
        [self didChangeValueForKey:@"isRewinding"];
        [self didChangeValueForKey:@"isFastForwarding"];
        [self didChangeValueForKey:@"isStopped"];
        [self didChangeValueForKey:@"isPaused"];
        [self didChangeValueForKey:@"isPlaying"];
        [self didChangeValueForKey:@"currentPlayerState"];
    }
}

- (void)playerInfo:(NSNotification*)note
{
    LogInfoTag(@"playerInfo", @"note: %@", note);
    [self updatePlayerState];
}

// TODO: determine how to filter out notifications caused by a play count increase
// TODO: something useful
- (void)sourceSaved:(NSNotification*)note
{
    LogVerboseTag(@"sourceSaved", @"note: %@", note);
}

- (void)setIsRunning:(BOOL)running
{    
    [self willChangeValueForKey:@"isRunning"];
    
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
    [self updatePlayerState];
}

- (BOOL)isRunning
{
    return _running;
}

- (BOOL)running
{
    return _running;
}

-(BOOL)isPlaying
{
    return (_running && _currentPlayerState == ITunesEPlSPlaying);
}

-(BOOL)isPaused
{
    return (_running && _currentPlayerState == ITunesEPlSPaused);
}

-(BOOL)isStopped
{
    return (_running && _currentPlayerState == ITunesEPlSStopped);
}

-(BOOL)isFastForwarding
{
    return (_running && _currentPlayerState == ITunesEPlSFastForwarding);
}

-(BOOL)isRewinding
{
    return (_running && _currentPlayerState == ITunesEPlSRewinding);
}

- (NSString*)description
{
    return [self dryDescriptionForProperties];
}

- (IBAction)playPause:(id)sender
{
    if (_running) [[ITunesApplication sharedInstance] playpause];
}

- (IBAction)nextTrack:(id)sender
{
    if (_running) [[ITunesApplication sharedInstance] nextTrack];
}

- (IBAction)previousTrack:(id)sender
{
    if (_running) [[ITunesApplication sharedInstance] previousTrack];
}

- (IBAction)run:(id)sender
{
    [[ITunesApplication sharedInstance] run];
}

- (IBAction)quit:(id)sender
{
    if (_running) [[ITunesApplication sharedInstance] quit];
}


@end
