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

#import "TestArticle.h"
#import "KNArticle.h"

@implementation TestArticle

-(void)testArticleCreation{
	KNArticle *			anArticle = [[KNArticle alloc] init];
	STAssertNotNil( anArticle, @"Could not create Article instance");
	[anArticle release];
}

-(void)testSetProperties{
	KNArticle *				anArticle = [[KNArticle alloc] init];
	NSAttributedString *	aTitle = [[NSAttributedString alloc] initWithString:@"Article Title"];
	
	[anArticle setTitle:aTitle];
	STAssertEqualObjects(aTitle, [anArticle title], @"Title didn't stick");
	STAssertEqualObjects([aTitle string], [anArticle name], @"Title didn't match name");
	
	[anArticle setStatus:StatusRead];
	STAssertEqualObjects(StatusRead, [anArticle status], @"Status didn't stick");
	[anArticle setLink: @"http://keeto.net/item.html?id=1"];
	STAssertEqualObjects(@"http://keeto.net/item.html?id=1", [anArticle link], @"Link didn't stick");
	[anArticle setSourceURL: @"http://keeto.net/item.html?id=1"];
	STAssertEqualObjects(@"http://keeto.net/item.html?id=1", [anArticle sourceURL], @"Source URL didn't stick");
	[anArticle setCommentsURL: @"http://keeto.net/item.html?id=1"];
	STAssertEqualObjects(@"http://keeto.net/item.html?id=1", [anArticle commentsURL], @"Comments URL didn't stick");
	[anArticle setAuthor: @"Keith Anderson <keith@keeto.net>"];
	STAssertEqualObjects(@"Keith Anderson <keith@keeto.net>", [anArticle author], @"Author didn't stick");
	NSDate *			aDate = [NSDate date];
	[anArticle setDate: aDate];
	STAssertEqualObjects( aDate, [anArticle date], @"Date didn't stick");
	[anArticle setCategory: @"Feed"];
	STAssertEqualObjects( @"Feed", [anArticle category], @"Category didn't stick");
	[anArticle setSummary:@"Summary"];
	STAssertEqualObjects(@"Summary", [anArticle summary], @"Summary didn't stick");
	[anArticle setContent:@"Content of article."];
	STAssertEqualObjects(@"Content of article.", [anArticle content], @"Content didn't stick");
	
	STAssertThrows( [anArticle setTitle: nil], @"Setting nil title didn't throw");
	STAssertThrows( [anArticle setStatus: nil], @"Setting nil status didn't throw");
	STAssertThrows( [anArticle setStatus: @"Foo"], @"Setting unknown status didn't throw");
	STAssertThrows( [anArticle setLink: nil], @"Setting nil link didn't throw");
	STAssertThrows( [anArticle setSourceURL: nil], @"Setting nil source URL didn't throw");
	STAssertThrows( [anArticle setCommentsURL: nil], @"Setting nil comments URL didn't throw");
	STAssertThrows( [anArticle setDate: nil], @"Setting nil date didn't throw");
	STAssertThrows( [anArticle setCategory: nil], @"Setting nil category didn't throw");
	STAssertThrows( [anArticle setSummary: nil], @"Setting nil summary didn't throw");
	STAssertThrows( [anArticle setContent: nil], @"Setting nil content didn't throw");
}

-(void)testArchiving{
	KNArticle *				sourceArticle = [[KNArticle alloc] init];
	NSMutableData *			data = [NSMutableData data];
	NSKeyedArchiver *		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData: data];
	NSAttributedString *	aTitle = [[[NSAttributedString alloc] initWithString:@"Article Title"] autorelease];
	
	
	[sourceArticle setTitle:aTitle];
	[sourceArticle setStatus:StatusRead];
	[sourceArticle setLink: @"http://keeto.net/item.html?id=1"];
	[sourceArticle setSourceURL: @"http://keeto.net/item.html?id=1"];
	[sourceArticle setCommentsURL: @"http://keeto.net/item.html?id=1"];
	[sourceArticle setAuthor: @"Keith Anderson <keith@keeto.net>"];
	[sourceArticle setDate: [NSDate date]];
	[sourceArticle setCategory: @"Feed"];
	[sourceArticle setSummary:@"Summary"];
	[sourceArticle setContent:@"Content of article."];
	
	[archiver encodeObject: sourceArticle forKey:@"root"];
	[archiver finishEncoding];
	[archiver release];
	
	KNArticle *				restoredArticle = [NSKeyedUnarchiver unarchiveObjectWithData: data];
	
	STAssertEqualObjects([restoredArticle title], [sourceArticle title], @"Title didn't stick");
	STAssertEqualObjects([restoredArticle status], [sourceArticle status], @"Status didn't stick");
	STAssertEqualObjects([restoredArticle link], [sourceArticle link], @"Link didn't stick");
	STAssertEqualObjects([restoredArticle sourceURL], [sourceArticle sourceURL], @"Source URL didn't stick");
	STAssertEqualObjects([restoredArticle commentsURL], [sourceArticle commentsURL], @"Comments URL didn't stick");
	STAssertEqualObjects([restoredArticle author], [sourceArticle author], @"Author didn't stick");
	STAssertEqualObjects([restoredArticle date], [sourceArticle date], @"Date didn't stick");
	STAssertEqualObjects([restoredArticle category], [sourceArticle category], @"Category didn't stick");
	STAssertEqualObjects([restoredArticle summary], [sourceArticle summary], @"Summary didn't stick");
	STAssertEqualObjects([restoredArticle content], [sourceArticle content], @"Content didn't stick");
	
	[sourceArticle release];
}

@end
