//
//  GrowlTunes-Amazon.m
//  GrowlTunes-Amazon
//
//  Created by Karl Adam on 9/29/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import "GrowlTunes-Amazon.h"

/*Based on code originally submitted by James Van Dyne
 *Updated for the v4 Amazon API with code from Fjölnir Ásgeirsson
 */

@interface GrowlTunes_Amazon(PRIVATE)

- (NSString *)canonicalAlbumName:(NSString *)fullAlbumName;

@end

@implementation GrowlTunes_Amazon

- (id) init {
	if ( self = [super init] ) {
		// Can't assume we have internet, but we are till someone figures a good test
		weGetInternet = YES;
	}
	return self;
}

- (BOOL)usesNetwork {
	return YES;
}

- (NSImage *)artworkForTitle:(NSString *)song
					byArtist:(NSString *)artist
					 onAlbum:(NSString *)album
			   isCompilation:(BOOL)compilation;
{
//	NSLog(@"Called getArtwork");

	/*If the album is a compilation, we don't look for the artist;
	 *	instead we look for all compilations.
	 */
	if (compilation)
		artist = @"compilation";

	NSImage *artwork = nil;
	NSLog( @"Go go interweb (%@ by %@ from %@)", song, artist, album );
	NSDictionary *albumInfo = [self getAlbum:album byArtist:artist];

	NSData *imageData = nil;
	NSString *URLString = [albumInfo objectForKey:@"artworkURL"];
	if (URLString && [URLString length]) {
		NSURL *URL = nil;
		@try {
			URL = [NSURL URLWithString:URLString];
			imageData = [self download:URL];
		}
		@catch(NSException *e) {
			NSLog(@"Exception occurred while downloading %@ (URL string: %@): %@", URL, URLString, [e reason]);
		}
	}
	if ( imageData )
		artwork = [[(NSImage *)[NSImage alloc] initWithData:imageData] autorelease];

	return artwork;
}

#pragma mark -
#pragma mark Amazon searching methods

- (NSArray *)getAlbumsByArtist:(NSString *)artistName {
	NSString *query = [[NSString stringWithFormat:@"?locale=us&t=0C8PCNE1KCKFJN5EHP02&dev-t=0C8PCNE1KCKFJN5EHP02&ArtistSearch=%@&mode=music&sort=+salesrank&offer=All&type=lite&page=1&f=xml", artistName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSData *XMLData = [self queryAmazon:query];

	if (XMLData) {
		// Parse the XML into a DOM object document
		DOMBuilder *builder = [DOMBuilder defaultBuilder];

		DOMDocument *document;
		@try
		{
			document = [builder buildFromData:XMLData];
		}
		@catch(NSException *e)
		{
			NSLog(@"An exception occurred while parsing XML data (it was probably malformed)\n" @"Exception reason: %@", [e reason]);
			return nil;
		}

		DOMElement *rootElement = [document documentElement]; // Get the root element

		/*locations of what we want:
		 *
		 *root element
		 *	for each album:
		 *	Details
		 *		ProductName <-album name
		 *		Artists
		 *			Artist <-artist name
		 */

		//Search for 'Details' tags in the root element
		DOMXPathExpression *resultQuery = [DOMXPathExpression expressionWithString:@"//Details"];
		NSArray *results = [resultQuery matchesForContextNode:rootElement];
		if ([results count] < 1U) {
//			NSLog(@"No results");
		} else {
//			NSLog(@"Found some!, filtering...");
			NSMutableArray *resultsInfo = [NSMutableArray arrayWithCapacity:[results count]];

			NSEnumerator *resultsEnum = [results objectEnumerator];
			DOMElement *result;

			while ((result = [resultsEnum nextObject])) {
				DOMElement *nameElement = [[result childElementsByTagName:@"ProductName"] objectAtIndex:0U];
				DOMElement *artistElement = [[[[result childElementsByTagName:@"Artists"] objectAtIndex:0U] childElementsByTagName:@"Artist"] objectAtIndex:0U];

				//we want the biggest artwork we can get.
				DOMElement *artworkElement = [[result childElementsByTagName:@"ImageUrlLarge"] objectAtIndex:0U];
				if(!artworkElement) {
					artworkElement = [[result childElementsByTagName:@"ImageUrlMedium"] objectAtIndex:0U];
					if(!artworkElement)
						artworkElement = [[result childElementsByTagName:@"ImageUrlSmall"] objectAtIndex:0U];
				}

				//Now create usable stuff from the elements
				NSString *artworkURL = [artworkElement textContent];
				NSString *albumName  = [nameElement textContent];

				//If the artist element contains our wanted artist, look for it!
				if ([artistElement containsChild:[DOMText textWithString:artistName]]) {
					NSArray *allArtists = [artistElement children];
					NSEnumerator *artistEnum = [allArtists objectEnumerator];
					while((artistElement = [artistEnum nextObject])) {
						NSString *textContent = [artistElement textContent];
						if ([textContent isEqualToString:artistName]) {
							artistName = textContent;
							break;
						}
					}
				} else {
					//we didn't find anyone interesting, so just use the first one.
					artistName = [[artistElement firstChild] textContent];
				}

				NSDictionary *productInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					albumName,  @"name",
					artworkURL, @"artworkURL",
					artistName, @"artist",
					nil];

				[resultsInfo addObject:productInfo];
			}
			return resultsInfo;
		}
	}
	return nil;
}

- (NSDictionary *)getAlbum:(NSString *)albumName byArtist:(NSString *)artistName {
	//Now that we have all the info we need, we can decide which result to use.
	BOOL found = NO; //This var is set to YES once we finally select the album to use.

	NSArray *matches = [self getAlbumsByArtist:artistName];
	unsigned numMatches = [matches count];

	NSMutableArray *resultCandidates = [NSMutableArray arrayWithCapacity:numMatches];
	NSDictionary *result = nil;

	NSEnumerator *matchEnum = [matches objectEnumerator];
	NSDictionary *match;

	while((match = [matchEnum nextObject])) {
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
- (NSData *)queryAmazon:(NSString *)query {
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

- (NSData *)download:(NSURL *)url {
	NSLog(@"Go go interweb: %@", url);

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
	if(error)
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
	if(!chars) {
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
		if(isspace(chars[i])) break;
	for (; i > 0U; --i) {
		if(!isspace(chars[i])) {
			++i;
			break;
		}
	}

	free(chars);
	return i ? [fullAlbumName substringToIndex:i] : [[fullAlbumName retain] autorelease];
}

@end
