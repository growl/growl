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

-(BOOL)usesNetwork
{
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
	
	// If the album is a compilation, we don't look for the artist,
	// Instead we look for all compilations
	if(compilation)
	{
		artist = @"compilation"; 
	}
	
	artwork = nil;
	NSLog( @"Go go interweb (%@ by %@ from %@)", song, artist, album );
	NSDictionary *albumInfo = [self getAlbum:album byArtist:artist];
	
	NSData *imageData = nil;
	if([albumInfo objectForKey:@"artworkURL"] != nil)
	{
		@try
	{
		imageData = [self download:[NSURL URLWithString:[albumInfo objectForKey:@"artworkURL"]]];
	}
		@catch(NSException *e)
	{
			NSLog(@"Exception occurred while downloading %@", [e reason]);
	}
	}
	artwork = [[NSImage alloc] initWithData: imageData];
	return artwork;
}

#pragma mark -
#pragma mark AMAZON SEARCHING METHODS

- (NSArray *)getAlbumsByArtist:(NSString *)artistName
{
	NSString *query = [[NSString stringWithFormat:@"?locale=us&t=0C8PCNE1KCKFJN5EHP02&dev-t=0C8PCNE1KCKFJN5EHP02&ArtistSearch=%s&mode=music&sort=+salesrank&offer=All&type=lite&page=1&f=xml", [artistName UTF8String]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSString *result = [self queryAmazon:query];
	
	if(result != nil)
	{
		// *** Now we get down and dirty! ***
		NSString *xml = [NSString stringWithString:result];
		// Parse the XML into a DOM object document
		NSData *XMLData = [NSData dataWithData:[xml dataUsingEncoding:NSUTF8StringEncoding]];
		DOMBuilder *builder = [DOMBuilder defaultBuilder];
		
		DOMDocument *document;
		@try
		{
			document = [builder buildFromData:XMLData];
		}
		// If the response was malformed we get an exception, catch it and return NIL
		@catch(NSException *e)
		{
			NSLog(@"An exception occurred while parsing XML data (It was probably malformed)\nREASON: %@", [e reason]);
			return nil;
		}
		
		DOMElement *rootElement = [document documentElement]; // Get the root element
		
		// *** Get the details of all found products ***
		DOMXPathExpression *resultQuery = [DOMXPathExpression expressionWithString:@"//Details"];
			NSArray *results = [resultQuery matchesForContextNode:rootElement];
			if([results count] < 1)
			{
//				NSLog(@"No results");
			}
			else
			{
//				NSLog(@"Found some!, filtering...");
				NSMutableArray *resultsInfo = [[NSMutableArray alloc] init]; // This array stores info for all results
				
				NSMutableDictionary *productInfo; // Stores the info to be stored for the current result
				NSArray *detailChildren; // Contains the details of the current product
				DOMElement *nameElement; // The name element of the current result
				DOMElement *artworkElement; // The artwork element of the current result
				DOMElement *artistElement; // The artist element of the current result
				NSArray *allArtists; // Used to store all of the artists, while we look for the artist we want
				NSString *artworkURL; // URL to the current artwork
				NSString *albumName; // Current album name
				NSString *artistName; // Current artist name
				unsigned int i;
				for(i = 0; i < [results count]; ++i)
				{
					detailChildren = [[results objectAtIndex:i] children];
					
					// *** Get elements with info on the current result ***
					nameElement = [[[results objectAtIndex:i] getElementsByTagName:@"ProductName"] objectAtIndex:0];
					// We want the biiig artwork ;-) (I was going to use leetsp33k for this comment but backed out)
					artworkElement = [[[results objectAtIndex:i] getElementsByTagName:@"ImageUrlLarge"] objectAtIndex:0];
					artistElement = [[[results objectAtIndex:i] getElementsByTagName:@"ProductName"] objectAtIndex:0];
					
					// *** Create usable stuff from the elements ***
					artworkURL = [artworkElement textContent];
					albumName = [nameElement textContent];
					// Find the artist that we most likely want
					if([artistElement containsChild:[DOMText textWithString:artist]])
					{
						// If the artist element contains our wanted artist, Look for it!
						allArtists = [artistElement children];
						unsigned int x;
						for(x = 0; x < [allArtists count]; ++x)
						{
							if([[[allArtists objectAtIndex:x] textContent] isEqualToString:artist])
							{
								artistElement = [allArtists objectAtIndex:x];
								artistName = [[allArtists objectAtIndex:x] textContent];
								
								break; // GIT OUT!
							}
						}
					}
					// If we didn't find anyone interesting we use the first one.
					else
					{
						artistName = [[artistElement firstChild] textContent];
					}
					
					//NSLog(@"Path to artwork: %@ For album: %@", artworkURL, albumName);
					
					// *** Add us to the array!! ***
					productInfo = [[NSMutableDictionary alloc] init]; // Initialize.
					[productInfo setObject:albumName forKey:@"name"];
					[productInfo setObject:artworkURL forKey:@"artworkURL"];
					[productInfo setObject:artistName forKey:@"artist"];
					
					[resultsInfo addObject:productInfo];
			}
				return resultsInfo;
		}
	}
	return nil;
}

- (NSDictionary *)getAlbum:(NSString *)albumName byArtist:(NSString *)artistName
{
	// *** Now that we have all info we need. we decide which result to use.. ***
	NSArray *resultsInfo = [self getAlbumsByArtist:artistName];
	BOOL found = NO; // This var is set to YES once we finally select the album to use...
	NSDictionary *theResult = nil; // Our FINAL result!! (finally)
	
	NSMutableArray *likelyMatches = [[NSMutableArray alloc] init];
	NSDictionary *currentResult;
	BOOL artistMatches;
	BOOL nameMatches;
	unsigned int i;
	for(i = 0; i <= [resultsInfo count]; ++i)
	{
		// If i is less than the count we are still searching
		if(i < [resultsInfo count])
		{
			currentResult = [resultsInfo objectAtIndex:i];
			nameMatches = NO;
			artistMatches = NO;
			if([[currentResult objectForKey:@"name"] caseInsensitiveCompare:album] == NSOrderedSame)
			{
				nameMatches = YES;
			}
			if([[currentResult objectForKey:@"artist"] caseInsensitiveCompare:artist] == NSOrderedSame)
			{
				artistMatches = YES;
			}
			
			// Check if both the artist and name match
			if(nameMatches && artistMatches)
			{
				// If it matches we stop searching, go out for a hotdog and let the code do the rest
				album = [NSDictionary dictionaryWithDictionary:currentResult];
				found = YES;
				
				[likelyMatches release]; // We don't need this now do we? ;-)
				
				break;
			}
			else if(nameMatches)
			{
				[likelyMatches addObject:currentResult];
			}
		}
		// Otherwise we have to select from the likely matches.. (or none..)
		else
		{
			if([likelyMatches count] > 0)
			{
				// Now we just select the first match (If you're asking why we didn't do that in the first occurrance
				//                                      then you ain't that smart, we want to loop through ALL
				//                                      albums to make sure we get the PERFECT match if it's there)
				theResult = [NSDictionary dictionaryWithDictionary:[likelyMatches objectAtIndex:0]];
				found = YES;
/*				NSLog(@"SELECTED: Path to artwork: %@ For album: %@", [theResult objectForKey:@"artworkURL"], 
					  [theResult objectForKey:@"name"]);
*/
			}
			else
			{
				// No likely results found
//				NSLog(@"Found no likely albums in response");
			}
		}
	} // For()
	
	// WE'RE OUTTA THE LOOP!!, w00t!
	return theResult;
}


- (NSString *)queryAmazon:(NSString *)query // "query" is actually just the GET args after the address.
{	
	NSString *search = [@"http://xml.amazon.com/onca/xml3" stringByAppendingString:query];
	NSURL *url = [NSURL URLWithString:search];
//	NSLog(@"searchpath: %@", search);
	
	// Do the search on AWS
	NSData *data = [self download:url];
	if(data == nil)
	{
		NSLog(@"Error while getting XML Response from Amazon");
	}
	else
	{
//		NSLog(@"Got response");
		return [[NSString alloc] initWithData:data
									 encoding:NSUTF8StringEncoding];
	}
	return nil;
}



#pragma mark -
#pragma mark ACCESSOR METHODS
- (NSString *)artist
{
	return artist;
}
- (NSString *)album
{
	return album;
}
- (NSString *)song
{
	return song;
}
- (BOOL)compilation
{
	return compilation;
}
- (NSImage *)artwork
{
	return artwork;
}

#pragma mark -
#pragma mark OTHER METHHODS
- (NSData *)download:(NSURL *)url
{
	NSError *error = nil;
	NSURLResponse *response = nil;
	NSURLRequest *request = nil;
	request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.];
	NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	
	return data;
}

@end
