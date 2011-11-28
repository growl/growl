//
//  iTunes+iTunesAdditions.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/26/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "iTunes+iTunesAdditions.h"

@implementation ITunesApplication (iTunesAdditions)

+(ITunesApplication*)sharedInstance
{
    static dispatch_once_t once;
    static __strong ITunesApplication* iTunes;
    dispatch_once(&once, ^ {
        iTunes = [ITunesApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    });
    return iTunes;
}

-(NSString*)playerStateName
{
    ITunesEPlS playerState = [self playerState];
    switch (playerState) {
        case ITunesEPlSPlaying:
            return @"playing";
            break;
            
        case ITunesEPlSPaused:
            return @"paused";
            break;
            
        case ITunesEPlSStopped:
            return @"stopped";
            break;
            
        case ITunesEPlSFastForwarding:
            return @"fast forwarding";
            break;
            
        case ITunesEPlSRewinding:
            return @"rewinding";
            break;
    }
}

@end


@implementation ITunesTrack (iTunesAdditions)

-(NSString*)albumRatingKindName
{
    ITunesERtK ratingKind = [self albumRatingKind];
    switch (ratingKind) {
        case ITunesERtKUser:
            return @"user";
            break;
            
        case ITunesERtKComputed:
            return @"computed";
            break;
    }
}

-(NSString*)ratingKindName
{
    ITunesERtK ratingKind = [self ratingKind];
    switch (ratingKind) {
        case ITunesERtKUser:
            return @"user";
            break;
            
        case ITunesERtKComputed:
            return @"computed";
            break;
    }
}

-(NSString*)videoKindName
{
    ITunesEVdK videoKind = [self videoKind];
    switch (videoKind) {
        case ITunesEVdKNone:
            return @"none";
            break;
            
        case ITunesEVdKMovie:
            return @"movie";
            break;
            
        case ITunesEVdKMusicVideo:
            return @"music video";
            break;
            
        case ITunesEVdKTVShow:
            return @"TV show";
            break;
    }
}

@end
