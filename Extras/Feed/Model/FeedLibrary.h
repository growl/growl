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

#define FeedUpdateFinishedNotification @"FeedUpdateFinished"
#define FeedUpdateStartedNotification @"FeedUpdateStarted"
#define FeedUpdateWillUpdateFeedNotification @"FeedUpdateWillUpdate"
#define FeedUpdateDidUpdateFeedNotification @"FeedUpdateDidUpdate"

@class Feed,Article;
@interface FeedLibrary : NSObject{
    NSMutableDictionary *           feedRoot;
    NSString *                      libLocation;
	NSString *						userLibraryPath;
    BOOL                            isDirty;
	
	NSMutableDictionary *			activeReaders;
	
	NSMutableArray *				feedsToUpdate;
	BOOL							isUpdating;
	int								unreadFeedCount;
}

-(NSString *)cacheLocation;

-(BOOL)save;
-(void)shutdown;
-(void)makeDirty;
-(void)refreshFeed:(Feed *)aFeed;
-(BOOL)refreshAll;
-(void)refreshPending;
-(BOOL)startUpdate;

// Debugging support
-(void)resetArticleKillList;

// Active Viewing Support
-(void)setSortDescriptors:(NSArray *)descriptors;
-(NSArray *)sortDescriptors;

-(BOOL)isArticleDeleted:(NSString *)articleKey;
-(void)removeArticle:(Article *)anArticle;

-(void)sortActiveArticles;
-(void)refreshActiveArticles;
-(NSArray *)activeFeeds;
-(NSArray *)feedsInFolder:(id) item;
-(NSArray *)activeArticles;
-(NSArray *)articlesInFolder:(id) item;
-(NSArray *)activeFeedItems;
-(void)setActiveFeedItems:(NSArray *)activeFeedItems;

-(Article *)oldestUnreadActiveArticle;
-(Article *)newestActiveArticle;

-(void)setActiveArticle:(Article *)article;
-(void)setActiveArticleIndex:(int)activeArticleIndex;
-(int)activeArticleCount;
-(int)activeUnreadCount;
-(int)activeArticleIndex;
-(Article *)activeArticle;
-(Article *)activeArticleAtIndex:(int)index;
-(int)indexOfActiveArticle:(Article *)article;

// Update Support
-(void)cancelUpdate;
-(void)updateStarted;
-(void)willUpdateFeed:(NSString *)source;
-(void)updateFeed:(NSString *)source headers:(NSDictionary *)headers articles:(NSArray *)articles;
-(void)updateFeed:(NSString *)source error:(NSString *)reason;
-(void)runNextUpdate;
-(void)updateFinished;
-(NSString *)typeForFeed:(NSString *)feedURL;

// Direct Access Support
-(NSArray *)allFeeds;
-(Feed *)feedForSource:(NSString *)source;
-(int)unreadCount;
-(int)unreadCountForItem:(id)item;



// Item Based Support
-(Article *)activeArticleForItem:(id)item;
-(void)setActiveArticle:(Article *)article forItem:(id)item;

-(NSString *)typeForItem:(id)item;
-(BOOL)isFolderItem:(id)item;
-(BOOL)isFeedItem:(id)item;
-(BOOL)isArticleItem:(id)item;

-(BOOL)isItem:(id)item1 descendentOfItem:(id)item2;

-(id)newFolderNamed:(NSString *)name inItem:(id)item atIndex:(int)index;
-(id)newFeed:(Feed *)feed inItem:(id)item atIndex:(int)index;
-(id)newArticle:(Article *)article inItem:(id)item atIndex:(int)index;

-(void)removeItem:(id)item;
-(void)removeItem:(id)item fromItem:(id)parentItem;
-(void)moveItem:(id)item toParent:(id)parent index:(int)index;

-(NSString *)nameForItem:(id)item;
-(NSString *)keyForItem:(id)item;
-(id)itemForKey:(NSString *)key;
-(void)setName:(NSString *)name forItem:(id)item;
-(Feed *)feedForItem:(id)item;
-(Article *)articleForItem:(id)item;

-(id)child:(int)index ofItem:(id)item;
-(BOOL)hasChildren:(id)item;
-(int)childCountOfItem:(id)item;


@end
