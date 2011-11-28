//
//  TrackMetadata.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/25/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iTunes.h"

@interface TrackMetadata : NSObject {
    ITunesTrack* _trackObject;
    NSMutableDictionary* _cache;
    BOOL _isEvaluated;
    BOOL _neverEvaluate;
}

@property(readonly, nonatomic, assign) BOOL isEvaluated;
@property(readwrite, nonatomic, assign) BOOL neverEvaluate;

@property(readonly, nonatomic, retain) id album;
@property(readonly, nonatomic, retain) id albumArtist;
@property(readonly, nonatomic, retain) id artist;
@property(readonly, nonatomic, retain) id comment;
@property(readonly, nonatomic, retain) id description;
@property(readonly, nonatomic, retain) id episodeID;
@property(readonly, nonatomic, retain) id episodeNumber;
@property(readonly, nonatomic, retain) id longDescription;
@property(readonly, nonatomic, retain) id name;
@property(readonly, nonatomic, retain) id seasonNumber;
@property(readonly, nonatomic, retain) id show;
@property(readonly, nonatomic, retain) id streamTitle;
@property(readonly, nonatomic, retain) id trackCount;
@property(readonly, nonatomic, retain) id trackNumber;
@property(readonly, nonatomic, retain) id time;
@property(readonly, nonatomic, retain) id videoKindName;


-(id)init;
-(id)initWithPersistentID:(NSString*)persistentID;
-(id)initWithTrackObject:(ITunesTrack*)track;
-(void)evaluate;

-(NSArray*)attributeKeys;

-(NSString*)typeDescription;
-(NSString*)trackClass;
-(NSString*)bestArtist;
-(NSString*)bestDescription;
-(NSImage*)artworkImage;

-(NSDictionary*)formattedDescriptionDictionary;

@end
