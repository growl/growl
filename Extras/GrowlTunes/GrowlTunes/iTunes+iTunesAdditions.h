//
//  iTunes+iTunesAdditions.h
//  GrowlTunes
//
//  Created by Travis Tilley on 11/26/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "iTunes.h"


@interface ITunesApplication (iTunesAdditions)
+(ITunesApplication*)sharedInstance;
@property(readonly, nonatomic, copy) NSString* playerStateName;
@end

@interface ITunesTrack (iTunesAdditions)
@property(readonly, nonatomic, copy) NSString* albumRatingKindName;
@property(readonly, nonatomic, copy) NSString* ratingKindName;
@property(readonly, nonatomic, copy) NSString* videoKindName;
@property(readonly, nonatomic, copy) NSImage* artworkImage;
@end
