/*
 *  Amazon.c
 *  GrowlTunes
 *
 *  Created by rudy on 7/15/06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include "Amazon.h"

/* Name: GTP_Init
   Purpose: return the ID for our plugin so that GrowlTunesPlugin can register it
			any datastructures that are going to be persistient through the life of
			the plugin should be allocated now. any plugin settings should be configured here
*/
CFStringRef GTP_Init(void) {

	return CFSTR("info.growl.growltunesplugin.amazon");
}

/* Name: GTP_IconData
   Purpose: the plugin should do the majority of its work here, returning a growl acceptable
			artwork encapsulated in a CFDataRef. GTP will provide artist, title and track
			information for the purposes of looking up the artwork.  It is up to the plugin
			author to determine what is sent back for use as the graphic.  NULL should be returned
			if the plugin could not find an appropriate piece of artwork for the track.  The purpose
			of this is so that GTP can fall through to the next available enabled artwork retrieval method
			currently the fall through is as such ( iTunes->ARTchive->Delicious->Amazon).  The reasoning for
			this is that the first 3 retrieval methods do not require a network connection and are most likely
			to result in found artwork.  Of course you can configure it such that only one method is enabled and
			fall through artwork retrieval will not occur.
*/
CFDataRef GTP_IconData(CFStringRef artist, CFStringRef title, CFStringRef album, CFStringRef composer, Boolean compilation) {
	CFDataRef icon = NULL;
	
	/* If the album is a compilation, we don't look for the artist;
	 * instead we look for all compilations.
	 */
	if( (!artist) && (!CFStringGetLength(artist)))
		artist = composer;
	if(compilation)
		artist = CFSTR("compilation");
	CFDictionaryRef albumInfo = getAlbumByArtist(album, artist);
	return imageWithAlbumInfo(albumInfo);
}

/* Name: GTP_Dealloc
   Purpose: to allow the plugin to dispose of any data structures that it has kept around for reuse
*/
Boolean GTP_Dealloc(void) {

	return true;
}

#define AMAZON_QUERY_FORMAT     \
	CFSTR("?locale=us           \
	&t=0C8PCNE1KCKFJN5EHP02     \
	&dev-t=0C8PCNE1KCKFJN5EHP02 \
	&ArtistSearch=%@            \
	&mode=music                 \
	&sort=+salesrank            \
	&offer=All                  \
	&type=lite                  \
	&page=1                     \
	&f=xml")

CFArrayRef getAlbumsByArtist(CFStringRef artistName)
 {
	CFMutableArrayRef result = nil;

	CFStringRef query = CFStringCreateWithFormatAndArguments (kCFAllocatorDefault, NULL, AMAZON_QUERY_FORMAT, artistName);
	CFStringRef escapedQuery = CFURLCreateStringByAddingPercentEscapes (kCFAllocatorDefault, query, CFSTR(""), CFSTR(""), kCFStringEncodingUTF8);

	CFDataRef *XMLData = queryAmazon(escapedQuery);

	if (XMLData) {
		CFXMLParser *parser = CFXMLParserCreate (kCFAllocatorDefault, XMLData, escapedQuery, CFOptionFlags parseOptions, CFIndex versionOfNodes, CFXMLParserCallBacks *callBacks,CFXMLParserContext *context);
		[parser setShouldProcessNamespaces:YES];
		GrowlAmazonXMLResponse *XMLResponse = [[[GrowlAmazonXMLResponse alloc] init] autorelease];
		[parser setDelegate:XMLResponse];
		[parser parse];
		[parser release];

		NSArray *foundItems = [XMLResponse foundItems];
		unsigned numFoundItems = [foundItems count];
		if (numFoundItems < 1U) {
//			NSLog(@"No results");
		} else {
//			NSLog(@"Found some!, filtering...");
			result = [NSMutableArray arrayWithCapacity:numFoundItems];

			NSEnumerator *foundItemsEnum = [foundItems objectEnumerator];
			NSDictionary *foundItem;

			while ((foundItem = [foundItemsEnum nextObject])) {
				NSString  *albumName = [foundItem objectForKey:AMAZON_ALBUM_KEY];

				NSSet    *foundArtists    = [NSSet setWithArray:[foundItem objectForKey:AMAZON_ARTISTS_KEY]];
				NSString *foundArtistName = [foundArtists member:artistName];
				if (foundArtistName) artistName = foundArtistName;

				NSMutableDictionary *productInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
					albumName,        @"name",
					artistName,       @"artist",
					nil];
				id obj;
				obj = [foundItem objectForKey:AMAZON_IMAGE_URL_LARGE_KEY];
				if (obj) [productInfo setObject:obj forKey:AMAZON_IMAGE_URL_LARGE_KEY];
				obj = [foundItem objectForKey:AMAZON_IMAGE_URL_MEDIUM_KEY];
				if (obj) [productInfo setObject:obj forKey:AMAZON_IMAGE_URL_MEDIUM_KEY];
				obj = [foundItem objectForKey:AMAZON_IMAGE_URL_SMALL_KEY];
				if (obj) [productInfo setObject:obj forKey:AMAZON_IMAGE_URL_SMALL_KEY];

				[result addObject:productInfo];
			}
		}
	}

	return result;
}

- (NSDictionary *) getAlbum:(NSString *)albumName byArtist:(NSString *)artistName {
	//Now that we have all the info we need, we can decide which result to use.
	BOOL found = NO; //This var is set to YES once we finally select the album to use.

	NSArray *matches = [self getAlbumsByArtist:artistName];
	unsigned numMatches = [matches count];

	NSMutableArray *resultCandidates = [NSMutableArray arrayWithCapacity:numMatches];
	NSDictionary *result = nil;

	NSEnumerator *matchEnum = [matches objectEnumerator];
	NSDictionary *match;

	while ((match = [matchEnum nextObject])) {
		NSString *matchAlbumName = [match objectForKey:@"name"];
		NSString *canonicalMatchAlbumName = [self canonicalAlbumName:matchAlbumName];
		NSString *canonicalAlbumName = [self canonicalAlbumName:albumName];
		BOOL   nameIsEqual = (!albumName)
		||                   ([matchAlbumName          caseInsensitiveCompare:albumName]          == NSOrderedSame)
		||                   ([matchAlbumName          caseInsensitiveCompare:canonicalAlbumName] == NSOrderedSame)
		||                   ([canonicalMatchAlbumName caseInsensitiveCompare:albumName]          == NSOrderedSame)
		||                   ([canonicalMatchAlbumName caseInsensitiveCompare:canonicalAlbumName] == NSOrderedSame);
		BOOL artistIsEqual = (!artistName)
		||                   ([[match objectForKey:@"artist"] caseInsensitiveCompare:artistName] == NSOrderedSame);

		if (nameIsEqual) {
			//Check if both the artist and name match
			if (artistIsEqual) {
				//this is the one we want.
				result = match;
				found = YES;

				break;
			} else
				[resultCandidates addObject:match];
		}
	}
	if (!found) {
		if ([resultCandidates count]) {
			/*Now we just select the first match.
			 *We didn't do that in the first loop because we want to loop
			 *	through ALL albums to make sure we get the PERFECT match
			 *	if it's there.
			 */
			result = [resultCandidates objectAtIndex:0U];
/*			NSLog(@"SELECTED: URL to artwork: %@ For album: %@", [theResult objectForKey:@"artworkURL"],
				  [theResult objectForKey:@"name"]);
*/
		} else {
			// No likely results found
//			NSLog(@"Found no likely albums in response");
		}
	}

	return result;
}

// "query" is actually just the GET args after the address.
- (NSData *) queryAmazon:(NSString *)query {
	NSString *search = [@"http://xml.amazon.com/onca/xml3" stringByAppendingString:query];
	NSURL *url = [NSURL URLWithString:search];

	// Do the search on AWS
	NSData *data = [self download:url];
	if (!data)
		NSLog(@"Error while getting XML Response from Amazon");
	return data;
}

#pragma mark -
#pragma mark Helper methods

CFDataRef imageDataForKeyFromAlbumInfo(CFStringRef key, CFDictionaryRef albumInfo) {
	CFDataRef imageData = NULL;
	CFStringRef URLString = CFDictionaryGetValue(albumInfo, key);
	if (URLString && CFStringGetLength(URLString)) {
		CFURLRef URL = NULL;
		//@try {
			URL = CFURLCreateWithString(kCFAllocatorDefault, URLString);
			imageData = download(URL);
		//}
		//@catch(NSException *e) {
		//	NSLog(@"Exception occurred while downloading %@ (URL string: %@): %@", URL, URLString, [e reason]);
		//}
	}
	return imageData;
}
CFDataRef imageWithAlbumInfo(CFDictionaryRef albumInfo) {
	CFDataRef imageData;
	CFDataRef image = NULL;
	NSSize imageSize = NSZeroSize;

	/*first try large, then medium, then small, looking for a viable image.
	 *an image is unviable if no URL exists for it (obviously) or if the image
	 *	is 1x1. Amazon returns 1x1 images for no obvious reason for albums that
	 *	are not available for purchase.
	 *see: http://trac.growl.info/trac/ticket/88
	 *	--boredzo
	 */

	CFMutableArrayRef imageReps = CFArrayCreateMutable(kCFAllocatorDefault, 3U, kCFTypeArrayCallBacks);
	CFMutableArrayRef *theseImageReps = NULL;
	unsigned i, numImageReps;
	NSImageRep *thisImageRep = nil;
	int width, height, mostPixels = 0;

	imageData = imageDataForKey(AMAZON_IMAGE_URL_LARGE_KEY, albumInfo);
	// this is as far as i have made it
	if (imageData) {
		theseImageReps = [[NSBitmapImageRep imageRepsWithData:imageData] mutableCopy];
		numImageReps = [theseImageReps count];
		for(i = 0U; i < numImageReps;) {
			thisImageRep = [theseImageReps objectAtIndex:i];
			width  = [thisImageRep pixelsWide];
			height = [thisImageRep pixelsHigh];
			if ((width == 1) && (height == 1)) {
				imageData = nil;
				[theseImageReps removeObjectAtIndex:i];
				--numImageReps;
			} else {
				++i;
				if ((width * height) > mostPixels) {
					imageSize = NSMakeSize(width, height);
					mostPixels = (width * height);
				}
			}
		}
		if (numImageReps) [imageReps addObjectsFromArray:theseImageReps];
		[theseImageReps release];
	}
	if (!imageData) {
		imageData = [self imageDataForKey:AMAZON_IMAGE_URL_MEDIUM_KEY fromAlbumInfo:albumInfo];
		if (imageData) {
			theseImageReps = [[NSBitmapImageRep imageRepsWithData:imageData] mutableCopy];
			numImageReps = [theseImageReps count];
			for(i = 0U; i < numImageReps;) {
				thisImageRep = [theseImageReps objectAtIndex:i];
				width  = [thisImageRep pixelsWide];
				height = [thisImageRep pixelsHigh];
				if ((width == 1) && (height == 1)) {
					imageData = nil;
					[theseImageReps removeObjectAtIndex:i];
					--numImageReps;
				} else {
					++i;
					if ((width * height) > mostPixels) {
						imageSize = NSMakeSize(width, height);
						mostPixels = (width * height);
					}
				}
			}
			if (numImageReps) [imageReps addObjectsFromArray:theseImageReps];
			[theseImageReps release];
		}
		if (!imageData) {
			imageData = [self imageDataForKey:AMAZON_IMAGE_URL_SMALL_KEY fromAlbumInfo:albumInfo];
			if (imageData) {
				theseImageReps = [[NSBitmapImageRep imageRepsWithData:imageData] mutableCopy];
				numImageReps = [theseImageReps count];
				for(i = 0U; i < numImageReps;) {
					thisImageRep = [theseImageReps objectAtIndex:i];
					width  = [thisImageRep pixelsWide];
					height = [thisImageRep pixelsHigh];
					if ((width == 1) && (height == 1)) {
						imageData = nil;
						[theseImageReps removeObjectAtIndex:i];
						--numImageReps;
					} else {
						++i;
						if ((width * height) > mostPixels) {
							imageSize = NSMakeSize(width, height);
							mostPixels = (width * height);
						}
					}
				}
				if (numImageReps) [imageReps addObjectsFromArray:theseImageReps];
				[theseImageReps release];
			}
		}
	}

	if ([imageReps count]) {
		image = [[[NSImage alloc] initWithSize:imageSize] autorelease];
		[image addRepresentations:imageReps];
	}
	
	return image;
}

- (NSData *)download:(NSURL *)url {
//	NSLog(@"Go go interweb: %@", url);

	/*the default time-out is 60 seconds.
	 *this is far too long for GrowlTunes; the song could easily be over by then.
	 *so we do it this way, with a time-out of 10 seconds.
	 */
	NSURLRequest *request = [NSURLRequest requestWithURL:url
	                                         cachePolicy:NSURLRequestUseProtocolCachePolicy
	                                     timeoutInterval:10.0];

	NSError *error = nil;
	NSURLResponse *response = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	if (error)
		NSLog(@"In -[GrowlTunes_Amazon download:]: Got error: %@", error);

	return data;
}

/*for each of these inputs:
 *	Revolver[UK]
 *	Revolver(UK)
 *	Revolver [UK]
 *	Revolver (UK)
 *	Revolver - UK
 *... this method returns 'Revolver'.
 */
- (NSString *)canonicalAlbumName:(NSString *)fullAlbumName {
	size_t numChars = [fullAlbumName length];
	unichar *chars = malloc(numChars * sizeof(unichar));
	if (!chars) {
		NSLog(@"In -[GrowlTunes_Amazon canonicalAlbumName:]: Could not allocate %lu bytes of memory in which to examine the full album name", (unsigned long)(numChars * sizeof(unichar)));
		return nil;
	}
	[fullAlbumName getCharacters:chars];

	unsigned long i = numChars; //this is used outside the for

	for (; i > 0U; --i) {
		switch (chars[i]) {
			case '[':
			case '(':
			case '-':
				goto lookForWhitespace;
		}
	}
lookForWhitespace:
	for (; i > 0U; --i)
		if (isspace(chars[i])) break;
	for (; i > 0U; --i) {
		if (!isspace(chars[i])) {
			++i;
			break;
		}
	}

	free(chars);
	return i ? [fullAlbumName substringToIndex:i] : [[fullAlbumName retain] autorelease];
}
