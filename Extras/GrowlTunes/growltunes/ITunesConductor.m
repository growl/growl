//
//  ITunesConductor.m
//  growltunes
//
//  Created by Travis Tilley on 11/4/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "ITunesConductor.h"
#import "macros.h"
#import "NSObject+DRYDescription.h"


@interface ITunesConductor ()

@property(readwrite, nonatomic, strong) iTunesApplication* iTunes;
@property(readwrite, nonatomic, assign, getter = isRunning) BOOL running;
@property(readwrite, nonatomic, assign) NSInteger trackID;
@property(readwrite, nonatomic, assign) iTunesEPlS playerState;
@property(readwrite, nonatomic, copy) NSMutableDictionary* itemData;

- (void)didLaunchOrTerminateNotification:(NSNotification*)note;
- (void)playerInfo:(NSNotification*)note;
- (void)sourceSaved:(NSNotification*)note;

@end


static int _LogLevel = LOG_LEVEL_ERROR;
static NSArray* tkeys;


@implementation ITunesConductor

@synthesize iTunes = _iTunes;
@synthesize trackID = _trackID;
@synthesize playerState = _playerState;
@synthesize itemData = _itemData;

+ (void)initialize
{
    if (self == [ITunesConductor class]) {
        setLogLevel("ITunesConductor");
        
        if (tkeys == nil) {
            tkeys = $array(@"EQ",
                           @"album",
                           @"albumArtist",
                           @"albumRating",
                           @"albumRatingKind",
                           @"artist",
                           @"bitRate",
                           @"bpm",
                           @"category",
                           @"comment",
                           @"compilation",
                           @"composer",
                           @"databaseID",
                           @"dateAdded",
                           @"discCount",
                           @"discNumber",
                           @"duration",
                           @"enabled",
                           @"episodeID",
                           @"episodeNumber",
                           @"finish",
                           @"gapless",
                           @"genre",
                           @"grouping",
                           @"id",
                           @"index",
                           @"kind",
                           @"longDescription",
                           @"lyrics",
                           @"modificationDate",
                           @"name",
                           @"objectDescription",
                           @"persistentID",
                           @"playedCount",
                           @"playedDate",
                           @"podcast",
                           @"rating",
                           @"ratingKind",
                           @"releaseDate",
                           @"sampleRate",
                           @"seasonNumber",
                           @"show",
                           @"shufflable",
                           @"size",
                           @"skippedCount",
                           @"skippedDate",
                           @"start",
                           @"time",
                           @"trackCount",
                           @"trackNumber",
                           @"unplayed",
                           @"videoKind",
                           @"volumeAdjustment",
                           @"year");
        }
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
    
    self.trackID = -1;
    self.playerState = StateStopped;
    
    iTunesApplication* ita = [SBApplication applicationWithBundleIdentifier:ITUNES_BUNDLE_ID];
    [ita setDelegate:self];
    self.iTunes = ita;
        
    self.running = self.iTunes.isRunning;
    
    if (self.running && self.iTunes.playerState == StatePlaying) {
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

- (iTunesTrack*)getTrackByPersistentID:(NSString*)persistentID
{
    SBElementArray* sources = [$notNull(self.iTunes) sources];
    iTunesSource* library = [sources objectWithName:@"Library"];
    iTunesLibraryPlaylist* libraryPlaylist = [[library libraryPlaylists] lastObject];
    SBElementArray* entireLibrary = [libraryPlaylist tracks];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"persistentID == %@", persistentID];
    NSArray* matched = [entireLibrary filteredArrayUsingPredicate:predicate];
    if ([matched count] > 0) { return [matched lastObject]; }
    return nil;
}

- (void)playerInfo:(NSNotification*)note
{
    LogInfoTag(@"playerInfo", @"note: %@", note);
        
    iTunesApplication* ita = $notNull(self.iTunes);
    
    iTunesTrack* currentTrack = ita.currentTrack.get;
    
    if (currentTrack.exists) {
        iTunesEPlS previousState = _playerState;
        iTunesEPlS currentState = ita.playerState;
        _playerState = currentState;
        
        NSInteger previousTrackID = _trackID;
        NSInteger currentTrackID = currentTrack.databaseID;
        _trackID = currentTrackID;
        
        NSString* trackType = NSStringFromClass([currentTrack class]);
        
        LogVerbose(@"previousState: %qi currentState: %qi previousTrackID: %qi currentTrackID: %qi trackType: %@",
                   previousState, currentState, previousTrackID, currentTrackID, trackType);
        
        if (previousTrackID == currentTrackID) {
            if (previousState == currentState) {return;}
            
            if ((currentState == StatePlaying) && ([trackType isEqualToString:@"iTunesURLTrack"])) {
                BOOL renotify = [[NSUserDefaults standardUserDefaults] boolForKey:RENOTIFY_STREAM_KEY];
                LogInfoTag(RENOTIFY_STREAM_KEY, @"renotify: %@", renotify?@"YES":@"NO");
                if (!renotify) {return;}
            }
        }
        
        NSMutableDictionary* currentTrackData = [[currentTrack dictionaryForKVCKeys:tkeys] mutableCopy];
        [currentTrackData setValue:trackType forKey:@"class"];
        [currentTrackData setValue:ita.currentEncoder.format forKey:@"format"];
        [currentTrackData setValue:[ita.encoders valueForKey:@"format"] forKey:@"usableFormats"];
        [currentTrackData setValue:ita.currentEQPreset.name forKey:@"EQPreset"];
        [currentTrackData setValue:ita.currentPlaylist.name forKey:@"playlist"];
        [currentTrackData setValue:ita.version forKey:@"iTunesVersion"];
        [currentTrackData setValue:[currentTrack performSelector:@selector(specifierDescription)] forKey:@"reference"];
        
        switch (currentState) {
            case StatePlaying:
                [currentTrackData setValue:@"playing" forKey:@"stateName"];
                [currentTrackData setValue:$bool(YES) forKey:@"isPlaying"];
                break;
                
            case StatePaused:
                [currentTrackData setValue:@"paused" forKey:@"stateName"];
                [currentTrackData setValue:$bool(YES) forKey:@"isPaused"];
                break;
                
            case StateStopped:
                [currentTrackData setValue:@"stopped" forKey:@"stateName"];
                [currentTrackData setValue:$bool(YES) forKey:@"isStopped"];
                break;
                
            case StateFastForward:
                [currentTrackData setValue:@"fast forwarding" forKey:@"stateName"];
                [currentTrackData setValue:$bool(YES) forKey:@"isFastForwarding"];
                break;
                
            case StateRewind:
                [currentTrackData setValue:@"rewinding" forKey:@"stateName"];
                [currentTrackData setValue:$bool(YES) forKey:@"isRewinding"];
                break;
        }
        
        if ([trackType isEqualToString:@"ITunesURLTrack"]) {
            iTunesURLTrack* utrack = (iTunesURLTrack*)currentTrack;
            [currentTrackData setValue:utrack.address forKey:@"address"];
            [currentTrackData setValue:ita.currentStreamTitle forKey:@"streamTitle"];
            [currentTrackData setValue:ita.currentStreamURL forKey:@"streamURL"];
            [currentTrackData setValue:$bool(YES) forKey:@"isStreaming"];
        } else if ([trackType isEqualToString:@"ITunesFileTrack"]) {
            iTunesFileTrack* ftrack = (iTunesFileTrack*)currentTrack;
            [currentTrackData setValue:ftrack.location forKey:@"location"];
            [currentTrackData setValue:$bool(YES) forKey:@"isFile"];
        } else if ([trackType isEqualToString:@"ITunesAudioCDTrack"]) {
            iTunesAudioCDTrack* atrack = (iTunesAudioCDTrack*)currentTrack;
            [currentTrackData setValue:atrack.location forKey:@"location"];
            [currentTrackData setValue:$bool(YES) forKey:@"isCD"];
        } else if ([trackType isEqualToString:@"ITunesDeviceTrack"]) {
            [currentTrackData setValue:$bool(YES) forKey:@"isDevice"];
            // perhaps more intuitive? iPhone/iPad might as well be an iPod for
            // all we care about the device...
            [currentTrackData setValue:$bool(YES) forKey:@"isIPod"];
        } else if ([trackType isEqualToString:@"ITunesSharedTrack"]) {
            [currentTrackData setValue:$bool(YES) forKey:@"isShared"];
        }
                
        iTunesArtwork* artwork = [currentTrack.artworks lastObject];
        
        if ([artwork exists]) {
            artwork = [artwork get];
            
            NSData* rawData = [artwork rawData];
            NSImage* img = [[NSImage alloc] initWithData:rawData];
            
            LogImage(@"track art", img);
            
            NSMutableDictionary* artMeta = [NSMutableDictionary dictionary];
            [artMeta setValue:img forKey:@"image"];
            [artMeta setValue:[artwork valueForKey:@"format"] forKey:@"format"];
            [artMeta setValue:$bool(artwork.downloaded) forKey:@"downloaded"];
            [artMeta setValue:[artwork valueForKey:@"kind"] forKey:@"kind"];
            [artMeta setValue:[artwork performSelector:@selector(specifierDescription)] forKey:@"reference"];
                        
            [currentTrackData setValue:artMeta forKey:@"artwork"];
            [currentTrackData setValue:$bool(YES) forKey:@"hasArtwork"];
        }
        
        LogVerboseTag(@"itemData", @"itemData: %@", currentTrackData);
        
        if (![currentTrackData isEqualToDictionary:self.itemData]) {
            self.itemData = currentTrackData;
        }
        
    }
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
