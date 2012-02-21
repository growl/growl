//
//  iTunes+iTunesAdditions.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/26/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "iTunes.h"
#import "macros.h"


@interface ITunesApplication (iTunesAdditions)
+(ITunesApplication*)sharedInstance;
@property(readonly, nonatomic, retain) NSString* playerStateName;
@end

@interface ITunesTrack (iTunesAdditions)
@property(readonly, nonatomic, retain) NSString* albumRatingKindName;
@property(readonly, nonatomic, retain) NSString* ratingKindName;
@property(readonly, nonatomic, retain) NSString* videoKindName;
@property(readonly, nonatomic, retain) NSData* artworkData;
@property(readonly, nonatomic, retain) NSImage* artworkImage;
@end
