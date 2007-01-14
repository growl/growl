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

#import "Library+Active.h"
#import "Library+Items.h"


#define LibraryActiveFeedItems @"ActiveFeeds"
#define LibraryActiveArticles @"ActiveArticles"
#define LibraryActiveArticleIndex @"ActiveArticleIndex"
#define LibraryDeletedArticleKeys @"DeletedArticleKeys"
#define LibrarySortDescriptors @"SortDescriptors"

#define CurrentArticleCache @"CurrentArticleCache"

@implementation Library (Active)

-(void)generateCurrentArticleCache{
	NSMutableArray *				articles = [NSMutableArray array];
	NSEnumerator *					enumerator = [[self activeFeeds] objectEnumerator];
	KNFeed *							feed = nil;
	
	while( (feed = [enumerator nextObject]) ){
		[articles addObjectsFromArray: [feed itemsWithProperty:ArticleIsSuppressed equalTo:[NSNumber numberWithBool:NO]]];
	}
	
	[articles sortUsingDescriptors: [self sortDescriptors]];
	[cache setObject: articles forKey:CurrentArticleCache];
}


-(void)setSortDescriptors:(NSArray *)descriptors{
	[prefs setObject: descriptors forKey: LibrarySortDescriptors];
	[self generateCurrentArticleCache];
}

-(NSArray *)sortDescriptors{
	return [prefs objectForKey: LibrarySortDescriptors];
}

-(BOOL)isArticleDeleted:(NSString *)articleKey{
	KNArticle *				article = [rootItem itemForKey: articleKey];
	
	if( article ){
		return [article isSuppressed];
	}else{
		return YES;
	}
}

-(NSArray *)activeArticles{
	if( ! [cache objectForKey: CurrentArticleCache] ){
		[cache setObject: [NSArray array] forKey:CurrentArticleCache];
	}
	return [cache objectForKey: CurrentArticleCache];
}

-(NSArray *)activeItems{
	return [rootItem currentItems];
}

-(NSArray *)activeFeeds{
	return [rootItem currentItemsOfType: FeedItemTypeFeed];
}

-(void)clearActiveArticles{
	NSEnumerator *			enumerator = [[self activeFeeds] objectEnumerator];
	KNFeed *					feed = nil;
	
	while( (feed = [enumerator nextObject]) ){
		[feed clearCurrentChildren];
	}
	[self generateCurrentArticleCache];
}

-(void)clearActiveItems{
	[rootItem clearAllCurrentChildren];
	[self generateCurrentArticleCache];
}


-(KNArticle *)oldestUnreadActiveArticle{
	KNArticle *				oldest = nil;
	NSEnumerator *			enumerator = [[self activeFeeds] objectEnumerator];
	KNFeed *					feed;
	
	while( (feed = [enumerator nextObject]) ){
		if( ! oldest ){
			oldest = [feed oldestUnread];
		}else{
			if( [oldest compareByDate: [feed oldestUnread]] ){
				oldest = [feed oldestUnread];
			}
		}
	}
	//KNDebug(@"LIB: is %@ in our active article list (%@)?", oldest, [self activeArticles]);
	return oldest;
}

-(KNArticle *)newestActiveArticle{
	KNArticle *				newest = nil;
	NSEnumerator *			enumerator = [[self activeFeeds] objectEnumerator];
	KNFeed *					feed;
	
	while( (feed = [enumerator nextObject]) ){
		if( ! newest ){
			newest = [feed newestArticle];
		}else{
			if( [[feed newestArticle] compareByDate: newest] ){
				newest = [feed newestArticle];
			}
		}
	}
	return newest;
}

-(NSArray *)feedsInFolder:(KNItem *) item{
	if( ! item ){ item = rootItem; }
	return [item itemsOfType:FeedItemTypeFeed];
}

-(NSArray *)articlesInFolder:(KNItem *) item{
	if( ! item ){ item = rootItem; }
	return [item itemsOfType: FeedItemTypeArticle];
}

-(KNArticle *)activeArticleAtIndex:(unsigned)idx{
	NSArray *					articles = [self activeArticles];
	
    if( idx < [articles count] ){
        return [articles objectAtIndex: idx];
    }else{
        return nil;
    }
}

-(unsigned)indexOfActiveArticle:(KNArticle *)article{
	return [[self activeArticles] indexOfObject: article];
}

-(unsigned)activeArticleCount{
    return [[self activeArticles] count];
}

-(unsigned)activeUnreadCount{
    unsigned			unreadCount = 0;
    NSEnumerator *		enumerator = [[self activeFeeds] objectEnumerator];
    KNFeed *				feed;
    
    while((feed = [enumerator nextObject])){
		unreadCount += [feed unreadCount];
    }
    return unreadCount;
}

@end
