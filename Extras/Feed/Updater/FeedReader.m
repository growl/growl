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

#import "FeedReader.h"
#import "FeedLibrary.h"
#import "Prefs.h"
#import "Feed.h"
#import "Article.h"

@implementation FeedReader

-(id)initWithLibrary:(FeedLibrary *)aLibrary source:(NSString *)aSource{
	self = [super init];
	if( self ){
		//KNDebug(@"%@: initWithLibrary", self);
		library = aLibrary;
		currentSource = [aSource retain];
		details = [[NSMutableDictionary alloc] init];
		articles = [[NSMutableArray alloc] init];
		incomingData = [[NSMutableData alloc] init];
		incomingIcon = [[NSMutableData alloc] init];
		readerError = [[NSString string] retain];
		
		dataConnection = nil;
		iconConnection = nil;
		
		parser = nil;
		feedData = [[NSMutableDictionary alloc] init];
		newArticles = [[NSMutableArray alloc] init];
		currentArticle = nil;
		currentBuffer = nil;
		validSource = NO;
		contentWasModified = NO;
		
		
		dataResponseCode = 400;
		NSMutableURLRequest *		request = nil;
		
		dataFinished = NO;
		[library willUpdateFeed: currentSource];
		
		request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString:currentSource] cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: [PREFS requestTimeoutInterval]];
		[request setValue:[PREFS userAgentString] forHTTPHeaderField:@"User-Agent"];
		
		dataConnection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
		if(! dataConnection ){
			KNDebug(@"%@: unable to start data connection", self);
			return nil;
		}
		//KNDebug(@"%@: started connection %@",self, aSource);
		
		
		
		
		NSURL *				url = [NSURL URLWithString: currentSource];
		NSURL *				imageURL = [[[NSURL alloc] initWithScheme: [url scheme] host: [url host] path:@"/favicon.ico"] autorelease];
		
		iconResponseCode = 400;
		iconFinished = NO;
		request = [NSMutableURLRequest requestWithURL: imageURL cachePolicy: NSURLRequestUseProtocolCachePolicy timeoutInterval: [PREFS requestTimeoutInterval]];
		[request setValue:[PREFS userAgentString] forHTTPHeaderField:@"User-Agent"];
		iconConnection = [[NSURLConnection alloc] initWithRequest: request delegate: self];
		if( ! iconConnection ){
			KNDebug(@"%@: unable to start icon connection", self);
			iconFinished = YES;
		}else{
			//KNDebug(@"%@: started icon %@",self, imageURL);
		}
	}
	return self;
}


-(void)dealloc{	
	[currentSource release];
	[details release];
	[articles release];
	[incomingData release];
	[incomingIcon release];
	[readerError release];
	
	[feedData release];
	[newArticles release];
	
	[super dealloc];
}

-(void)cancel{
	if( dataConnection ){
		[dataConnection cancel];
	}
	
	if( iconConnection ){
		[iconConnection cancel];
	}
}

-(NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse{
	//KNDebug(@"%@: redirecting request to %@", self, [request URL]);
	if( connection == dataConnection ){
		dataResponseCode = [(NSHTTPURLResponse *)redirectResponse statusCode];
	}else if( connection == iconConnection ){
		iconResponseCode = [(NSHTTPURLResponse *)redirectResponse statusCode];
	}
	return request;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	if( connection == dataConnection ){
		//KNDebug(@"%@: didReceiveResponse for %@ %d", self, [response URL], [(NSHTTPURLResponse *)response statusCode]);
		[incomingData setLength: 0];
		dataResponseCode = [(NSHTTPURLResponse *)response statusCode];
	}else if( connection == iconConnection ){
		//KNDebug(@"%@: resetting incomingData for favicon. %@ %d", self, [response URL], [(NSHTTPURLResponse *)response statusCode]);
		[incomingIcon setLength: 0];
		iconResponseCode = [(NSHTTPURLResponse *)response statusCode];
	}
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	if( connection == dataConnection ){
		//KNDebug(@"%@: got some data for %@", self, currentSource);
		[incomingData appendData: data];
	}else if( connection == iconConnection ){
		//KNDebug(@"%@: got some favicon data", self);
		[incomingIcon appendData: data];
	}else{
		KNDebug(@"%@: got some unspecified data of %d length",self, [data length]);
	}
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	if( connection == dataConnection ){
		if( ! iconFinished ){
			[iconConnection cancel];
			iconFinished = YES;
		}
		
		KNDebug(@"%@: Connection Error for: %@",self, currentSource, [error localizedDescription]);
		dataFinished = YES;
		[library updateFeed: currentSource error: [error localizedDescription]];
		
	}else if( connection == iconConnection ){
		iconFinished = YES;
		if( dataFinished ){
			[library updateFeed: currentSource headers: details  articles: articles];
		}
	}
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection{
	if( connection == dataConnection ){
		//KNDebug(@"%@: connectionDidFinishLoading for %@ '%d' (%d)", self, currentSource, [incomingData length], dataResponseCode);
		dataFinished = YES;
		
		if( dataResponseCode == 200 ){
			//KNDebug(@"%@: About to parse XML response", self);
			if( [self parseXMLData: incomingData] ){
				if( iconFinished ){ [library updateFeed: currentSource headers: details  articles: articles]; }
			}else{
				[self forceEncoding];
				KNDebug(@"%@: Forced encoding", self);
				if( [self parseXMLData: incomingData] ){
					if( iconFinished ){ [library updateFeed: currentSource headers: details articles: articles]; }
				}else{
					if( [self insulateContent] ){
						contentWasModified = YES;
						KNDebug(@"%@: Insulated content", self);
					}
					if( [self parseXMLData: incomingData] ){
						if( iconFinished ){ [library updateFeed: currentSource headers: details articles: articles]; }
					}else{
						if( ! iconFinished ){
							[iconConnection cancel];
							iconFinished = YES;
						}
						KNDebug(@"%@: Parse error in %@: %@", self, currentSource, readerError);
						[library updateFeed: currentSource error: readerError];
					}
				}
			}
		}else{
			if( ! iconFinished ){
				[iconConnection cancel];
				iconFinished = YES;
			}
			[self setReaderError: [NSString stringWithFormat: @"Error loading URL: %d", dataResponseCode]];
			[library updateFeed: currentSource error: readerError];
		}
				
	}else if( connection == iconConnection ){
		//KNDebug(@"%@: connectionDidFinishLoading for icon %@", self, currentSource);
		iconFinished = YES;
		
		if( iconResponseCode == 200 ){
			[self loadFavicon];
		}
		
		if( dataFinished ){
			[library updateFeed: currentSource headers: details  articles: articles];
		}
	}
}

-(BOOL)parseXMLData:(NSData *)sourceXML{
	BOOL					result = NO;
	NSEnumerator *			enumerator;
	NSDictionary *			articleDict;
	
	//KNDebug(@"%@: parseXMLData %@",self, currentSource);
	validSource = NO;		
	parser = [[NSXMLParser alloc] initWithData: sourceXML];
	if( parser ){
		[parser setDelegate: self];
		[parser setShouldResolveExternalEntities: NO];
		
		//KNDebug(@"%@: About to parse %@",self, currentSource);
		
		NS_DURING
			result = [parser parse];
		NS_HANDLER
			result = NO;
		NS_ENDHANDLER
		
		//KNDebug(@"%@: Finished parsing %@", self, currentSource);
		if( result && validSource ){
			//KNDebug(@"RSS: valid source parsed %@",self, currentSource);
			if( feedData ){
				//KNDebug(@"RSS: got feedData %@", feedData);
				[self setDetailsFromDict: feedData];
			}
			if( newArticles ){
				enumerator = [newArticles objectEnumerator];
				while( articleDict = [enumerator nextObject] ){
					//KNDebug(@"%@: parsing article: %@", self, articleDict);
					[self addArticleFromDict: articleDict];
				}
			}
		}else{
			result = NO;;
		}
		[parser release];
	}
	return result;
}

-(void)forceEncoding{
	NSMutableString *				sourceXML = nil;
	
	if( incomingData ){
		sourceXML = [[NSMutableString alloc] initWithData: incomingData encoding: NSASCIIStringEncoding];
		[incomingData release];
		incomingData = [[sourceXML dataUsingEncoding: NSUTF8StringEncoding] retain];
		[sourceXML release];
	}
}

-(BOOL)insulateContent{
}

-(void)setReaderError:(NSString *)anError{
	[readerError autorelease];
	readerError = [anError retain];
}

-(void)addArticleFromDict:(NSDictionary *)dict{
	NSMutableDictionary *			article = [NSMutableDictionary dictionary];
	
	//KNDebug(@"%@: addArticleFromDict: %@",self, dict);
	[article setObject: [self keyOfArticle: dict] forKey: ArticleKey];
	[article setObject: [self titleOfArticle: dict] forKey: ArticleTitle];
	[article setObject: [self authorOfArticle: dict] forKey: ArticleAuthor];
	[article setObject: [self linkOfArticle: dict] forKey: ArticleLink];//KNDebug(@"%@: next", self);
	[article setObject: [self dateOfArticle: dict] forKey: ArticleDate];
	[article setObject: [self sourceOfArticle: dict] forKey: ArticleSource];
	[article setObject: [self categoryOfArticle: dict] forKey: ArticleCategory];
	[article setObject: [self commentsOfArticle: dict] forKey: ArticleComments];
	[article setObject: [self contentOfArticle: dict] forKey: ArticleContent];
	[article setObject: [self sourceURLOfArticle: dict] forKey: ArticleSourceURL];
	[article setObject: [self torrentURLOfArticle: dict] forKey: ArticleTorrentURL];
	
	[articles addObject: article];
}

-(void)setDetailsFromDict:(NSDictionary *)dict{
	//KNDebug(@"FeedReader: setDetailsFromDict %@ (should override)",self, dict);
	[details setObject: FeedTypeUnknown forKey: FeedType];
}


-(void)loadFavicon{
	NSImage *			iconImage;
	NSData *			iconData;
	NSImage *			sizedImage;
	
	//KNDebug(@"%@: loadFavicon"self,);
	iconImage = [[NSImage alloc] initWithData: incomingIcon];
	if( iconImage ){
		//KNDebug(@"%@: fetched image %@",self, [iconImage class], iconImage);
		sizedImage = [[NSImage alloc] initWithSize: NSMakeSize(16,16)];
		[sizedImage lockFocus];
		[iconImage drawInRect:  NSMakeRect(0,0,16,16 )
					fromRect: NSMakeRect(0,0, [iconImage size].width, [iconImage size].height )
					operation: NSCompositeCopy
					fraction: 1.0
		];
		[sizedImage unlockFocus];
		iconData = [sizedImage TIFFRepresentation];
		[details setObject: [[iconData copy] autorelease] forKey: FeedIcon];
		
		[sizedImage release];
		[iconImage release];
		//KNDebug(@"%@: set the data (%@) %@",self, [iconData class], iconData);
	}
}

-(NSString *)keyOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)titleOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)contentOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)authorOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)sourceOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)sourceURLOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)categoryOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSDate *)dateOfArticle:(NSDictionary *)article{
	return [NSDate date];
}
-(NSString *)linkOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)commentsOfArticle:(NSDictionary *)article{
	return [NSString string];
}
-(NSString *)torrentURLOfArticle:(NSDictionary *)article{
	return [NSString string];
}

@end
