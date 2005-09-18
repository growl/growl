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

#import <Cocoa/Cocoa.h>

#define FeedLoadFailed @"FeedLoadFailed"

@class FeedLibrary;
@interface FeedReader : NSObject {
	FeedLibrary *					library;
	NSString *						currentSource;
	NSMutableDictionary *			details;
	NSMutableArray *				articles;
	NSMutableData *					incomingData;
	NSMutableData *					incomingIcon;
	NSString *						readerError;
	
	int								dataResponseCode;
	int								iconResponseCode;
	NSURLConnection *				dataConnection;
	BOOL							dataFinished;
	NSURLConnection *				iconConnection;
	BOOL							iconFinished;
	
	NSXMLParser *					parser;
	NSMutableDictionary *			feedData;
	NSMutableArray *				newArticles;
	NSMutableDictionary *			currentArticle;
	NSMutableString *				currentBuffer;
	BOOL							validSource;
	BOOL							contentWasModified;
}

-(id)initWithLibrary:(FeedLibrary *)aLibrary source:(NSString *)aSource;

-(void)cancel;
//-(BOOL)readFromSource:(NSString *)sourceURL;
-(BOOL)parseXMLData:(NSData *)sourceXML;
-(void)forceEncoding;
-(BOOL)insulateContent;
-(void)setReaderError:(NSString *)anError;

-(void)setDetailsFromDict:(NSDictionary *)dict;
-(void)addArticleFromDict:(NSDictionary *)dict;

-(NSString *)keyOfArticle:(NSDictionary *)article;
-(NSString *)titleOfArticle:(NSDictionary *)article;
-(NSString *)contentOfArticle:(NSDictionary *)article;
-(NSString *)authorOfArticle:(NSDictionary *)article;
-(NSString *)sourceOfArticle:(NSDictionary *)article;
-(NSString *)sourceURLOfArticle:(NSDictionary *)article;
-(NSString *)categoryOfArticle:(NSDictionary *)article;
-(NSDate *)dateOfArticle:(NSDictionary *)article;
-(NSString *)linkOfArticle:(NSDictionary *)article;
-(NSString *)commentsOfArticle:(NSDictionary *)article;
-(NSString *)torrentURLOfArticle:(NSDictionary *)article;

-(void)loadFavicon;

@end
