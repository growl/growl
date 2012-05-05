//
//  TrackMetadata.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/25/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "macros.h"
#import "iTunes.h"

@interface TrackMetadata : NSObject {
    ITunesTrack* _trackObject;
    NSMutableDictionary* _cache;
    BOOL _isEvaluated;
    BOOL _neverEvaluate;
}

@property(readonly, nonatomic, assign) BOOL isEvaluated;
@property(readonly, nonatomic, assign) BOOL isPodcast;
@property(readonly, nonatomic, assign) BOOL isStream;
@property(readonly, nonatomic, assign) BOOL isShow;
@property(readonly, nonatomic, assign) BOOL isMovie;
@property(readonly, nonatomic, assign) BOOL isMusicVideo;
@property(readonly, nonatomic, assign) BOOL isMusic;
@property(readwrite, nonatomic, assign) BOOL neverEvaluate;

@property(readonly, nonatomic, STRONG) NSString* album;
@property(readonly, nonatomic, STRONG) NSString* albumArtist;
@property(readonly, nonatomic, STRONG) NSString* artist;
@property(readonly, nonatomic, STRONG) NSString* comment;
@property(readonly, nonatomic, STRONG) NSString* description;
@property(readonly, nonatomic, STRONG) NSString* episodeID;
@property(readonly, nonatomic, STRONG) NSNumber* episodeNumber;
@property(readonly, nonatomic, STRONG) NSString* longDescription;
@property(readonly, nonatomic, STRONG) NSString* name;
@property(readonly, nonatomic, STRONG) NSNumber* seasonNumber;
@property(readonly, nonatomic, STRONG) NSString* show;
@property(readonly, nonatomic, STRONG) NSString* streamTitle;
@property(readonly, nonatomic, STRONG) NSNumber* trackCount;
@property(readonly, nonatomic, STRONG) NSNumber* trackNumber;
@property(readonly, nonatomic, STRONG) NSString* time;
@property(readonly, nonatomic, STRONG) NSString* videoKindName;

@property(readonly, nonatomic, STRONG) NSString* persistentID;

@property(readwrite, nonatomic, STRONG) NSNumber* rating;

@property(readonly, nonatomic, STRONG) NSData* artworkData;
@property(readonly, nonatomic, STRONG) NSImage* artworkImage;
@property(readonly, nonatomic, STRONG) NSString* bestArtist;
@property(readonly, nonatomic, STRONG) NSString* bestDescription;
@property(readonly, nonatomic, STRONG) NSString* trackClass;
@property(readonly, nonatomic, STRONG) NSString* typeDescription;
@property(readonly, nonatomic, STRONG) NSString* formattedTitle;
@property(readonly, nonatomic, STRONG) NSString* formattedDescription;


-(id)init;
-(id)initWithPersistentID:(NSString*)persistentID;
-(id)initWithTrackObject:(ITunesTrack*)track;
-(void)evaluate;
-(TrackMetadata*)evaluated;

-(NSArray*)attributeKeys;
-(NSDictionary*)formattedDescriptionDictionary;

@end
