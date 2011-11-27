//
//  TrackMetadata.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/25/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "TrackMetadata.h"
#import "iTunes+iTunesAdditions.h"
#import "macros.h"


@interface TrackMetadata ()

@property(readwrite, retain, nonatomic) ITunesTrack* trackObject;
@property(readwrite, retain, nonatomic) NSMutableDictionary* cache;
@property(readwrite, assign, nonatomic) BOOL isEvaluated;

+(ITunesApplication*)iTunes;
+(NSArray*)propertiesForTrackClass:(NSString*)className;
+(NSArray*)propertiesForTrackClass:(NSString*)className includingHelpers:(BOOL)withHelpers;

-(void)_updateStreamMetadata;
-(void)_updateApplicationMetadata;
-(void)_cacheAllProperties;

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

+(BOOL)accessInstanceVariablesDirectly
{
    return NO;
}

+(ITunesApplication*)iTunes
{
    static __strong ITunesApplication* iTunes;
    if (!iTunes) iTunes = [ITunesApplication applicationWithBundleIdentifier:ITUNES_BUNDLE_ID];
    return iTunes;
}

+(NSArray*)propertiesForTrackClass:(NSString*)className
{
    return [self propertiesForTrackClass:className includingHelpers:NO];
}

+(NSArray*)propertiesForTrackClass:(NSString*)className includingHelpers:(BOOL)withHelpers
{
    static __strong NSDictionary* propertiesByClassName;
    
    if (!propertiesByClassName) {
        NSSet* itemSet              = $set(@"container", @"exists", @"index", @"name", @"persistentID");
        NSSet* trackSet             = [itemSet setByAddingObjectsFromSet:
                                       $set(@"EQ",
                                            @"album",
                                            @"albumArtist",
                                            @"albumRating",
                                            @"albumRatingKind",
                                            @"artist",
                                            @"bitRate",
                                            @"bookmarkable",
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
                                            @"lyrics",
                                            @"modificationDate",
                                            @"objectDescription",
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
                                            @"year"
                                        )];
        
        NSSet* trackAdditionsSet    = $set(@"albumRatingKindName", @"ratingKindName", @"videoKindName");
        trackSet                    = [trackSet setByAddingObjectsFromSet:trackAdditionsSet];
        
        NSSet* cdSet                = [trackSet setByAddingObjectsFromSet:$set(@"location")];
        NSSet* deviceSet            = [trackSet copy];
        NSSet* fileSet              = [trackSet setByAddingObjectsFromSet:$set(@"location")];
        NSSet* sharedSet            = [trackSet copy];
        NSSet* urlSet               = [trackSet setByAddingObjectsFromSet:$set(@"address")];
        
        propertiesByClassName = 
            $dict(@"ITunesItem", itemSet,
                  @"ITunesTrack", trackSet,
                  @"ITunesAudioCDTrack", cdSet,
                  @"ITunesDeviceTrack", deviceSet,
                  @"ITunesFileTrack", fileSet,
                  @"ITunesSharedTrack", sharedSet,
                  @"ITunesURLTrack", urlSet);
    }
    
    NSSet* props = [propertiesByClassName objectForKey:className];
    
    if (props) {
        if (withHelpers) {
            props = [props setByAddingObjectsFromSet:$set(@"typeDescription", @"trackClass", 
                                                          @"bestArtist", @"bestDescription", 
                                                          @"artworkImage")];
        }
        return [[props allObjects] sortedArrayUsingSelector:@selector(compare:)];
    } else {
        return [NSArray array];
    }
}

#pragma mark initializers

-(id)init
{
    LogInfoTag(@"init", @"Initializing with lazy currentTrack object");
    ITunesApplication* ita = [[self class] iTunes];
    ITunesTrack* currentTrack = ita.currentTrack;
    return [self initWithTrackObject:currentTrack];
}

-(id)initWithPersistentID:(NSString*)persistentID
{
    LogInfoTag(@"init", @"Initializing with persistent ID: %@", persistentID);
    ITunesApplication* ita = [[self class] iTunes];
    SBElementArray* sources = [ita sources];
    ITunesSource* library = [sources objectWithName:@"Library"];
    ITunesLibraryPlaylist* libraryPlaylist = [[library libraryPlaylists] lastObject];
    SBElementArray* entireLibrary = [libraryPlaylist tracks];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"persistentID == %@", persistentID];
    NSArray* matched = [entireLibrary filteredArrayUsingPredicate:predicate];
    if ([matched count] > 0) return [self initWithTrackObject:[matched lastObject]];
    return nil;
}

-(id)initWithTrackObject:(ITunesTrack*)track
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
-(void)_updateStreamMetadata
{
    if (_isEvaluated) { return; }
    
    LogVerbose(@"updating stream metadata");
    
    ITunesApplication* ita = [[self class] iTunes];
    [self.cache setValue:ita.currentStreamTitle forKey:@"streamTitle"];
    [self.cache setValue:ita.currentStreamURL forKey:@"streamURL"];
}

-(void)_updateApplicationMetadata
{
    LogVerbose(@"updating application metadata");
    
    ITunesApplication* ita = [[self class] iTunes];
    [self.cache setObject:$bool(ita.frontmost) forKey:@"isActive"];
    [self.cache setObject:$bool(ita.fullScreen) forKey:@"isFullScreen"];
    [self.cache setObject:$bool(ita.mute) forKey:@"isMuted"];
    [self.cache setObject:ita.currentEQPreset.name forKey:@"EQPreset"];
    [self.cache setObject:$integer(ita.playerState) forKey:@"playerState"];
    [self.cache setObject:$integer(ita.playerPosition) forKey:@"playerPosition"];
}

-(void)_cacheAllProperties
{
    if (_isEvaluated) { return; }
    
    NSArray* keys = [[self class] propertiesForTrackClass:[self trackClass] 
                                         includingHelpers:NO];
    LogVerbose(@"caching properties: %@", keys);
    
    NSDictionary* cacheDictionary = [self.trackObject dictionaryWithValuesForKeys:keys];
    [self.cache addEntriesFromDictionary:cacheDictionary];
}

-(void)evaluate
{
    if (!_isEvaluated) {
        LogInfo(@"evaluating lazy track object");
        self.trackObject = [self.trackObject get];
        LogInfo(@"new track object: %@", self.trackObject);
        [self _updateStreamMetadata];
        [self _cacheAllProperties];
        self.isEvaluated = YES;
    }
}

#pragma mark KVC

// TODO: determine whether or not we care about caching 'exists' on evaluated tracks
-(id)valueForUndefinedKey:(NSString *)key
{
    LogVerboseTag(@"KVC", @"valueForUndefinedKey: %@", key);
    
    id value;
    
    if (_isEvaluated) {
        value = [self.cache objectForKey:key];
        if (!value) {
            value = [self.trackObject valueForKey:key];
            if (value) { [self.cache setObject:value forKey:key]; }
        }
    } else {
        value = [self.trackObject valueForKey:key];
    }
    
    return value;
}

-(NSArray*)attributeKeys
{
    return [[self class] propertiesForTrackClass:[self trackClass] includingHelpers:YES];
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
    [self _updateStreamMetadata];
    NSString* streamTitle = [self.cache valueForKey:@"streamTitle"];
    if (streamTitle && [streamTitle length] > 0) {
        return @"stream";
    }
    
    // go go team pre-classification
    ITunesEVdK videoKind = [[self valueForKey:@"videoKind"] intValue];
    switch (videoKind) {
        case ITunesEVdKNone:
            break;
            
        case ITunesEVdKTVShow:
            return @"show";
            break;
            
        case ITunesEVdKMovie:
            return @"movie";
            break;
            
        case ITunesEVdKMusicVideo:
            return @"musicVideo";
            break;
    }
    
    // anything else is just music. further classification (file/url/shared/device/etc) would be overkill.
    return @"music";
}

-(NSString*)trackClass
{
    // if this isn't an evaluated metadata object, get the non-loosely-typed track object first
    ITunesTrack* track = (_isEvaluated) ? self.trackObject : [self.trackObject get];
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
    
    ITunesArtwork* artwork = [artworks lastObject];
    if (![artwork exists]) return nil;
    
    artwork = [artwork get];
    NSData* data = artwork.rawData;
    NSImage* image = [[NSImage alloc] initWithData:data];
    
    LogImage(@"track art", image);
    
    return image;
}

@end
