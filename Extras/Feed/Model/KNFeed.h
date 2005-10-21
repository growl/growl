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


#import <Cocoa/Cocoa.h>
#import "KNItem.h"

#define FeedItemTypeFeed @"Feed"

#define FeedSourceTypeRSS @"RSS"
#define FeedSourceTypeAtom @"Atom"
#define FeedSourceTypeUnknown @"Unknown"

#define FeedDidCreateArticleNotification @"FeedDidCreateArticleNotification"

#define FeedSourceURL @"sourceURL"
#define FeedSourceType @"sourceType"
#define FeedFaviconURL @"faviconURL"
#define FeedFaviconImage @"faviconImage"
#define FeedSummary @"summary"
#define FeedLink @"link"
#define FeedLastError @"lastError"
#define FeedImageURL @"imageURL"

@class KNArticle;
@interface KNFeed : KNItem <NSCoding>{
	NSString *				sourceURL;
	NSString *				sourceType;
	NSString *				faviconURL;
	NSImage *				faviconImage;
	
	NSString *				summary;
	NSString *				link;
	NSString *				lastError;
	NSString *				imageURL;
}

-(void)setSourceURL:(NSString *)aSourceURL;
-(NSString *)sourceURL;
-(void)setSourceType:(NSString *)aSourceType;
-(NSString *)sourceType;
-(void)setFaviconURL:(NSString *)aFaviconURL;
-(NSString *)faviconURL;
-(void)setFaviconImage:(NSImage *)aFaviconImage;
-(NSImage *)faviconImage;
-(void)setSummary:(NSString *)aSummary;
-(NSString *)summary;
-(void)setLink:(NSString *)aLink;
-(NSString *)link;
-(void)setLastError:(NSString *)anError;
-(NSString *)lastError;
-(void)setImageURL:(NSString *)anImageURL;
-(NSString *)imageURL;

-(void)willUpdateArticles;
-(void)refreshArticleWithDictionary:(NSDictionary *)articleDict;
-(void)expireArticles;
-(void)didUpdateArticles;
-(KNArticle *)newestArticle;
-(KNArticle *)oldestUnread;

@end
