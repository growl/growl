//
//  ARTchiveIconSource.h
//  ARTchive
//
//  Created by Kevin Ballard on 9/29/04.
//  Copyright 2004 Kevin Ballard. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GrowlTunesPlugin
- (NSImage *)artworkForTitle:(NSString *)track
					byArtist:(NSString *)artist
					 onAlbum:(NSString *)album;
@end

@interface ARTchiveIconSource : NSObject <GrowlTunesPlugin> {

}

@end
