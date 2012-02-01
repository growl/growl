//
//  ITunesConductor.m
//  growltunes
//
//  Created by Travis Tilley on 11/4/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "ITunesConductor.h"
#import "iTunes+iTunesAdditions.h"


@interface ITunesConductor ()

@property(readwrite, nonatomic, assign) BOOL isRunning;
@property(readwrite, nonatomic, assign) ITunesEPlS currentPlayerState;
@property(readwrite, nonatomic, STRONG) NSString* currentPersistentID;
@property(readwrite, nonatomic, STRONG) TrackMetadata* metaTrack;
@property(readwrite, nonatomic, STRONG) TrackMetadata* currentTrack;

- (void)didLaunchOrTerminateNotification:(NSNotification*)note;
- (void)playerInfo:(NSNotification*)note;
- (void)sourceSaved:(NSNotification*)note;

- (void)updatePlayerState;
- (void)updatePlayerState:(NSDictionary*)note;

@end


@implementation ITunesConductor

@synthesize metaTrack = _metaTrack;
@synthesize currentTrack = _currentTrack;
@synthesize currentPlayerState = _currentPlayerState;
@synthesize currentPersistentID = _currentPersistentID;

static int ddLogLevel = DDNS_LOG_LEVEL_DEFAULT;

+ (int)ddLogLevel
{
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

+ (void)initialize
{
    if (self == [ITunesConductor class]) {
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
    }
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    return NO;
}

- (id)init
{
    self = [super init];
    [self bootstrap];
    return self;
}

-(void)awakeFromNib
{
    [self bootstrap];
}

-(void)cleanupRegistrations
{
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
}

- (void)bootstrap
{
    static BOOL booted = NO;
    if (booted) return;
    
        
    ITunesApplication* ita = [ITunesApplication sharedInstance];
    [ita setDelegate:self];
    
    self.isRunning = ita.isRunning;
    
    if (self.isRunning && self.isPlaying) {
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
    
    booted = YES;
}

-(void)dealloc
{
    [self cleanupRegistrations];
    RELEASE(_currentPersistentID);
    RELEASE(_currentTrack);
    RELEASE(_metaTrack);
    SUPER_DEALLOC;
}

-(void)finalize
{
    [self cleanupRegistrations];
    [super finalize];
}

- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{    
    Handle xx;
    AEPrintDescToHandle(event, &xx);
    LogError(@"event: \n%s\nerror: %@", *xx, error);
    DisposeHandle(xx);
    
    return nil;
}

- (void)didLaunchOrTerminateNotification:(NSNotification*)note
{
    NSString* appID = [[note userInfo] valueForKey:@"NSApplicationBundleIdentifier"];
    if ([appID isEqualToString:ITUNES_BUNDLE_ID]) {
        LogInfo(@"note: %@", note);

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
    [self updatePlayerState:nil];
}

- (void)updatePlayerState:(NSDictionary*)note
{    
    LogVerboseTag(LogTagState, @"updatePlayerState called");
    
    BOOL updateState = NO;
    BOOL updateID = NO;
    BOOL updateTrack = NO;
    
    ITunesEPlS newState = -1U;
    NSString* newID = nil;
    NSString* typeDescription = nil;
    
    if (note) {
        NSString* newStateName = [note valueForKey:@"Player State"];
        if (newStateName && [newStateName isEqualToString:@"Stopped"]) {
            newState = StateStopped;
        }
    }
    
    if (!_running || newState == StateStopped) {
        LogVerboseTag(LogTagState, @"iTunes is either not running or stopped (which may indicate shutdown is imminent)."
                      " Empty id and description data will be used.");
        if (!newState) newState = StateStopped;
        newID = nil;
        typeDescription = @"none";
    } else {
        LogVerboseTag(LogTagState, @"iTunes is running and not stopped."
                      " Current state, id, and description data will be used.");
        newState = [[ITunesApplication sharedInstance] playerState];
        newID = [self.metaTrack persistentID];
        typeDescription = [self.metaTrack typeDescription];
    }
    
    LogVerboseTag(LogTagState, @"previous state: %x new state: %x \nprevious ID: %@ new ID: %@ \ntype: %@",
                  _currentPlayerState, newState, _currentPersistentID, newID, typeDescription);
    
    if (newState != _currentPlayerState) { updateState = YES; }
    if (![newID isEqualToString:_currentPersistentID]) { updateID = YES; }
    if ((updateState || updateID || [typeDescription isEqualToString:@"stream"]) && 
        ![typeDescription isEqualToString:@"error"]) { updateTrack = YES; }
    
    LogVerboseTag(LogTagState, @"update state: %@ \nupdate ID: %@ \nupdate track: %@",
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
        _currentPlayerState = newState;
    }
    
    if (updateID) {
        [self willChangeValueForKey:@"currentPersistentID"];
        if (_currentPersistentID != newID) {
            RELEASE(_currentPersistentID);
            RETAIN(newID);
            _currentPersistentID = newID;
        }
    }
    
    if (updateTrack) {
        [self willChangeValueForKey:@"currentTrack"];
        
        if (!_running || newState == StateStopped) {
            LogVerboseTag(LogTagState, @"setting current track to nil. _running: %@ stopped: %@",
                          _running?@"YES":@"NO", (newState == ITunesEPlSStopped)?@"YES":@"NO");
            RELEASE(_currentTrack);
        } else {
            LogVerboseTag(LogTagState, @"setting current track to evaluated track");
            TrackMetadata* newTrack = [self.metaTrack evaluated];
            if (_currentTrack != newTrack) {
                RELEASE(_currentTrack);
                RETAIN(newTrack);
                _currentTrack = newTrack;
            }
        }
        
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
    LogInfo(@"note: %@", note);
    [self updatePlayerState:note.userInfo];
}

// TODO: determine how to filter out notifications caused by a play count increase
// TODO: something useful
- (void)sourceSaved:(NSNotification*)note
{
    LogVerbose(@"note: %@", note);
}

- (void)setIsRunning:(BOOL)running
{    
    [self willChangeValueForKey:@"isRunning"];
    
    NSString* watchType = nil;
    NSString* unWatchType = nil;
    
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

    LogInfo(@"iTunes %@ currently running, registering for %@", running?@"is":@"is not", watchType);
    
    [wsnc addObserver:self 
             selector:@selector(didLaunchOrTerminateNotification:) 
                 name:watchType 
               object:nil];
    
    _running = running;
    [self updatePlayerState];
    
    [self didChangeValueForKey:@"isRunning"];
}

- (TrackMetadata *)metaTrack
{
    if (_metaTrack) return _metaTrack;
    _metaTrack = [[TrackMetadata alloc] init];
    _metaTrack.neverEvaluate = YES;
    return _metaTrack;
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
    return (_running && _currentPlayerState == StatePlaying);
}

-(BOOL)isPaused
{
    return (_running && _currentPlayerState == StatePaused);
}

-(BOOL)isStopped
{
    return (_running && _currentPlayerState == StateStopped);
}

-(BOOL)isFastForwarding
{
    return (_running && _currentPlayerState == StateFastForward);
}

-(BOOL)isRewinding
{
    return (_running && _currentPlayerState == StateRewind);
}

-(BOOL)isFrontmost
{
    return (_running && [[ITunesApplication sharedInstance] frontmost]);
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
    self.isRunning = [[ITunesApplication sharedInstance] isRunning];
}

- (IBAction)quit:(id)sender
{
    if (_running) {
        self.isRunning = NO;
        [[ITunesApplication sharedInstance] quit];
    }
}

- (IBAction)activate:(id)sender
{
    [[ITunesApplication sharedInstance] activate];
}

-(NSNumber*)volume
{
    if (_running) {
        return [[ITunesApplication sharedInstance] valueForKey:@"soundVolume"];
    }
    return [NSNumber numberWithInt:100];
}

-(void)setVolume:(NSNumber *)volume
{
    if (_running) {
        [self willChangeValueForKey:@"volume"];
        [[ITunesApplication sharedInstance] setValue:volume forKey:@"soundVolume"];
        [self didChangeValueForKey:@"volume"];
    }
}

@end
