//
//  GrowlTunes-Amazon.m
//  GrowlTunes-Amazon
//
//  Created by Karl Adam on 9/29/04.
//  Copyright 2004 matrixPointer. All rights reserved.
//

#import "GrowlTunes-Amazon.h"

/* Based On Code Originally submitted by James Van Dyne */
/*	Updated for the v4 Amazon API with code from Fjölnir Ásgeirsson	*/

#ifndef MAC_OS_X_VERSION_10_4 > MAC_OS_X_VERSION_MAX_ALLOWED
	int NSXMLDocumentTidyXML = 1 << 10;  //  Correct value goes here.
#endif

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

- (NSImage *)artworkForTitle:(NSString *)newSong 
					byArtist:(NSString *)newArtist 
					 onAlbum:(NSString *)newAlbum 
			   isCompilation:(BOOL)newCompilation;
{	
//	NSLog(@"Called getArtwork");
	artist = newArtist;
	album = newAlbum;
	song = newSong;
	compilation = newCompilation;

	/*If the album is a compilation, we don't look for the artist;
	 *	instead we look for all compilations.
	 */
	if(compilation)
		artist = @"compilation"; 

	artwork = nil;
	NSLog( @"Go go interweb (%@ by %@ from %@)", song, artist, album );
	NSDictionary *albumInfo = [self getAlbum:album byArtist:artist];

	NSData *imageData = nil;
	if([(NSString *)[albumInfo objectForKey:@"artworkURL"] length] != 0) {
		@try
		{
			imageData = [self download:[NSURL URLWithString:[albumInfo objectForKey:@"artworkURL"]]];
		}
		@catch(NSException *e)
		{
			NSLog(@"Exception occurred while downloading %@", [e reason]);
		}
	}
	if( imageData ) {
		artwork = [[(NSImage *)[NSImage alloc] initWithData:imageData] autorelease];
	}
	return artwork;
}

#pragma mark -
#pragma mark Amazon searching methods

- (NSArray *)getAlbumsByArtist:(NSString *)artistName {
	NSString *query = [[NSString stringWithFormat:@"?locale=us&t=0C8PCNE1KCKFJN5EHP02&dev-t=0C8PCNE1KCKFJN5EHP02&ArtistSearch=%@&mode=music&sort=+salesrank&offer=All&type=lite&page=1&f=xml", artistName] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *result = [self queryAmazon:query];
	
	if(result) {
		NSString *xml = result;
		// Parse the XML into a DOM object document
		NSData *XMLData = [xml dataUsingEncoding:NSUTF8StringEncoding];
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
		
		//Get the details of all found products
		DOMXPathExpression *resultQuery = [DOMXPathExpression expressionWithString:@"//Details"];
		NSArray *results = [resultQuery matchesForContextNode:rootElement];
		if([results count] < 1U) {
//			NSLog(@"No results");
		} else {
//			NSLog(@"Found some!, filtering...");
			NSMutableArray *resultsInfo = [NSMutableArray arrayWithCapacity:[results count]];
			
			NSEnumerator *resultsEnum = [results objectEnumerator];
			DOMElement *result;

			while((result = [resultsEnum nextObject])) {
				DOMElement    *nameElement = [[result getElementsByTagName:@"ProductName"]   objectAtIndex:0U];
				//We want the biiig artwork ;-)
				DOMElement *artworkElement = [[result getElementsByTagName:@"ImageUrlLarge"] objectAtIndex:0U];
				DOMElement  *artistElement = nameElement;
				
				//Now create usable stuff from the elements
				NSString *artworkURL = [artworkElement textContent];
				NSString *albumName  = [nameElement textContent];
				NSString *artistName = nil;

				//If the artist element contains our wanted artist, look for it!
				if([artistElement containsChild:[DOMText textWithString:artist]]) {
					NSArray *allArtists = [artistElement children];
					NSEnumerator *artistEnum = [allArtists objectEnumerator];
					while((artistElement = [artistEnum nextObject])) {
						NSString *textContent = [artistElement textContent];
						if([textContent isEqualToString:artist]) {
							artistName = textContent;
							break;
						}
					}
				} else {
					//we didn't find anyone interesting, so just use the first one.
					artistName = [[artistElement firstChild] textContent];
				}
				
				//NSLog(@"Path to artwork: %@ For album: %@", artworkURL, albumName);

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
		BOOL   nameIsEqual = ([[match objectForKey:@"name"] caseInsensitiveCompare:album] == NSOrderedSame);
		BOOL artistIsEqual = ([[match objectForKey:@"artist"] caseInsensitiveCompare:artist] == NSOrderedSame);

		if(nameIsEqual) {
			//Check if both the artist and name match
			if(artistIsEqual) {
				//this is the one we want.
				result = match;
				found = YES;

				break;
			} else
				[resultCandidates addObject:match];
		}
	}
	if(!found) {
		if([resultCandidates count]) {
			/*Now we just select the first match.
			 *We didn't do that in the first loop because we want to loop
			 *	through ALL albums to make sure we get the PERFECT match
			 *	if it's there.
			 */
			result = [resultCandidates objectAtIndex:0U];
			found = YES;
/*			NSLog(@"SELECTED: Path to artwork: %@ For album: %@", [theResult objectForKey:@"artworkURL"], 
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
- (NSString *)queryAmazon:(NSString *)query {	
	NSString *search = [@"http://xml.amazon.com/onca/xml3" stringByAppendingString:query];
	NSURL *url = [NSURL URLWithString:search];
//	NSLog(@"searchpath: %@", search);
	
	// Do the search on AWS
	NSData *data = [self download:url];
	if(!data)
		NSLog(@"Error while getting XML Response from Amazon");
	else {
//		NSLog(@"Got response");
		return [[[NSString alloc] initWithData:data
		                              encoding:NSUTF8StringEncoding] autorelease];
	}
	return nil;
}

#pragma mark -
#pragma mark Accessors

- (NSString *)artist {
	return artist;
}
- (NSString *)album {
	return album;
}
- (NSString *)song {
	return song;
}
- (BOOL)compilation {
	return compilation;
}
- (NSImage *)artwork {
	return artwork;
}

#pragma mark -
#pragma mark Other cool stuff

- (NSData *)download:(NSURL *)url {
	NSLog(@"Go go interweb: %@", url);
	NSError *error = nil;
	NSURLResponse *response = nil;
	NSURLRequest *request = nil;
	request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	return data;
}

@end
