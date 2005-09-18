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

#import "AtomReader.h"
#import "Feed.h"
#import "Article.h"
#import "NSString+KNTruncate.h"
#import "NSDictionary+KNExtras.h"

#define AtomAlternateLink @"alternate"
#define AtomParserFailed @"AtomDownloadFailed"

@implementation AtomReader

-(void)parser:(NSXMLParser *)aParser parseErrorOccurred:(NSError *)error{
	validSource = NO;
	[self setReaderError: @"Invalid XML for source"];
	[NSException raise: AtomParserFailed format: @"Invalid XML for source (line %d)", [aParser lineNumber]];
}

-(void)parser:(NSXMLParser *)aParser didStartElement:(NSString *)element
	namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)atts{
	
	NSEnumerator *				enumerator;
	NSString *					attKey;
	
	
	if( currentContainer ){
		if( [currentContainer isEqualToString: @"content"] || [currentContainer isEqualToString: @"summary"]){
			[currentBuffer appendFormat: @"<%@ ", element];
			enumerator = [atts keyEnumerator];
			while( attKey = [enumerator nextObject] ){
				[currentBuffer appendFormat: @"%@=\"%@\" ", attKey, [atts objectForKey: attKey]];
			}
			[currentBuffer appendString: @">"];
			return;
		}
	}
	
	//KNDebug(@"ATOM: start element %@", element);
	validSource = YES;
	if( [element isEqualToString: @"feed"] ){
		// No op!
	}else if( [element isEqualToString: @"entry"] ){
		if( currentArticle ){ [currentArticle release]; }
		currentArticle = [[NSMutableDictionary alloc] init];
	
	}else if( [element isEqualToString: @"link"] ){
		if( [[atts objectForKey: @"rel"] isEqualToString: @"alternate"] ){
			NSString *				href = ([atts objectForKey: @"href"]) ? [atts objectForKey: @"href"] : [NSString string];
			if( currentArticle ){
				[currentArticle setObject: href forKey: @"link"];
			}else{
				[feedData setObject: href forKey: @"link"];
			}
		}
	}else if( [element isEqualToString: @"author"] ){
		currentContainer = @"author";
	}else if( [element isEqualToString: @"content"] ){
		//KNDebug(@"ATOM: starting content container");
		currentContainer = @"content";
	}else if( [element isEqualToString: @"summary"] ){
		currentContainer = @"summary";
	}
	
	if( currentBuffer ){ [currentBuffer release]; }
	currentBuffer = [[NSMutableString alloc] init];
}

-(void)parser:(NSXMLParser *)aParser foundCharacters:(NSString *)string{
	if( string != nil ){
		if( ! currentBuffer ){ currentBuffer = [[NSMutableString alloc] init]; }
		//[currentBuffer appendString: [string trimWhitespace]];
		[currentBuffer appendString: string];
	}
}

-(void)parser:(NSXMLParser *)aParser didEndElement:(NSString *)element namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName{
	NSMutableDictionary *			dest;
	
	
	if( currentContainer && [currentContainer isEqualToString: @"content"] && ![element isEqualToString:@"content"] ){
		[currentBuffer appendFormat: @"</%@>", element];
		return;
	}
	if( currentContainer && [currentContainer isEqualToString: @"summary"] && ![element isEqualToString:@"summary"] ){
		[currentBuffer appendFormat: @"</%@>", element];
		return;
	}
	
	//KNDebug(@"ATOM: end element %@", element);
	if( currentArticle ){
		dest = currentArticle;
	}else{
		dest = feedData;
	}
	
	if( [element isEqualToString:@"title"] ){
		[dest setObject: [currentBuffer collapseWhitespace] forKey: @"title"];
	
	}else if( [element isEqualToString: @"id"] ){
		[dest setObject: [currentBuffer collapseWhitespace] forKey: @"id"];
		
	}else if( [element isEqualToString: @"created"] ){
		[dest setObject: [currentBuffer collapseWhitespace] forKey: @"created"];
	
	}else if( [element isEqualToString: @"tagline"] ){
		[dest setObject: [currentBuffer collapseWhitespace] forKey: @"tagline"];
	
	}else if( [element isEqualToString: @"author"] ){
		currentContainer = nil;
	
	}else if( [element isEqualToString: @"name"] && currentContainer && [currentContainer isEqualToString: @"author"] ){
		[dest setObject: [currentBuffer collapseWhitespace] forKey: @"author"];
		
	}else if( [element isEqualToString: @"content"] ){
		//KNDebug(@"ATOM: ending content container");
		currentContainer = nil;
		[currentArticle setObject: [currentBuffer collapseWhitespace] forKey: @"content"];
		
	}else if( [element isEqualToString: @"summary"] ){
		currentContainer = nil;
		[currentArticle setObject: [currentBuffer collapseWhitespace] forKey: @"summary"];
		
	}else if( [element isEqualToString: @"entry"] ){
		if( currentArticle ){
			[newArticles addObject: currentArticle];
			[currentArticle release];
			currentArticle = nil;
		}
	}
	
	[currentBuffer release];
	currentBuffer = nil;
}

-(BOOL)insulateContent{
	NSMutableString *				sourceXML = nil;
	NSString *						openTag = nil;
	NSRange							openStartRange, openEndRange, openRange, closeRange, remainingRange;
	BOOL							didInsulate = NO;
	
	if( incomingData ){
		sourceXML = [[NSMutableString alloc] initWithData: incomingData encoding: NSUTF8StringEncoding];
		
		openStartRange = [sourceXML rangeOfString:@"<content" options:NSCaseInsensitiveSearch];
		while( openStartRange.location != NSNotFound ){
			remainingRange = NSMakeRange( 
				openStartRange.location + openStartRange.length, 
				[sourceXML length] - (openStartRange.location + openStartRange.length) 
			);
			openEndRange = [sourceXML rangeOfString:@">" options: NSLiteralSearch range: remainingRange];
			if( openEndRange.location == NSNotFound ){ break; }
			
			openRange = NSMakeRange(
				openStartRange.location,
				(openEndRange.location - openStartRange.location) + openEndRange.length
			);
			openTag = [sourceXML substringWithRange: openRange];
			[sourceXML replaceCharactersInRange: openRange withString:[NSString stringWithFormat: @"%@<![CDATA[", openTag]];
			
			remainingRange = NSMakeRange(
				openRange.location + openRange.length + 9,
				[sourceXML length] - (openRange.location + openRange.length + 9)
			);
			closeRange = [sourceXML rangeOfString:@"</content>" options: NSCaseInsensitiveSearch range: remainingRange];
			if( closeRange.location == NSNotFound ){ break; }
			[sourceXML replaceCharactersInRange: closeRange withString: @"]]></content>"];
			
			remainingRange = NSMakeRange(
				closeRange.location + closeRange.length + 3,
				[sourceXML length] - (closeRange.location + closeRange.length + 3)
			);
			openStartRange = [sourceXML rangeOfString: @"<content" options: NSCaseInsensitiveSearch range: remainingRange];
		}
		
		if( didInsulate ){
			[incomingData release];
			incomingData = [[sourceXML dataUsingEncoding: NSUTF8StringEncoding] retain];
		}
		[sourceXML release];
	}
	return didInsulate;
}


-(void)setDetailsFromDict:(NSDictionary *)dict{
	[details setObject: FeedTypeAtom forKey: FeedType];
	
	//KNDebug(@"ATOM: setDetailsFromDict");
	
	if( [dict objectForKey:@"title"] ){
		[details setObject: [dict objectForKey:@"title"] forKey: FeedTitle];
	}
	if( [dict objectForKey:@"tagline"] ){
		[details setObject: [dict objectForKey:@"tagline"] forKey: FeedSummary];
	}
	if( [dict objectForKey:@"link"] ){
		[details setObject: [dict objectForKey:@"link"] forKey: FeedLink];
	}
}

-(NSString *)keyOfArticle:(NSDictionary *)article{
	NSString *					key;
	NSDictionary *				hashDict;
	
	//KNDebug(@"ATOM: keyOfArticle %@", article);
	
	if( [article objectForKey: @"id"] ){
		key = [NSString stringWithString: [article objectForKey: @"id"]];
	}else{
		hashDict = [NSDictionary dictionaryWithObjectsAndKeys:
						[self titleOfArticle: article], @"title",
						/* [self contentOfArticle: article], @"content", */
						[self linkOfArticle: article], @"link",
					nil];
		key = [hashDict md5];
	}
	//KNDebug(@"ATOM: key is %@", key);
	return key;
}

-(NSString *)titleOfArticle:(NSDictionary *)article{
	//KNDebug(@"UPDATE: atom title parse %@ (%@)", article, [article objectForKey: @"title"]);
	if( [article objectForKey: @"title"] ){
		//NSString * title = [article objectForKey:@"title"];
		//KNDebug(@"UPDATE: title is %@", title);
		//NSString * collapsedString = [[article objectForKey: @"title"] collapseHTML];
		//KNDebug(@"UPDATE: collapsed title: %@", collapsedString);
		return [NSString stringWithString: [[article objectForKey: @"title"] collapseHTML]];
	}else{
		return [NSString string];
	}
}

-(NSString *)contentOfArticle:(NSDictionary *)article{
	NSString *				content = [NSString string];
	
	//KNDebug(@"ATOM: atom content parse");
	
	if( [article objectForKey:@"content"] ){
		content = [article objectForKey: @"content"];
	}else if( [article objectForKey: @"summary"] ){
		content = [article objectForKey: @"summary"];
	}
	
	return content;
}

-(NSString *)authorOfArticle:(NSDictionary *)article{
	//KNDebug(@"UPDATE: atom author parse");
	
	if( [article objectForKey: @"author"] ){
		return [NSString stringWithString: [article objectForKey: @"author"]];
	}else{
		return [NSString string];
	}
}


-(NSDate *)dateOfArticle:(NSDictionary *)article{
	//KNDebug(@"UPDATE: atom date parse");
	NSDate *			date = nil;
	if( [article objectForKey:@"created"] ){
		date = [NSDate dateWithNaturalLanguageString: [article objectForKey:@"created"]];
	}
	if( date == nil ){ date = [NSDate date]; }
	return date;
}

-(NSString *)linkOfArticle:(NSDictionary *)article{
	//KNDebug(@"UPDATE: atom link parse");
	if( [article objectForKey: @"link"] ){
		return [NSString stringWithString: [article objectForKey: @"link"]];
	}else{
		return [NSString string];
	}
}

@end
