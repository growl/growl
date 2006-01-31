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

#define FeedItemTypeArticle @"Article"

#define StatusRead @"Read"
#define StatusUnread @"Unread"
#define StatusUpdated @"Updated"

#define ArticleFeed @"feed"
#define ArticleGuid @"guid"
#define ArticleFeedName @"feedName"
#define ArticleStatus @"status"
#define ArticleTitleHTML @"titleHTML"
#define ArticleTitle @"title"
#define ArticleLink @"link"
#define ArticleSourceURL @"sourceURL"
#define ArticleCommentsURL @"commentsURL"
#define ArticleAuthor @"author"
#define ArticleDate @"date"
#define ArticleCategory @"category"
#define ArticleSummary @"summary"
#define ArticleContent @"content"
#define ArticleIsOnServer @"isOnServer"
#define ArticleIsSuppressed @"isSuppressed"

#define ArticlePreviewCacheVersion [NSNumber numberWithUnsignedInt: 1]

@class KNFeed;
@interface KNArticle : KNItem <NSCoding>{
	NSString *					status;
	
	NSString *					feedName;
	NSString *					guid;
	NSString *					titleHTML;
	NSString *					title;
	NSString *					link;
	NSString *					sourceURL;
	NSString *					commentsURL;
	
	NSString *					author;
	NSDate *					date;	
	NSString *					category;
	NSString *					summary;
	NSString *					content;
	
	BOOL						isOnServer;
	BOOL						isSuppressed;
	BOOL						isCacheValid;
}

-(void)willUpdate;
-(void)didUpdate;


-(NSComparisonResult)compareByDate:(KNArticle *)article;

-(NSString *)previewCachePath;

-(void)_updatedIfOld:(id)oldValue changed:(id)newValue;

-(NSString *)feedName;
-(void)setGuid:(NSString *)aGuid;
-(NSString *)guid;
-(void)setTitleHTML:(NSString *)aTitleHTML;
-(NSString *)titleHTML;
-(void)setTitle:(NSString *)aTitle;
-(NSString *)title;
-(void)setStatus:(NSString *)aStatus;
-(NSString *)status;
-(void)setLink:(NSString *)aLink;
-(NSString *)link;
-(void)setSourceURL:(NSString *)aSourceURL;
-(NSString *)sourceURL;
-(void)setCommentsURL:(NSString *)aCommentURL;
-(NSString *)commentsURL;
-(void)setAuthor:(NSString *)anAuthor;
-(NSString *)author;
-(void)setDate:(NSDate *)aDate;
-(NSDate *)date;
-(void)setCategory:(NSString *)aCategory;
-(NSString *)category;
-(void)setSummary:(NSString *)aSummary;
-(NSString *)summary;
-(void)setContent:(NSString *)aContent;
-(NSString *)content;
-(void)setIsOnServer:(BOOL)onServerFlag;
-(BOOL)isOnServer;
-(void)setIsSuppressed:(BOOL)suppressionFlag;
-(BOOL)isSuppressed;



-(void)generateCache:(id)sender;
-(void)deleteCache;
@end
