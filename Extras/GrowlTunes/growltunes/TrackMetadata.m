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
#import "FormattingToken.h"
#import "FormattingPreferencesHelper.h"
#import <objc/runtime.h>


@interface TrackMetadata ()

@property(readwrite, retain, nonatomic) ITunesTrack* trackObject;
@property(readwrite, retain, nonatomic) NSMutableDictionary* cache;
@property(readwrite, assign, nonatomic) BOOL isEvaluated;

+(NSArray*)propertiesForTrackClass:(NSString*)className;
+(NSArray*)propertiesForTrackClass:(NSString*)className includingHelpers:(BOOL)withHelpers;

-(void)_updateStreamMetadata;
-(void)_cacheAllProperties;

@end


static int _LogLevel = LOG_LEVEL_ERROR;


@implementation TrackMetadata

@synthesize trackObject = _trackObject;
@synthesize cache = _cache;
@synthesize isEvaluated = _isEvaluated;
@synthesize neverEvaluate = _neverEvaluate;

static id _propertyGetterFunc(TrackMetadata* self, SEL _cmd);

+(void)initialize
{
    if (self == [TrackMetadata class]) {
        setLogLevel("TrackMetadata");
        
        NSArray* props = [self propertiesForTrackClass:@"all"];
        for (NSString* prop in props) {
            class_addMethod(self, NSSelectorFromString(prop), (IMP)_propertyGetterFunc, "@@:");
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

+(BOOL)accessInstanceVariablesDirectly
{
    return NO;
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
                  @"ITunesURLTrack", urlSet,
                  @"all", [trackSet setByAddingObjectsFromSet:$set(@"location", @"address")]);
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
    ITunesApplication* ita = [ITunesApplication sharedInstance];
    ITunesTrack* currentTrack = ita.currentTrack;
    return [self initWithTrackObject:currentTrack];
}

-(id)initWithPersistentID:(NSString*)persistentID
{
    LogInfoTag(@"init", @"Initializing with persistent ID: %@", persistentID);
    ITunesApplication* ita = [ITunesApplication sharedInstance];
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
    _isEvaluated = NO;
    _neverEvaluate = NO;
    
    NSString* specifier = [track performSelector:@selector(specifierDescription)];
    BOOL evaluated = !([specifier rangeOfString:@"currentTrack"].location != NSNotFound);
    
    LogVerboseTag(@"init", @"track: %@ isEvaluated: %@", track, (evaluated ? @"YES" : @"NO"));
    
    if (evaluated) [self evaluate];
        
    return self;
}

#pragma mark evaluation

// TODO: determine whether it's worth it to do a persistentID check against the currentTrack and refresh when evaluated
-(void)_updateStreamMetadata
{
    if (_isEvaluated) { return; }
    
    LogVerbose(@"updating stream metadata");
    
    ITunesApplication* ita = [ITunesApplication sharedInstance];
    [self.cache setValue:ita.currentStreamTitle forKey:@"streamTitle"];
    [self.cache setValue:ita.currentStreamURL forKey:@"streamURL"];
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
    if (_neverEvaluate) return;
    
    if (!_isEvaluated) {
        LogInfo(@"evaluating lazy track object");
        self.trackObject = [self.trackObject get];
        LogInfo(@"new track object: %@", self.trackObject);
        [self _updateStreamMetadata];
        [self _cacheAllProperties];
        self.isEvaluated = YES;
        self.neverEvaluate = YES;
    }
}

#pragma mark KVC

// TODO: determine whether or not we care about caching 'exists' on evaluated tracks

static id _propertyGetterFunc(TrackMetadata* self, SEL _cmd) {    
    id value;
    NSString* key = NSStringFromSelector(_cmd);
    
    LogVerboseTag(@"KVC", @"_propertyGetterFunc _cmd:%@", key);
    
    if (self.isEvaluated) {
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

@dynamic album, albumArtist, artist, comment, description, episodeID, episodeNumber, longDescription, name, seasonNumber, show, streamTitle, trackCount, trackNumber, time, videoKindName;

-(id)valueForUndefinedKey:(NSString *)key
{
    LogVerboseTag(@"KVC", @"valueForUndefinedKey: %@", key);
    return _propertyGetterFunc(self, NSSelectorFromString(key));
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

#pragma mark token driven formatting magic

-(NSDictionary*)formattedDescriptionDictionary
{
    if (_isEvaluated) {
        NSDictionary* cachedValue = [self.cache valueForKey:@"formattedDescriptionDictionary"];
        if (cachedValue) {
            return cachedValue;
        }
    }
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setValue:[self artworkImage] forKey:@"icon"];
    
    NSString* type = [self typeDescription];
    
    if ([type isEqualToString:@"error"]) {
        LogError(@"track returned type description of error: %@", self);
        return nil;
    }
    
    NSArray* attributes = $array(formattingAttributes);
    FormattingPreferencesHelper* helper = [[FormattingPreferencesHelper alloc] init];
    
    NSMutableArray* descriptionArray = [NSMutableArray arrayWithCapacity:3];
    
    for (NSString* attribute in attributes) {
        NSArray* tokens = [helper tokensForType:type andAttribute:attribute];
        NSMutableArray* resolved = [NSMutableArray arrayWithCapacity:[tokens count]];
        
        for (id token in tokens) {
            if ([token isKindOfClass:[NSString class]]) {
                [resolved addObject:token];
            } else if ([token isKindOfClass:[FormattingToken class]]) {
                FormattingToken* ftoken = (FormattingToken*)token;
                if ([ftoken isDynamic]) {
                    id value = [self valueForKey:[ftoken lookupKey]];
                    [resolved addObject:[NSString stringWithFormat:@"%@", value]];
                } else {
                    [resolved addObject:[token displayString]];
                }
            }
        }
        
        NSString* resolvedString = [resolved componentsJoinedByString:@" "];
        [dict setValue:resolvedString forKey:attribute];
        
        if (![attribute isEqualToString:@"title"]) {
            [descriptionArray addObject:resolvedString];
        }
    }
    
    NSString* descriptionString = [descriptionArray componentsJoinedByString:@"\n"];
    [dict setValue:descriptionString forKey:@"description"];
    
    if (_isEvaluated) {
        [self.cache setValue:[dict copy] forKey:@"formattingDescriptionDictionary"];
    }
    
    return [dict copy];
}

@end
