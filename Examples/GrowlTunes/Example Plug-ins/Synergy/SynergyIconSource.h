//
//  SynergyIconSource.h
//  GrowlTunes-Synergy
//
//  Created by Mac-arena the Bored Zo on 08/31/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SynergyIconSource: NSObject
{
	NSString *synergySubPath;
}

- (NSImage *)artworkForTitle:(NSString *)song byArtist:(NSString *)artist onAlbum:(NSString *)album;

@end
