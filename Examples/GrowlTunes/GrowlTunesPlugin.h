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
			   
- (BOOL) usesNetwork;
@end

@protocol GrowlTunesPluginArchive
- (BOOL)archiveImage:(NSImage *)image
			track:(NSString *)track
		   artist:(NSString *)artist
			album:(NSString *)album
	  compilation:(BOOL)compilation;
@end
