/*
 *  GrowlTunesProtocol.h
 *  GrowlTunes
 *
 *  Created by Kevin Ballard on 10/5/04.
 *  Copyright 2004 Kevin Ballard. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

@protocol GrowlTunesPlugin
- (NSImage *)artworkForTitle:(NSString *)track
					byArtist:(NSString *)artist
					 onAlbum:(NSString *)album
			   isCompilation:(BOOL)compilation;
@end