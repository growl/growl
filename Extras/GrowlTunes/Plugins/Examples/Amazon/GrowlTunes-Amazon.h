//
//  GrowlTunes-Amazon.h
//  GrowlTunes-Amazon
//
//  Created by Karl Adam on 9/29/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DOM/DOM.h>
#import "GrowlTunesPlugin.h"

@interface GrowlTunes_Amazon : NSObject <GrowlTunesPlugin> {
	BOOL	weGetInternet;

	NSString *artist;
	NSString *album;
	NSString *song;
	BOOL compilation;
	NSImage *artwork;
}


- (NSImage *)artworkForTitle:(NSString *)newSong 
					byArtist:(NSString *)newArtist 
					 onAlbum:(NSString *)newAlbum 
			   isCompilation:(BOOL)newCompilation;

#pragma mark -
#pragma mark AMAZON SEARCHING METHODS
	// Gets all albums by the specified albums(might also return bodycare products)
	// But that's not what it asks amazon for, so just be careful with this badboy! ;-)
- (NSArray *)getAlbumsByArtist:(NSString *)artistName;
	// Tries to find albumName by artistName (can return many albums)
- (NSDictionary *)getAlbum:(NSString *)albumName byArtist:(NSString *)artistName;
	// Sends a query to Amazon web services, returns the full XML response IF anything is found,
	// otherwise it returns nil
- (NSString *)queryAmazon:(NSString *)query; // "query" is actually just the GET args after the address.

#pragma mark -
#pragma mark ACCESSOR METHODS
- (NSString *)artist;
- (NSString *)album;
- (NSString *)song;
- (BOOL)compilation;
- (NSImage *)artwork;

#pragma mark -
#pragma mark OTHER METHODS
	// This method simply downloads the specified NSURL and returns nil on error
- (NSData *)download:(NSURL *)address;
@end
