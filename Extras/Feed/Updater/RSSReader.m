/*

BSD License

Copyright (c) 2004, Keith Anderson
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

#import "RSSReader.h"
#import "KNFeed.h"
#import "KNArticle.h"
#import "NSString+KNTruncate.h"
#import "NSDictionary+KNExtras.h"

#define RSSParserFailed @"RSSParserFailed"


@implementation RSSReader

-(BOOL)parseXMLData:(NSData *)sourceXML{
	channelDone = NO;
	return [super parseXMLData: sourceXML];
}


-(void)parser:(NSXMLParser *)aParser foundComment:(NSString *)comment{
#pragma unused(aParser,comment)
	//KNDebug(@"RSS: Found comment: %@", comment);
}

-(void)parser:(NSXMLParser *)aParser parseErrorOccurred:(NSError *)error{
#pragma unused(aParser,error)
	//KNDebug(@"RSS: XML error (%@) at line %d column %d", error, [aParser lineNumber], [aParser columnNumber] );
	[self setReaderError:@"Invalid XML for source"];
	[NSException raise: RSSParserFailed format: @"Invalid XML for source (line %d)", [aParser lineNumber]];
}

-(void)parser:(NSXMLParser *)aParser didStartElement:(NSString *)element 
	namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)atts{
#pragma unused(aParser,nsURI,qName)
	
	//KNDebug(@"RSS: startElement %@", element);
	if( [element isEqualToString: @"channel"] ){
		validSource = YES;
		
	}else if( [element isEqualToString: @"item"] ){
		//KNDebug(@"RSS: found opening item");
		if( currentArticle ){ [currentArticle release]; }
		currentArticle = [[NSMutableDictionary alloc] init];
		
	}else if( [element isEqualToString: @"source"] && [atts objectForKey: @"url"] ){
		if( currentArticle ){
			[currentArticle setObject: [atts objectForKey:@"url"]  forKey: @"sourceURL"];
		}
	}
	
	if( currentBuffer ){ [currentBuffer release]; }
	currentBuffer = [[NSMutableString alloc] init];
}

-(void)parser:(NSXMLParser *)aParser foundCharacters:(NSString *)string{
#pragma unused(aParser)
	//KNDebug(@"RSS: foundCharacters: %@", string);
	if( string != nil ){
		if( ! currentBuffer ){ currentBuffer = [[NSMutableString alloc] init]; }
		//[currentBuffer appendString: [string trimWhitespace]];
		[currentBuffer appendString: string];
	}
}

-(void)parser:(NSXMLParser *)aParser foundIgnorableWhitespace:(NSString *)string{
#pragma unused(aParser,string)
	//KNDebug(@"RSS: found ignorable whitespace");
}

-(void)parser:(NSXMLParser *)aParser didEndElement:(NSString *)element namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName{
#pragma unused(aParser,nsURI,qName)
	//KNDebug(@"RSS: endElement %@", element);
	NSMutableDictionary *				dest = nil;
	
	if( currentArticle ){
		dest = currentArticle;
	}else if( ! channelDone ){
		dest = feedData;
	}
	
	if( [element isEqualToString: @"rss"] ){
		// No op
	}else if( [element isEqualToString: @"item"] ){
		//KNDebug(@"RSS: found closing item. Adding article %@", currentArticle);
		[newArticles addObject: currentArticle];
		[currentArticle release];
		currentArticle = nil;
		
	}else if( [element isEqualToString: @"channel"] ){
		//KNDebug(@"RSS: ### found ending channel ###");
		channelDone = YES;
	}else{
		if( currentBuffer && dest ){
			//KNDebug(@"RSS: adding content %@ to element %@", currentBuffer, [element stripNamespace]);
			//[dest setObject: currentBuffer forKey: [element stripNamespace] ];
			[dest setObject: [currentBuffer collapseWhitespace] forKey: element];
		}
	}
	
	[currentBuffer autorelease];
	currentBuffer = nil;
}

-(BOOL)insulateContent{
	NSMutableString *				sourceXML = nil;
	NSRange							openRange, closeRange, remainingRange;
	BOOL							didInsulate = NO;
	
	if( incomingData ){	
		sourceXML = [[NSMutableString alloc] initWithData: incomingData encoding: NSUTF8StringEncoding];
		//KNDebug(@"%@: about to insulate", self);
		
		openRange = [sourceXML rangeOfString:@"<description>" options: NSCaseInsensitiveSearch];
		while( openRange.location != NSNotFound ){
			
			remainingRange = NSMakeRange( 
				openRange.location + openRange.length,
				[sourceXML length] - (openRange.location + openRange.length)
			);
			
			closeRange = [sourceXML rangeOfString:@"</description>" options: NSCaseInsensitiveSearch range: remainingRange];
			
			if( closeRange.location != NSNotFound ){
				if( [sourceXML rangeOfString:@"<![CDATA[" options: NSCaseInsensitiveSearch range: NSMakeRange(remainingRange.location, 9)].location == NSNotFound ){
					[sourceXML replaceCharactersInRange: openRange withString:@"<description><![CDATA["];
					remainingRange = NSMakeRange(
						openRange.location + openRange.length + 9,
						[sourceXML length] - (openRange.location + openRange.length + 9)
					);
					closeRange = [sourceXML rangeOfString:@"</description>" options: NSCaseInsensitiveSearch range: remainingRange];
					[sourceXML replaceCharactersInRange: closeRange withString:@"]]></description>"];
					
					remainingRange = NSMakeRange(
						closeRange.location + closeRange.length + 3,
						[sourceXML length] - (closeRange.location + closeRange.length + 3)
					);
					didInsulate = YES;
				}
								
				remainingRange = NSMakeRange(
					closeRange.location + closeRange.length,
					[sourceXML length] - (closeRange.location + closeRange.length)
				);
				
				openRange = [sourceXML rangeOfString:@"<description>" options: NSCaseInsensitiveSearch range: remainingRange];
			}else{
				break;
			}
		}
		
		if( didInsulate ){
			[incomingData release];
			incomingData = [[sourceXML dataUsingEncoding: NSUTF8StringEncoding] retain];
			//KNDebug(@"%@: insulated content: %@", self, sourceXML);
		}
		[sourceXML release];
	}
	
	return didInsulate;
}



-(void)setDetailsFromDict:(NSDictionary *)dict{
	//KNDebug(@"RSS: setDetailsFromDict %@", dict);
	[details setObject: FeedSourceTypeRSS forKey: FeedSourceType];
	
	if( [dict objectForKey:@"title"] ){
		[details setObject: [dict objectForKey:@"title"] forKey: ItemName];
	}
	if( [dict objectForKey:@"description"] ){
		[details setObject: [dict objectForKey:@"description"] forKey: FeedSummary];
	}
	if( [dict objectForKey:@"link"] ){
		[details setObject: [dict objectForKey:@"link"] forKey: FeedLink];
	}
}

-(NSString *)keyOfArticle:(NSDictionary *)article{
	NSString *					key;
	NSDictionary *				hashDict;
	
	if( [article objectForKey: @"guid"] ){
		key = [article objectForKey: @"guid"];
	}else{
		hashDict = [NSDictionary dictionaryWithObjectsAndKeys:
						[self titleOfArticle: article], @"title",
						/* [self contentOfArticle: article], @"description", */
						[self linkOfArticle: article], @"link",
					nil];
					
		key = [hashDict md5];
	}
	return key;
}

-(NSAttributedString *)titleOfArticle:(NSDictionary *)article{
	if( [article objectForKey: @"title"] ){
		return [[[NSAttributedString alloc] initWithString: [[article objectForKey: @"title"] collapseHTML]] autorelease];
	}else{
		return [[[NSAttributedString alloc] init] autorelease];
	}
}

-(NSString *)contentOfArticle:(NSDictionary *)article{
    NSString *              content = [NSString string];
    
    if( [article objectForKey: @"description"] ){
        content = [article objectForKey: @"description"];
    }
	
	if( [article objectForKey: @"content:encoded"]){
		if( [[article objectForKey:@"content:encoded"] length] > [content length] ){
			content = [article objectForKey: @"content:encoded"];
		}
	}
    return [NSString stringWithString: content];
}

-(NSString *)authorOfArticle:(NSDictionary *)article{
    NSString *              author = [NSString string];
    
    if( [article objectForKey: @"author"] ){
        author = [NSString stringWithString: [article objectForKey: @"author"]];
    }else if( [article objectForKey: @"dc:creator"] ){
		author = [NSString stringWithString: [article objectForKey: @"dc:creator"]];
	}
    return author;
}

-(NSString *)sourceOfArticle:(NSDictionary *)article{
    NSString *              articleSource = [NSString string];
    
    if( [article objectForKey: @"source"] ){
        articleSource = [NSString stringWithString: [article objectForKey: @"source"]];
    }
    return articleSource;
}

-(NSString *)sourceURLOfArticle:(NSDictionary *)article{
	NSString *				articleSourceURL = [NSString string];
	
	if( [article objectForKey: @"sourceURL"] ){
		articleSourceURL = [NSString stringWithString: [article objectForKey: @"sourceURL"]];
	}
	return articleSourceURL;
}

-(NSString *)categoryOfArticle:(NSDictionary *)article{
    NSString *              category = [NSString string];
    
    if( [article objectForKey: @"category"] ){
        category = [NSString stringWithString: [article objectForKey: @"category"]];
    }else if( [article objectForKey: @"dc:subject"] ){
		category = [NSString stringWithString: [article objectForKey: @"dc:subject"]];
	}
    return category;
}

-(NSDate *)dateOfArticle:(NSDictionary *)article{
    NSDate *                date = nil;
    
	//KNDebug(@"RSS: dateOfArticle");
    if( [article objectForKey: @"pubDate"] ){
        // deal with all the different formats here. Dammit.
		//KNDebug(@"RSS: pubDate is %@", [article objectForKey: @"pubDate"]);
		date = [NSDate dateWithNaturalLanguageString: [article objectForKey: @"pubDate"]];
    }else if( [article objectForKey: @"dc:date"] ){
		//KNDebug(@"RSS: dc:date is %@", [article objectForKey: @"dc:date"]);
		NSString *dateString = [article objectForKey: @"dc:date"];
		NSRange range = [dateString rangeOfString:@"T"];
		if (range.location != NSNotFound ) {
			//KNDebug(@"RSS: stripping stuff");
			dateString = [[[dateString substringToIndex:range.location]
							stringByAppendingString:@" "]
							stringByAppendingString:[dateString substringFromIndex:range.location + range.length]];//KNDebug(@"RSS: otherNext");
			dateString = [[[[dateString substringToIndex:[dateString length] - 6]
							stringByAppendingString:@" "]
							stringByAppendingString:[dateString substringWithRange:NSMakeRange([dateString length] - 6, 3)]]
							stringByAppendingString:[dateString substringFromIndex:[dateString length] - 2]];
		}
		date = [NSDate dateWithNaturalLanguageString: dateString];
	}
	//KNDebug(@"RSS: found a date %@", date);
	//if( date == nil ){ date = [NSDate date]; }
    return date;
}

-(NSString *)linkOfArticle:(NSDictionary *)article{
    NSString *                 link = [NSString string];
	
	if( [article objectForKey: @"link"] ){
		link = [NSString stringWithString: [article objectForKey: @"link"]];
	}
    return link;
}

-(NSString *)commentsOfArticle:(NSDictionary *)article{
    NSString *                 link = [NSString string];
	
	if( [article objectForKey: @"comments"] ){
		link = [NSString stringWithString: [article objectForKey: @"comments"]];
	}
    return link;
}


@end
