//
//  GrowlTunes-Amazon.h
//  GrowlTunes-Amazon
//
//  Created by Karl Adam on 9/29/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface GrowlTunes_Amazon : NSObject {
	BOOL	weGetInternet;
}

- (NSImage *)artworkForTitle:(NSString *)song 
					byArtist:(NSString *)artist 
					 onAlbum:(NSString *)album;
@end
