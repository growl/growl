//
//  iTunes+iTunesAdditions.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/26/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "iTunes.h"


@interface ITunesApplication (iTunesAdditions)
@property(readonly, copy, nonatomic) NSString* playerStateName;
@end

@interface ITunesTrack (iTunesAdditions)
@property(readonly, copy, nonatomic) NSString* albumRatingKindName;
@property(readonly, copy, nonatomic) NSString* ratingKindName;
@property(readonly, copy, nonatomic) NSString* videoKindName;
@end
