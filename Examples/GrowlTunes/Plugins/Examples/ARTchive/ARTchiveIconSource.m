//
//  ARTchiveIconSource.m
//  ARTchive
//
//  Created by Kevin Ballard on 9/29/04.
//  Copyright 2004 Kevin Ballard. All rights reserved.
//

#import "ARTchiveIconSource.h"


@implementation ARTchiveIconSource

- (id) init {
	if (self = [super init]) {
		NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
		//[userDefaults addSuiteNamed:@"com.growl.GrowlTunesARTchive"];
		[defs addSuiteNamed:@"public.music.artwork"];
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:@"~/Library/Images/Music" forKey:@"LibraryLocation"];
		[dict setObject:@"Cover" forKey:@"PreferredImage"];
		[defs registerDefaults:dict];
	}
	return self;
}

- (NSImage *)artworkForTitle:(NSString *)track byArtist:(NSString *)artist onAlbum:(NSString *)album {
	// Protect string from itself
	NSMutableString *temp = [NSMutableString string];
	if ([track length]) {
		[temp setString:track];
		[temp replaceOccurrencesOfString:@":" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
		[temp replaceOccurrencesOfString:@"/" withString:@":" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
		track = [NSString stringWithString:temp];
	}
	
	if ([artist length]) {
		[temp setString:artist];
		[temp replaceOccurrencesOfString:@":" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
		[temp replaceOccurrencesOfString:@"/" withString:@":" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
		artist = [NSString stringWithString:temp];
	}
	
	if ([album length]) {
		[temp setString:album];
		[temp replaceOccurrencesOfString:@":" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
		[temp replaceOccurrencesOfString:@"/" withString:@":" options:NSLiteralSearch range:NSMakeRange(0, [temp length])];
		album = [NSString stringWithString:temp];
	}
	
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *path = [[defs objectForKey:@"LibraryLocation"] stringByExpandingTildeInPath];
	if ([defs objectForKey:@"ArtworkSubdirectory"])
		path = [path stringByAppendingPathComponent:[defs objectForKey:@"ArtworkSubdirectory"]];
	
	if ([artist length]) {
		path = [path stringByAppendingPathComponent:artist];
	} else {
		path = [path stringByAppendingPathComponent:@"Unknown Artist"];
	}
	
	if ([album length]) {
		path = [path stringByAppendingPathComponent:album];
	} else {
		path = [path stringByAppendingPathComponent:@"Unknown Album"];
	}
	
	path = [path stringByAppendingPathComponent:[defs objectForKey:@"PreferredImage"]];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSEnumerator *e = [[NSArray arrayWithObjects:@"tiff", @"tif", @"png", @"jpeg", @"jpg", @"gif", @"bmp", nil] objectEnumerator];
	NSString *ext;
	while (ext = [e nextObject]) {
		NSString *fullPath = [path stringByAppendingPathExtension:ext];
		if ([fm fileExistsAtPath:fullPath]) {
			return [[[NSImage alloc] initByReferencingFile:fullPath] autorelease];
		}
	}
	return nil;
}

@end
