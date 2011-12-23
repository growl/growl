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
@property(readwrite, nonatomic, assign) BOOL neverEvaluate;

@property(readonly, nonatomic, retain) NSString* album;
@property(readonly, nonatomic, retain) NSString* albumArtist;
@property(readonly, nonatomic, retain) NSString* artist;
@property(readonly, nonatomic, retain) NSString* comment;
@property(readonly, nonatomic, retain) NSString* description;
@property(readonly, nonatomic, retain) NSString* episodeID;
@property(readonly, nonatomic, retain) NSNumber* episodeNumber;
@property(readonly, nonatomic, retain) NSString* longDescription;
@property(readonly, nonatomic, retain) NSString* name;
@property(readonly, nonatomic, retain) NSNumber* seasonNumber;
@property(readonly, nonatomic, retain) NSString* show;
@property(readonly, nonatomic, retain) NSString* streamTitle;
@property(readonly, nonatomic, retain) NSNumber* trackCount;
@property(readonly, nonatomic, retain) NSNumber* trackNumber;
@property(readonly, nonatomic, retain) NSString* time;
@property(readonly, nonatomic, retain) NSString* videoKindName;

@property(readonly, nonatomic, retain) NSString* persistentID;

@property(readwrite, nonatomic, retain) NSNumber* rating;

@property(readonly, nonatomic, retain) NSImage* artworkImage;
@property(readonly, nonatomic, retain) NSString* bestArtist;
@property(readonly, nonatomic, retain) NSString* bestDescription;
@property(readonly, nonatomic, retain) NSString* trackClass;
@property(readonly, nonatomic, retain) NSString* typeDescription;
@property(readonly, nonatomic, retain) NSString* formattedTitle;
@property(readonly, nonatomic, retain) NSString* formattedDescription;


-(id)init;
-(id)initWithPersistentID:(NSString*)persistentID;
-(id)initWithTrackObject:(ITunesTrack*)track;
-(void)evaluate;
-(TrackMetadata*)evaluated;

-(NSArray*)attributeKeys;
-(NSDictionary*)formattedDescriptionDictionary;

@end
