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
#import "FeedLibrary.h"

#import "Feed.h"
#import "Article.h"
#import "RSSReader.h"
#import "AtomReader.h"
#import "Prefs.h"
#import "NSNumber+KNRandom.h"
#import "OPMLReader.h"

#define CURRENT_VERSION 1

#define LibraryFeedRoot @"FeedRoot"
#define LibrarySourceIndex @"SourceIndex"
#define LibraryVersion @"Version"
#define LibrarySortKeys @"SortKeys"
#define LibrarySortKey @"SortKey"
#define LibraryActiveFeedItems @"ActiveFeeds"
#define LibraryActiveArticles @"ActiveArticles"
#define LibraryActiveArticleIndex @"ActiveArticleIndex"
#define LibraryDeletedArticleKeys @"DeletedArticleKeys"
#define LibraryItemKeyIndex @"ItemKeyIndex"
#define LibrarySortDescriptors @"SortDescriptors"
#define LibrarySelectedArticles @"SelectedArticles"

#define TreeItemName @"TreeItemName"
#define TreeItemType @"TreeItemType"
#define TreeItemTypeFolder @"Folder"
#define TreeItemTypeFeed @"Feed"
#define TreeItemTypeArticle @"Article"
#define TreeChildArray @"TreeChildArray"
#define TreeFeedObject @"TreeFeedObject"
#define TreeItemParent @"TreeItemParent"
#define TreeItemKey @"TreeItemKey"
#define TreeArticleObject @"TreeArticleObject"
#define TreeItemActiveArticle @"TreeItemActiveArticle"

#define FEED_LIB_DIR @"Feed"
#define FEED_LIB_FILE @"Library.feed"
#define FEED_LIB_FILE_BAK @"Library.feed.bak"
@implementation FeedLibrary

-(id)init{
    self = [super init];
    if( self ){
        //KNDebug(@"LIB: Init");
        feedRoot = nil;
        isDirty = NO;
		isUpdating = NO;
        feedsToUpdate = [[NSMutableArray alloc] init];
		activeReaders = [[NSMutableDictionary alloc] init];
		[NSNumber initRandom];
		
        NSArray *           paths;
        NSFileManager *     fileManager = [NSFileManager defaultManager];
        NSData *            fileData = nil;
        
        paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
        if( [paths count] == 0 ){
            KNDebug(@"LIB: Unable to locate users Library directory!");
            return nil;
        }
        
        if( ! [fileManager fileExistsAtPath: [paths objectAtIndex:0]] ){
            KNDebug(@"LIB: User Library directory doesn't exist!");
            return nil;
        }
		
		userLibraryPath = [[paths objectAtIndex:0] retain];
        
        libLocation = [userLibraryPath stringByAppendingPathComponent: FEED_LIB_DIR];
        if( ! [fileManager fileExistsAtPath: libLocation] ){
            KNDebug(@"LIB: No Feed directory found at %@. Creating", libLocation);
            if( ! [fileManager createDirectoryAtPath: libLocation attributes: [NSDictionary dictionary]] ){
                KNDebug(@"LIB: Unable to create Feed directory");
                return nil;
            }
        }
        
        libLocation = [libLocation stringByAppendingPathComponent: FEED_LIB_FILE];
        if( ! [fileManager fileExistsAtPath: libLocation] ){
            feedRoot = [[NSMutableDictionary alloc] init];
			
            [feedRoot setObject: [NSMutableArray array] forKey:LibraryFeedRoot];
            [feedRoot setObject: [NSMutableDictionary dictionary] forKey:LibrarySourceIndex];
            [feedRoot setObject: [NSNumber numberWithInt: CURRENT_VERSION] forKey:LibraryVersion];
            [feedRoot setObject: [NSMutableArray array] forKey: LibraryActiveFeedItems];
            [feedRoot setObject: [NSMutableArray array] forKey: LibraryActiveArticles];
            [feedRoot setObject: [NSNumber numberWithInt: NSNotFound] forKey: LibraryActiveArticleIndex];
			[feedRoot setObject: [NSMutableArray array] forKey: LibraryDeletedArticleKeys];
			[feedRoot setObject: [NSMutableDictionary dictionary] forKey: LibraryItemKeyIndex];
			[feedRoot setObject: [NSMutableArray array] forKey: LibrarySelectedArticles];
			
			// Load our default sources
			OPMLReader *				opml = [[OPMLReader alloc] init];
			NSEnumerator *				enumerator;
			NSString *					source;
			Feed *						feed;
			
			if( [opml parse: [[NSFileManager defaultManager] contentsAtPath: [[NSBundle mainBundle] pathForResource:@"DefaultSources" ofType:@"opml"]]] ){
				enumerator = [[opml outlines] objectEnumerator];
				while((source = [enumerator nextObject])){
					feed = [[Feed alloc] initWithSource: source];
					[self newFeed: feed inItem: nil atIndex: [self childCountOfItem: nil]];
					[feed release];
				}
			}else{
				KNDebug(@"LIB: Unable to load default sources");
			}
			[opml release];
			
			
            fileData = [NSKeyedArchiver archivedDataWithRootObject: feedRoot];
            if( ! [fileManager createFileAtPath: libLocation contents: fileData attributes: [NSDictionary dictionary]] ){
                KNDebug(@"LIB: Unable to create Feed library file");
                return nil;
            }
			KNDebug(@"LIB: Created default Feed library file");
        }
        
        
        KNDebug(@"LIB: Loading library from %@", libLocation);
        fileData = [fileManager contentsAtPath: libLocation];
        if( ! fileData ){
            KNDebug(@"LIB: Unable to load file data");
            return nil;
        }
        
        feedRoot = [[NSKeyedUnarchiver unarchiveObjectWithData: fileData] retain];
        [libLocation retain];
        
        //KNDebug(@"LIB: Unarchived feedRoot");
        if( ![feedRoot objectForKey:LibraryVersion] ){
            [feedRoot setObject: [NSNumber numberWithInt:0] forKey:LibraryVersion];
        }
                
        if( ![feedRoot objectForKey:LibrarySortKeys] ){
            [feedRoot setObject: [NSArray arrayWithObjects:
                            ArticleDate, ArticleKey,nil
                    ] forKey: LibrarySortKeys
            ];
        }
        
        if( ![feedRoot objectForKey:LibrarySortKey] ){
            [feedRoot setObject: [NSString stringWithString: ArticleDate] forKey: LibrarySortKey];
        }
        
        if( ! [feedRoot objectForKey:LibraryActiveFeedItems] ){
            [feedRoot setObject: [NSMutableArray array] forKey:LibraryActiveFeedItems];
        }
        
        if( ! [feedRoot objectForKey:LibraryActiveArticles] ){
            [feedRoot setObject: [NSMutableArray array] forKey:LibraryActiveArticles];
        }
        
        if( ! [feedRoot objectForKey:LibraryActiveArticleIndex] ){
            [feedRoot setObject: [NSNumber numberWithInt: NSNotFound] forKey: LibraryActiveArticleIndex];
        }
		
		if( ! [feedRoot objectForKey:LibraryDeletedArticleKeys] ){
			[feedRoot setObject: [NSMutableArray array] forKey: LibraryDeletedArticleKeys];
		}
				
		if( ! [feedRoot objectForKey:LibraryItemKeyIndex] ){
			[feedRoot setObject: [NSMutableDictionary dictionary] forKey: LibraryItemKeyIndex];
		}
		
		if( ! [feedRoot objectForKey:LibrarySortDescriptors] ){
			[feedRoot setObject: [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey:ArticleDate ascending:YES] autorelease]] forKey: LibrarySortDescriptors];
		}
		
		if( ! [feedRoot objectForKey:LibrarySelectedArticles] ){
			[feedRoot setObject: [NSMutableArray array] forKey: LibrarySelectedArticles];
		}
        		
		[NSTimer scheduledTimerWithTimeInterval:15 target: self selector:@selector(timedSave:) userInfo:nil repeats: YES];
		[NSTimer scheduledTimerWithTimeInterval:600 target: self selector: @selector(purgeKillList:) userInfo:nil repeats: YES];
    }
    return self;
}

-(void)dealloc{
	[activeReaders release];
	[feedsToUpdate release];
	[feedRoot release];
	[libLocation release];
	[userLibraryPath release];
	[super dealloc];
}

-(void)makeDirty{
	//KNDebug(@"LIB: makeDirty");
    isDirty = YES;
}

-(void)timedSave:(NSTimer *)timer{
#pragma unused(timer)
	[self save];
}

-(BOOL)save{
    NSFileManager *     fileManager = [NSFileManager defaultManager];
    NSData *            fileData = nil;
    NSString *          libBackupLocation = [libLocation stringByDeletingLastPathComponent];
    NSNumber *          oldVersion;
    
	//KNDebug(@"LIB: save");
    if( isDirty && !isUpdating ){
		//KNDebug(@"LIB: dirty. Will write");
		oldVersion = [feedRoot objectForKey:LibraryVersion];
		[feedRoot setObject:[NSNumber numberWithInt:CURRENT_VERSION] forKey:LibraryVersion];
		fileData = [NSKeyedArchiver archivedDataWithRootObject: feedRoot];
		libBackupLocation = [libBackupLocation stringByAppendingPathComponent: FEED_LIB_FILE_BAK];
		if( [fileManager movePath: libLocation toPath: libBackupLocation handler: nil] ){
			//KNDebug(@"LIB: backed up lib");
			if( [fileManager createFileAtPath: libLocation contents: fileData attributes: [NSDictionary dictionary]] ){
				[fileManager removeFileAtPath: libBackupLocation handler: nil];
				KNDebug(@"LIB: Saved library file");
				isDirty = NO;
				return YES;
			}else{
				KNDebug(@"LIB: Unable to save library");
				[fileManager movePath: libBackupLocation toPath: libLocation handler: nil];
				[feedRoot setObject:oldVersion forKey:LibraryVersion];
			}
		}
    }
    return NO;
}

-(int)version{
    return [[feedRoot objectForKey:LibraryVersion] intValue];
}

-(NSString *)cacheLocation{
	NSString *				currentPath = [userLibraryPath stringByAppendingPathComponent:@"Caches/Feed"];
	NSFileManager *			fileManager = [NSFileManager defaultManager];
	 
	if( ! [fileManager fileExistsAtPath: currentPath] ){
		KNDebug(@"LIB: No cache directory found at %@. Creating", currentPath);
		if( ! [fileManager createDirectoryAtPath: currentPath attributes: [NSDictionary dictionary]] ){
			KNDebug(@"LIB: Unable to create cache directory");
			return nil;
		}
	}
	
	currentPath = [currentPath stringByAppendingPathComponent:@"Library"];
	if( ! [fileManager fileExistsAtPath: currentPath] ){
		if( ! [fileManager createDirectoryAtPath: currentPath attributes: [NSDictionary dictionary]] ){
			return nil;
		}
	}
		
	return currentPath;
}

-(void)refreshFeed:(Feed *)aFeed{
	KNDebug(@"LIB: refreshFeed");
	if( [feedsToUpdate indexOfObject: aFeed] == NSNotFound ){
		[feedsToUpdate addObject: aFeed];
	}
}

-(BOOL)refreshAll{
	KNDebug(@"LIB: refreshAll");
	NSEnumerator *			enumerator = [[[feedRoot objectForKey:LibrarySourceIndex] allKeys] objectEnumerator];
	NSString *				feedSource = nil;
	
	[feedsToUpdate removeAllObjects];
	while((feedSource = [enumerator nextObject])){
		[feedsToUpdate addObject: [self feedForSource: feedSource]];
	}
	return [self startUpdate];
}

-(void)refreshPending{
	NSEnumerator *			enumerator = [[[feedRoot objectForKey:LibrarySourceIndex] allKeys] objectEnumerator];
	NSString *				feedSource = nil;
	
	[feedsToUpdate removeAllObjects];
	while((feedSource = [enumerator nextObject])){
		if( [[[self feedForSource: feedSource] valueForKeyPath:@"prefs.wantsUpdate"] boolValue] ){
			[feedsToUpdate addObject: [self feedForSource: feedSource]];
		}
	}
	[self startUpdate];
}

-(BOOL)startUpdate{
	if( KNNetworkReachablePolitely( @"keeto.net" ) ){
		if( ([feedsToUpdate count] > 0) && ! isUpdating){
			[self updateStarted];
			[self runNextUpdate];
			return YES;
		}
	}else{
		KNDebug(@"LIB: Network is offline - skipping update");
	}
	return NO;
}

-(void)shutdown{
    //KNDebug(@"LIB: shutdown called");
}

-(void)resetArticleKillList{
	NSMutableArray *			newKillList = [NSMutableArray array];
	
	KNDebug(@"LIB: resetArticleKillList - there were %d articles", [[feedRoot objectForKey:LibraryDeletedArticleKeys] count]);
	[feedRoot setObject:newKillList forKey: LibraryDeletedArticleKeys];
	[self makeDirty];
	//[self save];
}

-(void)purgeKillList:(NSTimer *)timer{
#pragma unused(timer)
	NSEnumerator *				feedEnumerator = [[self feedsInFolder: nil] objectEnumerator];
	Feed *						feed;
	NSEnumerator *				articleEnumerator;
	Article *					article;
	
	//KNDebug(@"LIB: purgeKillList");
	while((feed = [feedEnumerator nextObject])){
		//KNDebug(@"LIB: purging feed %@", feed);
		articleEnumerator = [[feed articles] objectEnumerator];
		while((article = [articleEnumerator nextObject])){
			if( ![article isOnServer] ){
				//KNDebug(@"LIB: purging article from kill list %@", [article title]);
				[[feedRoot objectForKey:LibraryDeletedArticleKeys] removeObject: [article key]];
			}
		}
	}
}

#pragma mark -
#pragma mark Active View Support

-(void)setSortDescriptors:(NSArray *)descriptors{
	[feedRoot setObject: descriptors forKey: LibrarySortDescriptors];
}

-(NSArray *)sortDescriptors{
	return [feedRoot objectForKey: LibrarySortDescriptors];
}


-(void)removeArticle:(Article *)anArticle{
	Feed *					articleFeed = [anArticle feed];
	
	//KNDebug(@"LIB: removing article %@ from feed %@", [anArticle title], [articleFeed title]);
	if( [anArticle isOnServer] ){
		//KNDebug(@"LIB: article is on server - adding to kill list");
		[[feedRoot objectForKey: LibraryDeletedArticleKeys] addObject: [anArticle key]];
	}
	
	if( anArticle == [self activeArticle] ){
		//KNDebug(@"LIB: deleting active article. setting current index to %d", NSNotFound);
		[self setActiveArticleIndex: NSNotFound];
	}
	
	KNDebug(@"LIB: clearing saved selection from item %@", [self itemForKey: [[anArticle feed] source]]);
	[self setActiveArticle:nil forItem: [self itemForKey: [[anArticle feed] source]]];
	KNDebug(@"LIB: telling feed to drop article");
	[articleFeed removeArticle: anArticle];
	//KNDebug(@"LIB: got our article removed");
	//[self refreshActiveArticles];
}

-(BOOL)isArticleDeleted:(NSString *)articleKey{
	return( [[feedRoot objectForKey: LibraryDeletedArticleKeys] indexOfObject: articleKey] != NSNotFound );
}

-(void)sortActiveArticles{
    Article *               oldActiveArticle = nil;
    
    //KNDebug(@"LIB: sortActiveArticles");
	oldActiveArticle = [self activeArticle];
    
    //[[feedRoot objectForKey:LibraryActiveArticles] sortUsingSelector: @selector(compare:)];
	[[feedRoot objectForKey: LibraryActiveArticles] sortUsingDescriptors: [self sortDescriptors]];

	[self setActiveArticleIndex: [[feedRoot objectForKey:LibraryActiveArticles] indexOfObject: oldActiveArticle]];

	//KNDebug(@"LIB: after sort article index: %d", [[feedRoot objectForKey:LibraryActiveArticles] indexOfObject: oldActiveArticle]);
    [self makeDirty];
}

-(void)refreshActiveArticles{
	NSEnumerator *			enumerator;
	Feed *					feed;
	NSMutableArray *		newArticleList = [NSMutableArray array];
	int						i;
	Article *				oldActiveArticle = nil;
	Article *				article;
	
	oldActiveArticle = [self activeArticle];
	//KNDebug(@"LIB: saving active article %@", oldActiveArticle);
	enumerator = [[self activeFeeds] objectEnumerator];
	while((feed = [enumerator nextObject])){
		for(i=0;i<[feed articleCount];i++){
			if( [newArticleList indexOfObject: [feed articleAtIndex:i]] == NSNotFound ){
				[newArticleList addObject: [feed articleAtIndex:i]];
			}
		}
	}
	
	enumerator = [[self activeArticles] objectEnumerator];
	while((article = [enumerator nextObject])){
		if( [newArticleList indexOfObject: article] == NSNotFound ){
			[newArticleList addObject: article];
		}
	}
	
	[feedRoot setObject: newArticleList forKey: LibraryActiveArticles];
	[self setActiveArticleIndex: [[feedRoot objectForKey:LibraryActiveArticles] indexOfObject: oldActiveArticle]];
	//KNDebug(@"LIB: after refresh article index: %d", [[feedRoot objectForKey:LibraryActiveArticles] indexOfObject: oldActiveArticle]);
	[self sortActiveArticles];
}

-(void)setActiveFeedItems:(NSArray *)activeFeedItems{
    //KNDebug(@"LIB: setActiveFeeds: %@", activeFeedItems);
    if( ! [[feedRoot objectForKey:LibraryActiveFeedItems] isEqualToArray: activeFeedItems] ){
        [feedRoot setObject: [NSArray arrayWithArray:activeFeedItems] forKey: LibraryActiveFeedItems];
		[self refreshActiveArticles];
    }
}

-(NSArray *)activeFeedItems{
    return [feedRoot objectForKey: LibraryActiveFeedItems];
}

-(Article *)oldestUnreadActiveArticle{
	Article *				oldest = nil;
	NSEnumerator *			enumerator = [[self activeFeedItems] objectEnumerator];
	NSDictionary *			feedItem;
	Feed *					feed;
	
	while((feedItem = [enumerator nextObject])){
		if( [self isFeedItem: feedItem] ){
			feed = [self feedForItem: feedItem];
			if( ! oldest ){
				oldest = [feed oldestUnread];
			}else{
				if( [oldest compareByDate: [feed oldestUnread]] ){
					oldest = [feed oldestUnread];
				}
			}
		}
	}
	//KNDebug(@"LIB: is %@ in our active article list (%@)?", oldest, [self activeArticles]);
	return oldest;
}

-(Article *)newestActiveArticle{
	Article *				newest = nil;
	NSEnumerator *			enumerator = [[self activeFeedItems] objectEnumerator];
	NSDictionary *			feedItem;
	Feed *					feed;
	
	while((feedItem = [enumerator nextObject])){
		if( [self isFeedItem: feedItem] ){
			feed = [self feedForItem: feedItem];
			if( ! newest ){
				newest = [feed newestArticle];
			}else{
				if( [[feed newestArticle] compareByDate: newest] ){
					newest = [feed newestArticle];
				}
			}
		}
	}
	return newest;
}

-(NSArray *)activeFeeds{
	NSMutableArray *		feeds = [NSMutableArray array];
	NSArray *				subFeeds;
	NSEnumerator *			enumerator = [[self activeFeedItems] objectEnumerator];
	NSDictionary *			feedItem;
	NSEnumerator *			subEnumerator;
	Feed *					subFeed;
	
	while((feedItem = [enumerator nextObject])){
		if( [self isFeedItem: feedItem] ){
			if( [feeds indexOfObject: [self feedForItem: feedItem]] == NSNotFound ){
				[feeds addObject: [self feedForItem: feedItem]];
			}
		}else if( [self isFolderItem: feedItem] ){
			subFeeds = [self feedsInFolder: feedItem];
			subEnumerator = [subFeeds objectEnumerator];
			while((subFeed = [subEnumerator nextObject])){
				if( [feeds indexOfObject: subFeed] == NSNotFound ){
					[feeds addObject: subFeed];
				}
			}
			//[feeds addObjectsFromArray: [self feedsInFolder: feedItem]];
		}
	}
	return feeds;
}

-(NSArray *)feedsInFolder:(id) item{
	NSMutableArray *		feeds = [NSMutableArray array];
	NSEnumerator *			enumerator;
	NSDictionary *			childItem;
	NSArray *				sourceList;
	//NSArray *				sourceList;
	
	if( [self isFolderItem: item] ){
		if( item ){ sourceList = [item objectForKey: TreeChildArray]; }
		else{ sourceList = [feedRoot objectForKey: LibraryFeedRoot]; }
		
		enumerator = [sourceList objectEnumerator];
		while((childItem = [enumerator nextObject])){
			if( [self isFeedItem: childItem] ){
				if( [feeds indexOfObject: [self feedForItem: childItem]] == NSNotFound ){
					[feeds addObject: [self feedForItem: childItem]];
				}
			}else if( [self isArticleItem: childItem] ){
				if( [feeds indexOfObject: [[self articleForItem: childItem] feed]] == NSNotFound ){
					//[feeds addObject: [[self articleForItem: childItem] feed]];
				}
			}else if( [self isFolderItem: childItem] ){
				[feeds addObjectsFromArray: [self feedsInFolder: childItem]];
			}
		}
	}
	return feeds;
}

-(NSArray *)activeArticles{
	NSMutableArray *		articles = [NSMutableArray array];
	NSArray *				subArticles;
	NSEnumerator *			enumerator = [[self activeFeedItems] objectEnumerator];
	NSDictionary *			item;
	NSEnumerator *			subEnumerator;
	Article *				subArticle;
	
	while((item = [enumerator nextObject])){
		if( [self isArticleItem: item] ){
			if( [articles indexOfObject: [self articleForItem: item]] == NSNotFound ){
				[articles addObject: [self articleForItem: item]];
			}
		}else if( [self isFolderItem: item] ){
			subArticles = [self articlesInFolder: item];
			subEnumerator = [subArticles objectEnumerator];
			while((subArticle = [subEnumerator nextObject])){
				if( [articles indexOfObject: subArticle] == NSNotFound ){
					[articles addObject: subArticle];
				}
			}
		}
	}
	return articles;
}

-(NSArray *)articlesInFolder:(id) item{
	NSMutableArray *		articles = [NSMutableArray array];
	NSEnumerator *			enumerator;
	NSDictionary *			childItem;
	NSArray *				sourceList;
	
	if( [self isFolderItem: item] ){
		if( item ){ sourceList = [item objectForKey: TreeChildArray]; }
		else{ sourceList = [feedRoot objectForKey: LibraryFeedRoot]; }
		
		enumerator = [sourceList objectEnumerator];
		while((childItem = [enumerator nextObject])){
			if( [self isArticleItem: childItem] ){
				[articles addObject: [self articleForItem: childItem]];
			}else if( [self isFolderItem: childItem] ){
				[articles addObjectsFromArray: [self articlesInFolder: childItem]];
			}
		}
	}
	return articles;
}

-(Article *)activeArticleAtIndex:(int)idx{
    if( (idx > -1) && (idx < [self activeArticleCount]) ){
        return [[feedRoot objectForKey: LibraryActiveArticles] objectAtIndex: idx];
    }else{
        return nil;
    }
}

-(int)indexOfActiveArticle:(Article *)article{
	//KNDebug(@"LIB: Checking %@ against %@", article, [self activeArticles]);
	return [[self activeArticles] indexOfObject: article];
}

-(int)activeArticleCount{
    return [[feedRoot objectForKey: LibraryActiveArticles] count];
}

-(int)activeUnreadCount{
    int                 unreadCount = 0;
    NSEnumerator *      enumerator = [[self activeFeeds] objectEnumerator];
    Feed *				feed;
    
    while((feed = [enumerator nextObject])){
		unreadCount += [feed unreadArticleCount];
    }
    return unreadCount;
}

-(void)setActiveArticle:(Article *)article{
	[self setActiveArticleIndex: [[feedRoot objectForKey:LibraryActiveArticles] indexOfObject: article]];
}

-(void)setActiveArticleIndex:(int)activeArticleIndex{
	NSDictionary *			item = nil;
	
	//KNDebug(@"LIB: setActiveArticleIndex to %d" ,activeArticleIndex);
    [feedRoot setObject: [NSNumber numberWithInt: activeArticleIndex] forKey: LibraryActiveArticleIndex];
	
	item = [self itemForKey: [[[self activeArticle] feed] source]];
	if( item ){
		//KNDebug(@"LIB: setting active article selection in item %@", item);
		[self setActiveArticle: [self activeArticle] forItem: item];
	}
	
    [self makeDirty];
}

-(int)activeArticleIndex{
	//KNDebug(@"LIB: activeArticleIndex. %@", [feedRoot objectForKey:LibraryActiveArticleIndex]);
    return [[feedRoot objectForKey: LibraryActiveArticleIndex] intValue];
}

-(Article *)activeArticle{
    return [self activeArticleAtIndex: [self activeArticleIndex]];
}


#pragma mark -
#pragma mark Update Thread Support

-(NSString *)typeForFeed:(NSString *)feedURL{
    return [[self feedForSource:feedURL] type];
}

-(void)cancelUpdate{
	FeedReader *			reader = nil;
	
	if( isUpdating ){
		[feedsToUpdate removeAllObjects];
	}
	
	while( [activeReaders count] > 0 ){
		NSString *			source = [[activeReaders allKeys] objectAtIndex:0];
		reader = [[activeReaders objectForKey: source] retain];
		[reader cancel];
		[activeReaders removeObjectForKey: source];
		[reader release];
	}
	[self updateFinished];
}

-(void)updateStarted{
    KNDebug(@"LIB: Update Started. %d items to update", [feedsToUpdate count]);
    isUpdating = YES;
	unreadFeedCount = [self unreadCount];
    [[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateStartedNotification object: nil];
}

-(void)willUpdateFeed:(NSString *)source{
	[[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateWillUpdateFeedNotification object: source];
}

-(void)updateFeed:(NSString *)source headers:(NSDictionary *)headers articles:(NSArray *)articles{
    Feed *                  feed = [self feedForSource: source];
    NSEnumerator *          enumerator = [articles objectEnumerator];
    NSDictionary *          article;
    
    [feed updateFeedFromDictionary: headers];
	[feed setError: nil];
	[feed articlesWillUpdate];
    while((article = [enumerator nextObject])){
		if( ! [self isArticleDeleted: [article objectForKey:ArticleKey]] ){
			[feed addArticleFromDictionary: article];
		}
    }
	[feed articlesDidUpdate];
	//KNDebug(@"LIB: feed %@ updated", [feed title]);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateDidUpdateFeedNotification object: source];
	
	FeedReader *			oldReader = [[activeReaders objectForKey: source] retain];
	[activeReaders removeObjectForKey: source];
	[oldReader autorelease];
	
	[self runNextUpdate];
}

-(void)updateFeed:(NSString *)source error:(NSString *)reason{
	Feed *					feed = [self feedForSource: source];
	
	if( [[feed type] isEqualToString: FeedTypeUnknown] && [[activeReaders objectForKey: source] isKindOfClass:[RSSReader class]] ){
		AtomReader *			newReader = [[AtomReader alloc] initWithLibrary: self source: source];
		
		KNDebug(@"LIB: retrying unknown feed as Atom");
		if( newReader ){
			[activeReaders setObject: newReader forKey: [feed source]];
			[newReader release];
		}
		
	}else{
		[feed setError: reason];
		KNDebug(@"feed %@ error %@", [feed title], reason);
		[[NSNotificationCenter defaultCenter] postNotificationName: FeedUpdateDidUpdateFeedNotification object: source];
		
		FeedReader *		oldReader = [[activeReaders objectForKey: source] retain];

		[activeReaders removeObjectForKey: source];
		[oldReader autorelease];
		[self runNextUpdate];
	}
}

-(void)runNextUpdate{
	Feed *				feed = nil;
	FeedReader *		newReader = nil;
	
	if( [feedsToUpdate count] > 0U ){
		while( ((int)[activeReaders count] < [PREFS maxUpdateThreads]) && ([feedsToUpdate count] > 0U) ){
			
			newReader = nil;
			
			feed = [feedsToUpdate objectAtIndex:0];
			[feedsToUpdate removeObject: feed];
			//KNDebug(@"LIB: Starting updater for %@", [feed source]);
			
			if( [[feed type] isEqualToString: FeedTypeRSS] ||
				[[feed type] isEqualToString: FeedTypeUnknown]
			){
				newReader = [[RSSReader alloc] initWithLibrary: self source: [feed source]];
			}else if( [[feed type] isEqualToString: FeedTypeAtom] ){
				newReader = [[AtomReader alloc] initWithLibrary: self source: [feed source]];
			}
			
			if( newReader ){
				[activeReaders setObject: newReader forKey: [feed source]];
				[newReader release];
			}
		}
	}else{
		if( [activeReaders count] == 0 ){
			[self updateFinished];
		}
	}
}

-(void)updateFinished{
	KNDebug(@"LIB: Update Finished");
    //NSArray *				oldKillFile = [NSArray arrayWithArray: [feedRoot objectForKey: LibraryDeletedArticleKeys]];
	NSEnumerator *			enumerator;// = [oldKillFile objectEnumerator];
	//NSString *				key;
	Feed *					feed;
	
	/*
	while( key = [enumerator nextObject] ){
		if( [visibleArticles indexOfObject: key] == NSNotFound ){
			[[feedRoot objectForKey: LibraryDeletedArticleKeys] removeObject: key];
			[self makeDirty];
		}
	}
	*/
	
	//if( [PREFS articleExpireInterval] != -1 ){
		enumerator = [[self allFeeds] objectEnumerator];
		while((feed = [enumerator nextObject])){
			//KNDebug(@"About to purge articles in %@", [self feedForSource: key]);
			[feed expireArticles];
		}
	//}
	
	//[feedsToUpdate removeAllObjects];
	isUpdating = NO;
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateFinishedNotification object: nil];
	if( unreadFeedCount < [self unreadCount] ){
		unreadFeedCount = [self unreadCount];
		if(! [[PREFS notificationSoundName] isEqualToString: @""] ){
			NSSound *			notificationSound = [NSSound soundNamed: [PREFS notificationSoundName]];
			if( notificationSound ){
				[notificationSound play];
			}
		}
	}
}

#pragma mark -
#pragma mark Direct Access
-(Feed *)feedForSource:(NSString *)aSource{
    return [[[feedRoot objectForKey:LibrarySourceIndex] objectForKey:aSource] objectForKey:TreeFeedObject];
}

-(int)unreadCount{
    //NSEnumerator *          enumerator = [[feedRoot objectForKey:LibrarySourceIndex] keyEnumerator];
	NSEnumerator *			enumerator = [[feedRoot objectForKey:LibraryFeedRoot] objectEnumerator];
    //NSString *              itemKey;
    NSDictionary *          item;
    int                     totalUnread = 0;
    
    //while( itemKey = [enumerator nextObject] ){
	while((item = [enumerator nextObject])){
        //item = [[feedRoot objectForKey:LibrarySourceIndex] objectForKey: itemKey];
        //totalUnread += [[item objectForKey:TreeFeedObject] unreadArticleCount];
		totalUnread += [self unreadCountForItem: item];
    }
    
    return totalUnread;
}

-(int)unreadCountForItem:(id)item{
	NSEnumerator *				enumerator;
	int							unreadCount = 0;
	id							child;
	
	//KNDebug(@"LIB: unreadCountForItem");
	if( [self isFeedItem: item] ){
		//KNDebug(@"LIB: item is a feed");
		unreadCount = [[self feedForItem: item] unreadArticleCount];
	}else if( [self isFolderItem: item] ){
		//KNDebug(@"LIB: item is a folder");
		enumerator = [[item objectForKey: TreeChildArray] objectEnumerator];
		while((child = [enumerator nextObject])){
			//KNDebug(@"LIB: checking unread of child item %@", child);
			if( [self isFeedItem: child] ){
				unreadCount += [[self feedForItem: child] unreadArticleCount];
			}else if( [self isFolderItem: child] ){
				unreadCount += [self unreadCountForItem: child];
			}else if( [self isArticleItem: child] ){
				if( [[[self articleForItem: child] status] isEqualToString: StatusUnread] ){
					unreadCount++;
				}
			}
		}
		//KNDebug(@"LIB: got unread count of %d", unreadCount);
	}else if( [self isArticleItem: item] ){
		//KNDebug(@"LIB: Getting unread count for article %@", [self articleForItem:item]);
		if( [[[self articleForItem: item] status] isEqualToString: StatusUnread] ){
			unreadCount++;
		}
	}
	return unreadCount;
}

-(NSArray *)allFeeds{
	NSMutableArray *		feeds = [NSMutableArray array];
	NSEnumerator *			enumerator = [[[feedRoot objectForKey:LibrarySourceIndex] allValues] objectEnumerator];
	id						feedItem;
	
	while((feedItem = [enumerator nextObject])){
		[feeds addObject: [self feedForItem: feedItem]];
	}
	return( feeds );
}

#pragma mark -
#pragma mark Item Based

-(Article *)activeArticleForItem:(id)item{
	Article *				article = nil;
	int						i;
	
	article = [item objectForKey: TreeItemActiveArticle];
	if( ! article ){
		if( [self isFolderItem: item] ){
			for(i=0;i<[self childCountOfItem: item];i++){
				article = [self activeArticleForItem: [self child: i ofItem: item]];
				if( article ){
					break;
				}
			}
		}
	}
	return article;
}

-(void)setActiveArticle:(Article *)article forItem:(id)item{
	if( article ){
		[item setObject: article forKey: TreeItemActiveArticle];
	}else{
		[item removeObjectForKey: TreeItemActiveArticle];
	}
}

-(NSString *)typeForItem:(id)item{
	if( !item ){ return [NSString stringWithString:@""]; }
	return( [item objectForKey: TreeItemType] );
}

-(BOOL)isFolderItem:(id)item{
	if( ! item ){ return YES; }
    return( [[item objectForKey: TreeItemType] isEqualToString: TreeItemTypeFolder] );
}

-(BOOL)isFeedItem:(id)item{
    //KNDebug(@"LIB: isFeedItem %@", item);
	if( ! item ){ return NO; }
    return( [[item objectForKey: TreeItemType] isEqualToString: TreeItemTypeFeed] );
}

-(BOOL)isArticleItem:(id)item{
	if( ! item ){ return NO; }
	return( [[item objectForKey: TreeItemType] isEqualToString: TreeItemTypeArticle] );
}

-(BOOL)isItem:(id)item1 descendentOfItem:(id)item2{
	BOOL					isDescendent = NO;
	NSEnumerator *			enumerator;
	id						childItem;
	
	if( item1 == item2 ){ return YES; }
	//KNDebug(@"LIB: isItem %@ descendentOfItem %@", item1, item2);
	if( [self isFolderItem: item2] ){
		enumerator = [[item2 objectForKey: TreeChildArray] objectEnumerator];
		while((childItem = [enumerator nextObject])){
			if( item1 == childItem ){ return YES; }
			
			if( [self isFolderItem: childItem] ){
				isDescendent = [self isItem: item1 descendentOfItem: childItem];
				if( isDescendent ){ break; }
			}
		}
	}
	//KNDebug(@"LIB: isDescendent %@", isDescendent ? @"YES" : @"NO");
	return isDescendent;
}

-(id)newFolderNamed:(NSString *)name inItem:(id)item atIndex:(int)idx{
    NSMutableDictionary *           itemRecord = [NSMutableDictionary dictionary];
    NSString *						key;
	
    [itemRecord setObject:TreeItemTypeFolder forKey:TreeItemType];
    [itemRecord setObject:[NSMutableArray array] forKey:TreeChildArray];
    [itemRecord setObject: name forKey: TreeItemName];
	
	key = [NSString stringWithFormat:@"FOLDER: %f", [NSDate timeIntervalSinceReferenceDate]];
	[itemRecord setObject: key forKey: TreeItemKey];
    
    if( item != nil ){
        if( [[item objectForKey: TreeItemType] isEqualToString: TreeItemTypeFolder] ){
            [[item objectForKey: TreeChildArray] insertObject: itemRecord atIndex: idx];
        }
    }else{
        [[feedRoot objectForKey:LibraryFeedRoot] insertObject: itemRecord atIndex: idx];
    }
	
	[[feedRoot objectForKey: LibraryItemKeyIndex] setObject: itemRecord forKey: key];
    return itemRecord;
}

-(id)newFeed:(Feed *)feed inItem:(id)item atIndex:(int)idx{
    NSMutableDictionary *           itemRecord = [NSMutableDictionary dictionary];
    NSMutableArray *				itemStore;
	
	//KNDebug(@"LIB: newFeed: %@", feed);
    if( [[feedRoot objectForKey:LibrarySourceIndex] objectForKey: [feed source]] ){
        KNDebug(@"LIB: Attempt to add duplicate feed source: %@", [feed source]);
        return nil;
    }
    
    [itemRecord setObject:TreeItemTypeFeed forKey:TreeItemType];
    [itemRecord setObject:feed forKey:TreeFeedObject];
	[itemRecord setObject: [feed source] forKey: TreeItemKey];
    
	if( item ){
		itemStore = [item objectForKey: TreeChildArray];
	}else{
		itemStore = [feedRoot objectForKey: LibraryFeedRoot];
	}
	
	if( [self isFolderItem: item] ){
		if( idx < 0 || idx >= (int)[itemStore count] ){
			[itemStore addObject: itemRecord];
		}else{
			[itemStore insertObject: itemRecord atIndex: idx];
		}
	}
    
    [[feedRoot objectForKey:LibrarySourceIndex] setObject: itemRecord forKey: [feed source]];
    [[feedRoot objectForKey: LibraryItemKeyIndex] setObject: itemRecord forKey: [feed source]];
    return itemRecord;
}

-(id)newArticle:(Article *)article inItem:(id)item atIndex:(int)idx{
	NSMutableDictionary *			itemRecord = [NSMutableDictionary dictionary];
	
	[itemRecord setObject: TreeItemTypeArticle forKey: TreeItemType];
	[itemRecord setObject: article forKey: TreeArticleObject];
	[itemRecord setObject: [article key] forKey: TreeItemKey];
	[itemRecord setObject: article forKey: TreeItemActiveArticle];
	
	if( item ){
		if( [self isFolderItem: item] ){
			if( idx < 0 || idx >= (int)[[item objectForKey: TreeChildArray] count] ){
				[[item objectForKey: TreeChildArray] addObject: itemRecord];
			}else{
				[[item objectForKey: TreeChildArray] insertObject: itemRecord atIndex: idx];
			}
		}
	}else{
		if( idx < 0 || idx >= (int)[[feedRoot objectForKey: LibraryFeedRoot] count] ){
			[[feedRoot objectForKey: LibraryFeedRoot] addObject: itemRecord];
		}else{
			[[feedRoot objectForKey: LibraryFeedRoot] insertObject: itemRecord atIndex: idx];
		}
	}
	return itemRecord;
}

-(void)removeItem:(id)item{    
    if( item != nil ){
        // Remove Feeds from the source index dictionary
		[self removeItem:item fromItem: NULL];
		return;
    }
}

-(void)removeItem:(id)item fromItem:(id)parentItem{
	NSMutableArray *			itemStore;
	NSEnumerator *				enumerator;
	NSDictionary *				currentItem;
	Article *					article;
	
	//KNDebug(@"LIB: removeItem %@ fromItem %@", item, parentItem);
	if( ! [self isFolderItem: parentItem] ) return;
	
	if( ! parentItem ){
		itemStore = [feedRoot objectForKey: LibraryFeedRoot];
	}else{
		itemStore = [parentItem objectForKey: TreeChildArray];
	}
	//KNDebug(@"LIB: itemStore is %@", itemStore);
	
	if( [itemStore indexOfObject: item] != NSNotFound ){
		//KNDebug(@"removing from parent %@", parentItem);
		
		if( [self isFeedItem: item] ){
			[[feedRoot objectForKey: LibrarySourceIndex] removeObjectForKey: [[self feedForItem: item] source]];
			// remove any articles from kill list
			//KNDebug(@"LIB: about to clean kill file for feed %@", [self feedForItem: item]);
			enumerator = [[[self feedForItem: item] articles] objectEnumerator];
			while((article = [enumerator nextObject])){
				//KNDebug(@"LIB: removing %@ from kill file", [article key]);
				[[feedRoot objectForKey: LibraryDeletedArticleKeys] removeObject: [article key]];
			}
		}
		[[feedRoot objectForKey: LibraryItemKeyIndex] removeObjectForKey: [self keyForItem: item]];
		
		[itemStore removeObject: item];
		[self makeDirty];
	}else{
		//KNDebug(@"scanning children for folders");
		enumerator = [itemStore objectEnumerator];
		while((currentItem = [enumerator nextObject])){
			//KNDebug(@"checking %@", currentItem);
			if( [self isFolderItem: currentItem] ){
				[self removeItem: item fromItem: currentItem];
			}
		}
	}
}

-(void)moveItem:(id)item toParent:(id)parent index:(int)idx{
	//KNDebug(@"LIB: moveItem %@ toParent %@ index %d", item, parent, idx);
	NSMutableArray *				itemSource;
	
	if( [self isFolderItem: parent] ){
		//KNDebug(@"LIB: going to move (old parent is folder: %@)", oldParent);
		if( (idx < 0) || (idx > [self childCountOfItem: parent]) ){
			//KNDebug(@"LIB: moveItem - reset index from %d to %d", idx, [self childCountOfItem: parent]);
			idx = [self childCountOfItem: parent];
		}
		
		[item retain];
		[self removeItem: item];
		if( [self isFeedItem: item] ){
			[[feedRoot objectForKey: LibrarySourceIndex] setObject: item forKey: [[self feedForItem: item] source]];
		}
		[[feedRoot objectForKey: LibraryItemKeyIndex] setObject: item forKey: [self keyForItem: item]];
		
		if( parent ){
			itemSource = [parent objectForKey: TreeChildArray];
		}else{
			itemSource = [feedRoot objectForKey: LibraryFeedRoot];
		}
		
		//KNDebug(@"LIB: index is %d and source (%@) count is %d", idx, itemSource, [itemSource count]);
		if( idx >= (int)[itemSource count] ){
			[itemSource addObject: item];
		}else{
			[itemSource insertObject: item atIndex: idx];
		}
		
		[item release];
		//KNDebug(@"LIB: moved it!");
	}
}

-(NSString *)nameForItem:(id)item{
    NSString *              value = [NSString stringWithString:@""];
    
    if( [self isFolderItem: item] ){
        value = [item objectForKey: TreeItemName];
    }else if( [self isFeedItem: item] ){
		if( [[[self feedForItem: item] userTitle] isEqualToString: @""] ){
			value = [[self feedForItem: item] title];
		}else{
			value = [[self feedForItem: item] userTitle];
		}
    }else if( [self isArticleItem: item] ){
		if( [[[self articleForItem: item] userTitle] isEqualToString: @""] ){
			value = [[self articleForItem: item] title];
		}else{
			value = [[self articleForItem: item] userTitle];
		}
	}
	if( value == nil ){
		KNDebug(@"LIB: ####WARNING#### nameForItem (%@) is nil",item);
	}
    return value;
}

-(NSString *)keyForItem:(id)item{
	return [item objectForKey: TreeItemKey];
}

-(id)itemForKey:(NSString *)aKey{
	return [[feedRoot objectForKey: LibraryItemKeyIndex] objectForKey: aKey];
}

-(void)setName:(NSString *)name forItem:(id)item{
	if( name == nil ){
		KNDebug(@"LIB: ####WARNING#### setting nil name for item!");
	}
    if( [self isFolderItem: item] ){
        [item setObject: name forKey: TreeItemName];
    }else if( [self isFeedItem: item] ){
		[[self feedForItem: item] setUserTitle: name];
	}else if( [self isArticleItem: item] ){
		[[self articleForItem: item] setUserTitle: name];
	}
}

-(Feed *)feedForItem:(id)item{
    Feed *                  feed = nil;
    
    if( [[item objectForKey: TreeItemType] isEqualToString: TreeItemTypeFeed] ){
        feed = [item objectForKey: TreeFeedObject];
    }
    return feed;
}

-(Article *)articleForItem:(id)item{
	Article *				article = nil;
	
	if( [self isArticleItem: item] ){
		article = [item objectForKey: TreeArticleObject];
	}
	return article;
}

-(id)child:(int)idx ofItem:(id)item{
    id              childObject = nil;
    
    if( item != nil ){
        if( [[item objectForKey:TreeItemType] isEqualToString:TreeItemTypeFolder] ){
            childObject = [[item objectForKey:TreeChildArray] objectAtIndex: idx];
        }
    }else{
        childObject = [[feedRoot objectForKey:LibraryFeedRoot] objectAtIndex: idx];
    }
    return childObject;
}

-(BOOL)hasChildren:(id)item{
    BOOL            result = NO;
    
    if( item != nil ){
        result = [[item objectForKey:TreeItemType] isEqualToString: TreeItemTypeFolder];
    }else{
        result = ([[feedRoot objectForKey:LibraryFeedRoot] count] > 0);
    }
    return result;
}

-(int)childCountOfItem:(id)item{
    int             count = 0;
    
    //KNDebug(@"LIB: ChildCount %@", item);
    if( item != nil ){
        if( [[item objectForKey:TreeItemType] isEqualToString: TreeItemTypeFolder] ){
            count = [[item objectForKey:TreeChildArray] count];
            //KNDebug(@"LIB: ChildCount found %d in folder", count);
        }
    }else{
        count = [[feedRoot objectForKey:LibraryFeedRoot] count];
       // KNDebug(@"LIB: ChildCount found %d in root", count);
    }
    
    return count;
}


@end
