//
//  TrackMetadata.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/25/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "TrackMetadata.h"
#import "macros.h"


@interface TrackMetadata ()

@property(readwrite, retain, nonatomic) iTunesTrack* trackObject;
@property(readwrite, retain, nonatomic) NSMutableDictionary* cache;
@property(readwrite, assign, nonatomic) BOOL isEvaluated;

+(iTunesApplication*)iTunes;

-(void)updateStreamMetadata;
-(void)updateApplicationMetadata;

@end


static int _LogLevel = LOG_LEVEL_ERROR;


@implementation TrackMetadata

@synthesize trackObject = _trackObject;
@synthesize cache = _cache;
@synthesize isEvaluated = _isEvaluated;

+(void)initialize
{
    if (self == [TrackMetadata class]) {
        setLogLevel("TrackMetadata");
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

+(iTunesApplication*)iTunes
{
    static __strong iTunesApplication* iTunes;
    if (!iTunes) iTunes = [SBApplication applicationWithBundleIdentifier:ITUNES_BUNDLE_ID];
    return iTunes;
}

#pragma mark initializers

-(id)init
{
    LogInfoTag(@"init", @"Initializing with lazy currentTrack object");
    iTunesApplication* ita = [[self class] iTunes];
    iTunesTrack* currentTrack = ita.currentTrack;
    return [self initWithTrackObject:currentTrack];
}

-(id)initWithPersistentID:(NSString*)persistentID
{
    LogInfoTag(@"init", @"Initializing with persistent ID: %@", persistentID);
    iTunesApplication* ita = [[self class] iTunes];
    SBElementArray* sources = [ita sources];
    iTunesSource* library = [sources objectWithName:@"Library"];
    iTunesLibraryPlaylist* libraryPlaylist = [[library libraryPlaylists] lastObject];
    SBElementArray* entireLibrary = [libraryPlaylist tracks];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"persistentID == %@", persistentID];
    NSArray* matched = [entireLibrary filteredArrayUsingPredicate:predicate];
    if ([matched count] > 0) return [self initWithTrackObject:[matched lastObject]];
    return nil;
}

-(id)initWithTrackObject:(iTunesTrack*)track
{
    self = [super init];
        
    self.cache = [NSMutableDictionary dictionary];
    self.trackObject = track;
    
    NSString* specifier = [track performSelector:@selector(specifierDescription)];
    _isEvaluated = !([specifier rangeOfString:@"currentTrack"].location != NSNotFound);
    
    LogVerboseTag(@"init", @"track: %@ isEvaluated: %@", track, (_isEvaluated ? @"YES" : @"NO"));
    
    return self;
}

#pragma mark evaluation

// TODO: determine whether it's worth it to do a persistentID check against the currentTrack and refresh when evaluated
-(void)updateStreamMetadata
{
    if (_isEvaluated) { return; }
    
    LogVerbose(@"updating stream metadata");
    
    iTunesApplication* ita = [[self class] iTunes];
    NSString* streamTitle = ita.currentStreamTitle;
    NSString* streamURL = ita.currentStreamURL;
    
    if (streamTitle && streamURL) {
        LogVerbose(@"updating stream metadata for stream");
        [self.cache setObject:ita.currentStreamTitle forKey:@"streamTitle"];
        [self.cache setObject:ita.currentStreamURL forKey:@"streamURL"];
    } else {
        LogVerbose(@"updating stream metadata for non-stream");
        // too lazy to use NSNull
        [self.cache setObject:@"" forKey:@"streamTitle"];
        [self.cache setObject:@"" forKey:@"streamURL"];
    }
}

-(void)updateApplicationMetadata
{
    LogVerbose(@"updating application metadata");
    
    iTunesApplication* ita = [[self class] iTunes];
    [self.cache setObject:$bool(ita.frontmost) forKey:@"isActive"];
    [self.cache setObject:$bool(ita.fullScreen) forKey:@"isFullScreen"];
    [self.cache setObject:$bool(ita.mute) forKey:@"isMuted"];
    [self.cache setObject:ita.currentEQPreset.name forKey:@"EQPreset"];
    [self.cache setObject:$integer(ita.playerState) forKey:@"playerState"];
    [self.cache setObject:$integer(ita.playerPosition) forKey:@"playerPosition"];
}

-(void)evaluate
{
    if (!_isEvaluated) {
        LogInfo(@"evaluating lazy track object");
        self.trackObject = [self.trackObject get];
        LogInfo(@"new track object: %@", self.trackObject);
        [self updateStreamMetadata];
        self.isEvaluated = YES;
    }
}

#pragma mark KVC proxying

// TODO: determine whether or not we care about caching 'exists' on evaluated tracks
-(id)valueForUndefinedKey:(NSString *)key
{
    LogVerboseTag(@"KVC proxying", @"valueForUndefinedKey: %@", key);
    
    id value;
    
    if (_isEvaluated) {
        value = [self.cache objectForKey:key];
        if (!value) { value = [self.trackObject valueForKey:key]; }
        if (value) { [self.cache setObject:value forKey:key]; }
    } else {
        value = [self.trackObject valueForKey:key];
    }
    
    return value;
}

#pragma mark helper accessors

// TODO: classify itunes university tracks if their genre is consistently "iTunes\U00a0U"
-(NSString*)typeDescription
{
    // first check to see if the track exists. if the last track change notification was the result of playing a
    // ringtone or itunes store preview, then it doesn't appear you can introspect its' metadata via SB/AS. in this
    // case 'exists' will throw an applescript error, return nil, and evaluate to NO.
    BOOL exists = [[self valueForKey:@"exists"] boolValue];
    if (!exists) {
        return @"error";
    }
    
    // a podcast can be audio, video, file, or url so we need to check for this first
    BOOL isPodcast = [[self valueForKey:@"podcast"] boolValue];
    if (isPodcast) {
        return @"podcast";
    }
    
    // stream info is pulled from the application object rather than the track object. the easiest way to determine if
    // this is a radio stream is to check whether iTunesApplication.currentStreamTitle is an empty string. because this
    // information only exists while streaming, and only for the duration of that track, we need to ask for it right
    // away then cache those values.
    [self updateStreamMetadata];
    NSString* streamTitle = [self.cache valueForKey:@"streamTitle"];
    if (streamTitle && [streamTitle length] > 0) {
        return @"stream";
    }
    
    // go go team pre-classification
    iTunesEVdK videoKind = [[self valueForKey:@"videoKind"] intValue];
    switch (videoKind) {
        case iTunesEVdKNone:
            break;
            
        case iTunesEVdKTVShow:
            return @"show";
            break;
            
        case iTunesEVdKMovie:
            return @"movie";
            break;
            
        case iTunesEVdKMusicVideo:
            return @"musicVideo";
            break;
    }
    
    // anything else is just music. further classification (file/url/shared/device/etc) would be overkill.
    return @"music";
}

-(NSString*)trackClass
{
    // if this isn't an evaluated metadata object, get the non-loosely-typed track object first
    iTunesTrack* track = (_isEvaluated) ? self.trackObject : [self.trackObject get];
    return NSStringFromClass([track class]);
}

-(NSString*)bestArtist
{
    NSString* bestArtist;
    BOOL isCompilation = [[self valueForKey:@"compilation"] boolValue];
    
    if (isCompilation) {
        bestArtist = [self valueForKey:@"albumArtist"];
        if (!bestArtist || [bestArtist length] == 0) {
            bestArtist = [self valueForKey:@"artist"];
        }
    } else {
        bestArtist = [self valueForKey:@"artist"];
    }
    
    if (!bestArtist || [bestArtist length] == 0) {
        bestArtist = @"Unknown Artist";
    }
    
    return bestArtist;
}

-(NSString*)bestDescription
{
    NSString* bestDescription;
    
    bestDescription = [self valueForKey:@"longDescription"];
    
    if (!bestDescription || [bestDescription length] == 0) {
        bestDescription = [self valueForKey:@"comment"];
    }
    
    if (!bestDescription || [bestDescription length] == 0) {
        bestDescription = [self valueForKey:@"description"];
    }
    
    if (!bestDescription) {
        bestDescription = @"";
    }
    
    return bestDescription;
}

-(NSImage*)artworkImage
{
    SBElementArray* artworks = self.trackObject.artworks;
    if ([artworks count] == 0) return nil;
    
    iTunesArtwork* artwork = [artworks lastObject];
    if (![artwork exists]) return nil;
    
    artwork = [artwork get];
    NSData* data = artwork.rawData;
    NSImage* image = [[NSImage alloc] initWithData:data];
    
    LogImage(@"track art", image);
    
    return image;
}

@end
