//
//  TrackMetadata.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/25/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <objc/runtime.h>
#import "TrackMetadata.h"
#import "iTunes+iTunesAdditions.h"
#import "FormattingToken.h"
#import "FormattingPreferencesHelper.h"


@interface TrackMetadata ()

@property(readwrite, STRONG, nonatomic) ITunesTrack* trackObject;
@property(readwrite, STRONG, nonatomic) NSMutableDictionary* cache;
@property(readwrite, assign, nonatomic) BOOL isEvaluated;

+(NSArray*)propertiesForTrackClass:(NSString*)className;
+(NSArray*)propertiesForTrackClass:(NSString*)className includingHelpers:(BOOL)withHelpers;

-(void)_updateStreamMetadata;
-(void)_cacheAllProperties;

@end


@implementation TrackMetadata

@synthesize trackObject = _trackObject;
@synthesize cache = _cache;
@synthesize isEvaluated = _isEvaluated;
@synthesize neverEvaluate = _neverEvaluate;

static id _propertyGetterFunc(TrackMetadata* self, SEL _cmd);

static int ddLogLevel = DDNS_LOG_LEVEL_DEFAULT;

+ (int)ddLogLevel
{
    return ddLogLevel;
}

+ (void)ddSetLogLevel:(int)logLevel
{
    ddLogLevel = logLevel;
}

+(void)initialize
{
    if (self == [TrackMetadata class]) {
        NSNumber *logLevel = [[NSUserDefaults standardUserDefaults] objectForKey:
                              [NSString stringWithFormat:@"%@LogLevel", [self class]]];
        if (logLevel)
            ddLogLevel = [logLevel intValue];
        
        NSArray* props = [self propertiesForTrackClass:@"all"];
        for (NSString* prop in props) {
            BOOL success = class_addMethod(self, NSSelectorFromString(prop), (IMP)_propertyGetterFunc, "@@:");
            if (!success) {
                LogErrorTag(LogTagKVC, @"Unable to add property accessor for: %@", prop);
            }
        }
    }
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
    static __STRONG NSDictionary* propertiesByClassName;
    
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
        NSSet* deviceSet            = AUTORELEASE([trackSet copy]);
        NSSet* fileSet              = [trackSet setByAddingObjectsFromSet:$set(@"location")];
        NSSet* sharedSet            = AUTORELEASE([trackSet copy]);
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
        RETAIN(propertiesByClassName);
    }
    
    NSSet* props = [propertiesByClassName objectForKey:className];
    
    if (props) {
        if (withHelpers) {
            props = [props setByAddingObjectsFromSet:$set(@"typeDescription", @"trackClass", 
                                                          @"bestArtist", @"bestDescription", 
                                                          @"artworkData")];
        }
        return [[props allObjects] sortedArrayUsingSelector:@selector(compare:)];
    } else {
        return [NSArray array];
    }
}

#pragma mark initializers

-(id)init
{
    LogInfoTag(LogTagInit, @"Initializing with lazy currentTrack object");
    ITunesApplication* ita = [ITunesApplication sharedInstance];
    
    if (![ita isRunning]) {
        LogError(@"iTunes isn't running; there is no 'current track'");
        return nil;
    }
    
    ITunesTrack* currentTrack = ita.currentTrack;
    return [self initWithTrackObject:currentTrack];
}

-(id)initWithPersistentID:(NSString*)persistentID
{
    LogInfoTag(LogTagInit, @"Initializing with persistent ID: %@", persistentID);
    ITunesApplication* ita = [ITunesApplication sharedInstance];
    
    if (![ita isRunning]) {
        LogError(@"iTunes isn't running; unable to lookup track %@", persistentID);
        return nil;
    }
    
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
    
    LogVerboseTag(LogTagInit, @"track: %@ isEvaluated: %@", track, (evaluated ? @"YES" : @"NO"));
    
    if (evaluated) [self evaluate];
        
    return self;
}

-(void)dealloc
{
    RELEASE(_cache);
    RELEASE(_trackObject);
    SUPER_DEALLOC;
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
        
        if (![[ITunesApplication sharedInstance] isRunning]) {
            LogError(@"iTunes isn't running");
            return;
        }
        
        self.trackObject = [self.trackObject get];
        LogInfo(@"new track object: %@", self.trackObject);
        [self _updateStreamMetadata];
        [self _cacheAllProperties];
        self.isEvaluated = YES;
        self.neverEvaluate = YES;
    }
}

-(TrackMetadata*)evaluated
{
    if (_isEvaluated) { return self; }
    
    TrackMetadata* etrack = [[TrackMetadata alloc] initWithTrackObject:self.trackObject];
    if (etrack) {
        etrack.neverEvaluate = NO;
        [etrack evaluate];
    }
    return AUTORELEASE(etrack);
}

#pragma mark KVC

static inline id _safeTrackPropertyGetter(TrackMetadata* self, NSString* key) {
    id value = nil;
    
    LogVerboseTag(LogTagKVC, @"_safeTrackPropertyGetter for key: %@", key);
    
    if (![[ITunesApplication sharedInstance] isRunning]) {
        LogWarnTag(LogTagKVC, @"iTunes isn't running, unable to retrieve value: %@", key);
        return value;
    }
    
    if (![self.trackObject exists]) {
        LogWarnTag(LogTagKVC, @"track object doesn't exist, unable to retrieve value: %@", key);
        return value;
    }
    
    value = [self.trackObject valueForKey:key];
    LogVerboseTag(LogTagKVC, @"retrieved value: %@", key);
    
    return value;
}

static inline id _cachingTrackPropertyGetter(TrackMetadata* self, NSString* key) {
    id value = nil;
    
    LogVerboseTag(LogTagKVC, @"_cachingTrackPropertyGetter for key: %@", key);
    
    value = [self.cache valueForKey:key];
    LogVerboseTag(LogTagKVC, @"cached value: %@", value);
    
    if (!value) {
        value = _safeTrackPropertyGetter(self, key);
        if (value) {
            LogVerboseTag(LogTagKVC, @"caching retrieved value");
            [self.cache setValue:value forKey:key];
        }
    }
    
    return value;
}

static id _propertyGetterFunc(TrackMetadata* self, SEL _cmd) {    
    NSString* key = NSStringFromSelector(_cmd);    
    LogVerboseTag(LogTagKVC, @"_propertyGetterFunc _cmd:%@", key);
    
    if (self.isEvaluated && ![key isEqualToString:@"exists"]) {
        LogVerboseTag(LogTagKVC, @"is evaluated");
        return _cachingTrackPropertyGetter(self, key);
    }
    
    return _safeTrackPropertyGetter(self, key);
}

@dynamic album, albumArtist, artist, comment, description, episodeID, episodeNumber, longDescription, name, seasonNumber, show, streamTitle, trackCount, trackNumber, time, videoKindName, persistentID, rating;

-(id)valueForUndefinedKey:(NSString *)key
{
    LogVerboseTag(LogTagKVC, @"valueForUndefinedKey: %@", key);
    return _propertyGetterFunc(self, NSSelectorFromString(key));
}

-(NSArray*)attributeKeys
{
    return [[self class] propertiesForTrackClass:[self trackClass] includingHelpers:YES];
}

-(void)setRating:(NSNumber *)rating
{
    if (![[ITunesApplication sharedInstance] isRunning] || ![self.trackObject exists]) return;
    
    [self.trackObject setValue:rating forKey:@"rating"];
    if (self.isEvaluated) {
        rating = [self.trackObject valueForKey:@"rating"];
        [self.cache setValue:rating forKey:@"rating"];
    }
}

#pragma mark helper accessors

// TODO: classify itunes university tracks if their genre is consistently "iTunes\U00a0U"
-(NSString*)typeDescription
{
    if (![[ITunesApplication sharedInstance] isRunning]) {
        LogWarn(@"iTunes isn't running; this TrackMetadata object is invalid");
        return @"error";
    }
    
    // first check to see if the track exists. if the last track change notification was the result of playing a
    // ringtone or itunes store preview, then it doesn't appear you can introspect its' metadata via SB/AS. in this
    // case 'exists' will throw an applescript error, return nil, and evaluate to NO.
    BOOL exists = [[self valueForKey:@"exists"] boolValue];
    if (!exists) {
        LogWarn(@"this track doesn't exist");
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
    ITunesEVdK videoKind = [[self valueForKey:@"videoKind"] unsignedIntValue];
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
        
        default:
            break;
    }
    
    // anything else is just music. further classification (file/url/shared/device/etc) would be overkill.
    return @"music";
}

-(BOOL)isPodcast
{ return [self.typeDescription isEqualToString:@"podcast"]; }

-(BOOL)isStream
{ return [self.typeDescription isEqualToString:@"stream"]; }

-(BOOL)isShow
{ return [self.typeDescription isEqualToString:@"show"]; }

-(BOOL)isMovie
{ return [self.typeDescription isEqualToString:@"movie"]; }

-(BOOL)isMusicVideo
{ return [self.typeDescription isEqualToString:@"musicVideo"]; }

-(BOOL)isMusic
{ return [self.typeDescription isEqualToString:@"music"]; }

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
        bestDescription = [self valueForKey:@"objectDescription"];
    }
    
    if (!bestDescription) {
        bestDescription = @"";
    }
    
    return bestDescription;
}

-(NSData*)artworkData
{
    NSData* data = self.trackObject.artworkData;
    LogData(data);
    return data;
}

-(NSImage*)artworkImage
{
    NSImage* image = self.trackObject.artworkImage;
    LogImage(image);
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
    [dict setValue:[self artworkData] forKey:@"icon"];
    
    NSString* type = [self typeDescription];
    
    if ([type isEqualToString:@"error"]) {
        LogError(@"track returned type description of error: %@", self);
        return nil;
    }
    
    NSArray* attributes = $array(formattingAttributes);
    FormattingPreferencesHelper* helper = AUTORELEASE([[FormattingPreferencesHelper alloc] init]);
    
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
    
    NSCharacterSet* toTrim = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString* descriptionString = [[descriptionArray componentsJoinedByString:@"\n"]
                                   stringByTrimmingCharactersInSet:toTrim];
    [dict setValue:descriptionString forKey:@"description"];
    
    NSDictionary* immutableDict = AUTORELEASE([dict copy]);
    
    if (_isEvaluated) {
        [self.cache setValue:immutableDict forKey:@"formattingDescriptionDictionary"];
    }
    
    return immutableDict;
}

-(NSString*)formattedTitle
{
    return [[self formattedDescriptionDictionary] objectForKey:@"title"];
}

-(NSString*)formattedDescription
{
    return [[self formattedDescriptionDictionary] objectForKey:@"description"];
}

@end
