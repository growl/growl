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
#import <Foundation/Foundation.h>

#define StatusUnread @"Unread"
#define StatusRead @"Read"
#define StatusUpdated @"Updated"

// Key/Value keys
#define ArticleFeed @"feed"
#define ArticleFeedName @"feedName"
#define ArticleStatus @"status"
#define ArticleKey @"key"
#define ArticleTitle @"title"
#define ArticleUserTitle @"userTitle"
#define ArticleAuthor @"author"
#define ArticleLink @"link"
#define ArticleDate @"date"
#define ArticleSource @"source"
#define ArticleSourceURL @"sourceURL"
#define ArticleCategory @"category"
#define ArticleComments @"comments"
#define ArticleContent @"content"
#define ArticleOnServer @"onServer"
#define ArticlePreviewCachePath @"previewCachePath"
#define ArticleUniqueKey @"uniqueKey"
#define ArticleTorrentURL @"torrentURL"

@class Feed;
@interface Article : NSObject <NSCoding> {
    Feed *                  feed;
	NSString *              status;
	NSString *              key;
    NSString *              title;
	NSString *				userTitle;
	NSString *              author;
	NSString *				link;
	NSDate *                date;
	NSString *              source;
	NSString *				sourceURL;
    NSString *              category;
    NSString *				comments;
    NSString *              content;
	NSString *				torrent;
	
	NSString *				uniqueKey;
	NSString *				previewCachePath;
    
	BOOL					isOnServer;
}

-(Feed *)feed;
-(NSString *)key;
-(NSString *)status;
-(void)setStatus:(NSString *)aStatus;

-(NSString *)title;
-(void)setTitle:(NSString *)aTitle;
-(NSString *)userTitle;
-(void)setUserTitle:(NSString *)aTitle;
-(NSString *)author;
-(void)setAuthor:(NSString *)anAuthor;
-(NSString *)link;
-(void)setLink:(NSString *)aLink;
-(NSDate *)date;
-(void)setDate:(NSDate *)aDate;
-(NSString *)source;
-(void)setSource:(NSString *)aSource;
-(NSString *)sourceURL;
-(void)setSourceURL:(NSString *)aSourceURL;
-(NSString *)category;
-(void)setCategory:(NSString *)aCategory;
-(NSString *)comments;
-(void)setComments:(NSString *)aComments;
-(NSString *)content;
-(void)setContent:(NSString *)aContent;
-(NSString *)torrent;
-(void)setTorrent:(NSString *)aTorrentURL;
-(BOOL)isOnServer;
-(void)setIsOnServer:(BOOL)serverFlag;

@end
