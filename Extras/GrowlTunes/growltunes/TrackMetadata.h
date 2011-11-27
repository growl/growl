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
}

@property(readonly, assign, nonatomic) BOOL isEvaluated;

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

@end
