/*

BSD License

Copyright (c) 2005, Keith Anderson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice,
	this list of conditions and the following disclaimer in the documentation
	and/or other materials provided with the distribution.
*	Neither the name of keeto.net or Keith Anderson nor the names of its
	contributors may be used to endorse or promote products derived
	from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


*/

#import "TestFeed.h"
#import "KNFeed.h"


@implementation TestFeed

-(void)testFeedCreation{
	KNFeed *			aFeed = [[KNFeed alloc] init];
	STAssertNotNil( aFeed, @"Could not create Feed instance");
	[aFeed release];
}

-(void)testSetProperties{
	KNFeed *			aFeed = [[KNFeed alloc] init];
	
	// set and check normal properties
	[aFeed setSourceURL:@"http://keeto.net/rss.xml"];
	STAssertEqualObjects( @"http://keeto.net/rss.xml", [aFeed sourceURL], @"Source URL didn't stick");
	[aFeed setSourceType:FeedSourceTypeRSS];
	STAssertEqualObjects( FeedSourceTypeRSS, [aFeed sourceType], @"Source type didn't stick");
	[aFeed setFaviconURL:@"http://keeto.net/favicon.ico"];
	STAssertEqualObjects(@"http://keeto.net/favicon.ico", [aFeed faviconURL], @"Favicon URL didn't stick");
	[aFeed setSummary:@"Summary"];
	STAssertEqualObjects(@"Summary", [aFeed summary], @"Summary didn't stick");
	[aFeed setLink: @"http://keeto.net"];
	STAssertEqualObjects(@"http://keeto.net", [aFeed link], @"Link didn't stick");
	[aFeed setLastError:@"Unable to load: 404 Not Found"];
	STAssertEqualObjects(@"Unable to load: 404 Not Found", [aFeed lastError], @"Error didn't stick");
	[aFeed setImageURL:@"http://keeto.net/images/header.gif"];
	STAssertEqualObjects(@"http://keeto.net/images/header.gif", [aFeed imageURL], @"Image URL didn't stick");
	
	// make sure errors are thrown
	STAssertThrows( [aFeed setSourceURL: nil] , @"Setting nil source URL did not throw");
	STAssertThrows( [aFeed setSourceType: nil], @"Setting nil source type did not throw");
	STAssertThrows( [aFeed setSourceType: @"Foo"], @"Setting unknown source type did not throw");
	STAssertThrows( [aFeed setFaviconURL: nil] , @"Setting nil favicon URL did not throw");
	STAssertThrows( [aFeed setSummary: nil] , @"Setting nil summary did not throw");
	STAssertThrows( [aFeed setLink: nil] , @"Setting nil link did not throw");
	STAssertThrows( [aFeed setLastError: nil] , @"Setting nil error did not throw");
	STAssertThrows( [aFeed setImageURL: nil], @"Setting nil image URL did not throw");
	
	[aFeed release];
}

-(void)testArchiving{
	KNFeed *					sourceFeed = [[KNFeed alloc] init];
	NSMutableData *			data = [NSMutableData data];
	NSKeyedArchiver *		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	
	[sourceFeed setSourceURL:@"http://keeto.net/rss.xml"];
	[sourceFeed setSourceType:FeedSourceTypeRSS];
	[sourceFeed setFaviconURL:@"http://keeto.net/favicon.ico"];
	[sourceFeed setSummary:@"Summary"];
	[sourceFeed setLink: @"http://keeto.net/"];
	[sourceFeed setLastError: @"Unable to load: 404 Not Found"];
	[sourceFeed setImageURL:@"http://keeto.net/images/header.gif"];
	
	[archiver encodeObject: sourceFeed forKey:@"root"];
	[archiver finishEncoding];
	[archiver release];
	
	KNFeed *				restoredFeed = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	
	STAssertEqualObjects( sourceFeed, restoredFeed, @"Archiving did not produce equal Feeds");
	STAssertEqualObjects( [sourceFeed sourceURL], [restoredFeed sourceURL], @"Source URL did not survive archiving");
	STAssertEqualObjects( [sourceFeed sourceType], [restoredFeed sourceType], @"Source type did not survive archiving");
	STAssertEqualObjects( [sourceFeed faviconURL], [restoredFeed faviconURL], @"Favicon URL did not survive archiving");
	STAssertEqualObjects( [sourceFeed summary], [restoredFeed summary], @"Summary did not survive archiving");
	STAssertEqualObjects( [sourceFeed link], [restoredFeed link], @"Link did not survive archiving");
	STAssertEqualObjects( [sourceFeed lastError], [restoredFeed lastError], @"Last error did not survive archiving");
	STAssertEqualObjects( [sourceFeed imageURL], [restoredFeed imageURL], @"Image URL did not survive archiving");
	
	[sourceFeed release];
}

@end
