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
#import "Feed.h"
#import "Article.h"
#import "FeedDelegate.h"
#import "FeedLibrary.h"
#import "Prefs.h"
#import "NSString+KNTruncate.h"
#import "KNUtility.h"

#define FeedSourceURLArchiveKey @"sourceurl"
#define FeedDescriptionArchiveKey @"description"

#define FeedDefaultIcon @"FeedDefault"

#define UNIQUEKEYLENGTH 20

@implementation Feed

-(id)initWithSource:(NSString *)aSource{
    self = [super init];
    if( self ){
		//KNDebug(@"FEED: initWithSource %@", aSource);
        source = [[NSString stringWithString: aSource] retain];
        title = [[NSString stringWithString:source] retain];
		userTitle = [[NSString stringWithString: @""] retain];
        summary = [[NSString stringWithString:@""] retain];
        link = [[NSString stringWithString:@""] retain];
        type = [[NSString stringWithString:FeedTypeUnknown] retain];
		image = [[NSString stringWithString:@""] retain];
		icon = [[NSImage imageNamed:FeedDefaultIcon] retain];
		articles = [[NSMutableArray alloc] init];
		uniqueKey = [KNUniqueKeyWithLength(UNIQUEKEYLENGTH) retain];
		prefs = [[NSMutableDictionary alloc] init];
		
		error = nil;
	}
    return self;
}

-(void)dealloc{
	//KNDebug(@"FEED: dealloc");
    [source release];
    [title release];
	[userTitle release];
    [summary release];
    [link release];
    [type release];
	[image release];
    [icon release];
    [articles release];
	[uniqueKey release];
	[prefs release];
	
    [super dealloc];
}

-(id)initWithCoder:(NSCoder *)coder{
    self = [super init];
    if( self ){
		// These items haven't changed, so don't need special treatment
		title = [[coder decodeObjectForKey: FeedTitle] retain];
		link = [[coder decodeObjectForKey: FeedLink] retain];
        type = [[coder decodeObjectForKey: FeedType] retain];
		articles = [[coder decodeObjectForKey: FeedArticles] retain];
		
		source = [coder decodeObjectForKey: FeedSource];
		if( !source ){ source = [coder decodeObjectForKey: FeedSourceURLArchiveKey]; }
		if( !source ){ source = [NSString string]; }
		[source retain];
		
		summary = [coder decodeObjectForKey: FeedSummary];
		if( ! summary ){ summary = [coder decodeObjectForKey: FeedDescriptionArchiveKey]; }
		if( ! summary ){ summary = [NSString string]; }
		[summary retain];
		
		image = [[coder decodeObjectForKey: FeedImage] retain];
		if( [image class] == [NSImage class] ){
			icon = (NSImage *) image;
			image = [[NSString string] retain];
		}
		
		if( ! icon ){
			icon = [[coder decodeObjectForKey: FeedIcon] retain];
		}
		
		userTitle = [coder decodeObjectForKey: FeedUserTitle];
		if( ! userTitle ){
			userTitle = [NSString stringWithString: @""];
		}
		[userTitle retain];
		
		uniqueKey = [coder decodeObjectForKey: FeedUniqueKey];
		if( ! uniqueKey ){
			uniqueKey = KNUniqueKeyWithLength(UNIQUEKEYLENGTH);
		}
		[uniqueKey retain];
		
		prefs = [coder decodeObjectForKey: FeedPrefsKey];
		if( ! prefs ){
			prefs = [NSMutableDictionary dictionary];
		}
		[prefs retain];
		
		error = nil;
	}
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject: source forKey: FeedSource];
    [coder encodeObject: title forKey: FeedTitle];
	[coder encodeObject: userTitle forKey: FeedUserTitle];
    [coder encodeObject: summary forKey: FeedSummary];
    [coder encodeObject: link forKey: FeedLink];
    [coder encodeObject: type forKey: FeedType];
	[coder encodeObject: image forKey: FeedImage];
	[coder encodeObject: icon forKey: FeedIcon];
    [coder encodeObject: articles forKey: FeedArticles];
	[coder encodeObject: uniqueKey forKey: FeedUniqueKey];
	[coder encodeObject: prefs forKey: FeedPrefsKey];
}

-(NSString *)description{
	return( [NSString stringWithFormat:@"%@{%@: %@ - %d Articles}", [super description], [self type], [self title], [articles count]] );
}

-(NSString *)cacheLocation{
	//KNDebug(@"FEED: cacheLocation. Our library cache is: %@ - our uniqueKey is %@", [[[NSApp delegate] feedLibrary] cacheLocation], uniqueKey);
	
	NSString *				cachePath = [[[[NSApp delegate] feedLibrary] cacheLocation] stringByAppendingPathComponent: uniqueKey];
	NSFileManager *			fileManager = [NSFileManager defaultManager];
	
	if( ! [fileManager fileExistsAtPath: cachePath] ){
		if( ! [fileManager createDirectoryAtPath: cachePath attributes: [NSDictionary dictionary]] ){
			return nil;
		}
	}
	
	return cachePath;
}

#pragma mark -
#pragma mark Accessors

-(NSString *)source{
    return source;
}

-(NSString *)title{
    return title;
}

-(NSString *)userTitle{
	return userTitle;
}

-(void)setUserTitle:(NSString *)aTitle{
	[userTitle autorelease];
	userTitle = [aTitle retain];
}

-(NSString *)summary{
    return summary;
}

-(NSString *)link{
    return link;
}

-(NSString *)type{
    return type;
}

-(NSString *)image{
	return image;
}

-(NSImage *)icon{
	return icon;
}

-(NSArray *)articles{
	return articles;
}

-(NSString *)error{
	return error;
}

-(void)setError:(NSString *)reason{
	if( error ){ [error autorelease]; error = nil; }
	if( reason ){ error = [reason copy]; }
}

-(id)valueForKeyPath:(NSString *)keyPath{
	id				value = [super valueForKeyPath: keyPath];
	
	if( ! value ){
		if( [keyPath isEqualToString: @"prefs.updateLength"] ){
			value = [NSNumber numberWithDouble: [PREFS updateLength]];
		}else if( [keyPath isEqualToString:@"prefs.updateUnits"] ){
			value = [NSNumber numberWithDouble: [PREFS updateUnits]];
		}else if( [keyPath isEqualToString:@"prefs.expireInterval"] ){
			value = [NSNumber numberWithDouble: [PREFS articleExpireInterval]];
		}else if( [keyPath isEqualToString:@"prefs.wantsUpdate"] ){
			NSTimeInterval			delay = [[self valueForKeyPath:@"prefs.updateLength"] doubleValue] * [[self valueForKeyPath:@"prefs.updateUnits"] doubleValue];
			value = [NSNumber numberWithBool: ((delay + [[self valueForKeyPath:@"prefs.lastUpdate"] timeIntervalSinceNow]) <= 0)];
		}
	}
	return value;
}

-(void)setValue:(id)aValue forKeyPath:(NSString *)keyPath{
	
	if( ![[self valueForKeyPath: keyPath] isEqual: aValue] ){
		[[[NSApp delegate] feedLibrary] makeDirty];
	}
	[super setValue:aValue forKeyPath:keyPath];
}

#pragma mark -
#pragma mark Update Utilities

-(void)expireArticles{
	NSArray *					articleCopy = [NSArray arrayWithArray: articles];
	NSEnumerator *				enumerator = [articleCopy objectEnumerator];
	Article *					article;
	NSDate *					expireDate;
	
	if( [[self valueForKeyPath:@"prefs.expireInterval"] doubleValue] != -1 ){
	//if( [PREFS articleExpireInterval] != -1 ){
		while( article = [enumerator nextObject] ){
			//expireDate = [[article date] addTimeInterval: [PREFS articleExpireInterval]];
			expireDate = [[article date] addTimeInterval: [[self valueForKeyPath:@"prefs.expireInterval"] doubleValue]];
			if( ([expireDate timeIntervalSinceNow] < 0) && (![[article status] isEqualToString: StatusUnread]) ){
				KNDebug(@"FEED: expiring article %@ (%@)", [article title], [article status]);
				[[[NSApp delegate] feedLibrary] removeArticle: article];
			}
		}
	}
}

-(void)articlesWillUpdate{
	NSEnumerator *				enumerator = [articles objectEnumerator];
	Article *					article;
	
	//KNDebug(@"FEED: articlesWillUpdate");
	while( article = [enumerator nextObject] ){
		[article setIsOnServer: NO];
	}
}

-(void)articlesDidUpdate{
	[self setValue:[NSDate date] forKeyPath:@"prefs.lastUpdate"];
}


-(void)addArticleFromDictionary:(NSDictionary *)dictionary{
	//KNDebug(@"FEED: addArticleFromDictionary");
    Article *               newArticle = nil;
    Article *               oldArticle = [self articleForKey: [dictionary objectForKey:ArticleKey]];
	
    if( oldArticle == nil ){
        //KNDebug(@"FEED: Actually adding");
        newArticle = [[Article alloc] initWithFeed: self dictionary: dictionary];
		[newArticle setIsOnServer: YES];
        [articles addObject: newArticle];
        [newArticle release];
        [[[NSApp delegate] feedLibrary] makeDirty];
        
    }else{
        //KNDebug(@"FEED: Updating old: %@", [dictionary objectForKey: ArticleTitle]);
        [oldArticle setTitle: [dictionary objectForKey: ArticleTitle]];
        [oldArticle setContent: [dictionary objectForKey: ArticleContent]];
        [oldArticle setAuthor: [dictionary objectForKey: ArticleAuthor]];
        [oldArticle setSource: [dictionary objectForKey: ArticleSource]];
		[oldArticle setSourceURL: [dictionary objectForKey: ArticleSourceURL]];
        [oldArticle setCategory: [dictionary objectForKey: ArticleCategory]];
        [oldArticle setLink: [dictionary objectForKey: ArticleLink]];
        [oldArticle setComments: [dictionary objectForKey: ArticleComments]];
		[oldArticle setTorrent: [dictionary objectForKey: ArticleTorrentURL]];
		[oldArticle setIsOnServer: YES];
    }
	//KNDebug(@"FEED: added article");
}

-(void)updateFeedFromDictionary:(NSDictionary *)dictionary{
    //KNDebug(@"FEED: updateFeedFromDictionary");
    if( ![[dictionary objectForKey: FeedType] isEqualToString: type] ){
        [type autorelease];
		type = [[dictionary objectForKey: FeedType] copy];
    }
    
    if( ![[dictionary objectForKey: FeedTitle] isEqualToString: title] ){
        [title autorelease];
		title = [[dictionary objectForKey: FeedTitle] copy];
    }
    
    if( ![[dictionary objectForKey: FeedSummary] isEqualToString: summary] ){
        [summary autorelease];
		summary = [[dictionary objectForKey: FeedSummary] copy];
    }
    if( ![[dictionary objectForKey: FeedLink] isEqualToString: link] ){
        [link autorelease];
        link = [[dictionary objectForKey:FeedLink] copy];
    }
	//KNDebug(@"FEED: did the link, doing image");
	if( [dictionary objectForKey: FeedIcon] ){
		//KNDebug(@"FEED: got an image for feed %@", dictionary);
		NSData *				incomingData = [dictionary objectForKey: FeedIcon];
		//KNDebug(@"FEED: data from bg thread is (%@) %@", [incomingData class], incomingData);
		NSImage *				incomingImage = [[NSImage alloc] initWithData: incomingData];
		
		if( icon ){ [icon release]; }
		//KNDebug(@"FEED: released old image");
		icon = incomingImage;
	}else{
		if( icon ){ [icon release]; }
		icon = [[NSImage imageNamed: FeedDefaultIcon] retain];
		
	}
	//KNDebug(@"FEED: updating makeDirty");
	[[[NSApp delegate] feedLibrary] makeDirty];
	//KNDebug(@"done");
}

#pragma mark -
#pragma mark Article Access

-(long)articleCount{
    return [articles count];
}

-(int)unreadArticleCount{
    int                 unreadCount = 0;
    NSEnumerator *      enumerator = nil;
    Article *           article = nil;
    
	//KNDebug(@"FEED: unreadArticleCount");
    enumerator = [articles objectEnumerator];
    while( article = [enumerator nextObject] ){
        if( [[article status] isEqualToString: StatusUnread] ){
            unreadCount++;
        }
    }
    return unreadCount;
}

-(Article *)articleAtIndex:(long)anIndex{
    return [articles objectAtIndex: anIndex];
}

-(Article *)articleForKey:(NSString *)key{
    NSEnumerator *          enumerator = [articles objectEnumerator];
    Article *               article = nil;
    
    while( article = [enumerator nextObject] ){
        if( [[article key] isEqualToString: key] ){
            return article;
        }
    }
    return nil;
}

-(int)indexOfArticle:(Article *)anArticle{
	//KNDebug(@"FEED indexOfArticle %@", [anArticle title]);
	return( [articles indexOfObject: anArticle] );
}

-(void)removeArticle:(Article *)anArticle{
	//KNDebug(@"FEED: removeArticle %@", [anArticle title]);
	[self removeArticleAtIndex: [self indexOfArticle: anArticle]];
}

-(void)removeArticleAtIndex:(int)anIndex{
	//KNDebug(@"FEED: removeArticleAtIndex: %d", anIndex);
	if( (anIndex > -1) && (anIndex < [articles count]) ){
		//KNDebug(@"FEED: actually removing article %@", articles);
		[[self articleAtIndex: anIndex] deleteCache];
		//KNDebug(@"FEED: cleared article cache");
		[articles removeObjectAtIndex: anIndex];
		[[[NSApp delegate] feedLibrary] makeDirty];
	}
	//KNDebug(@"FEED: removed article!");
}

-(Article *)oldestUnread{
	Article *				oldest = nil;
	NSMutableArray *		articleTemp = [NSMutableArray arrayWithArray: articles];
	NSEnumerator *			enumerator = nil;
	Article *				article = nil;
	
	[articleTemp sortUsingSelector: @selector(compareByDate:)];
	enumerator = [articleTemp objectEnumerator];
	
	while( article = [enumerator nextObject] ){
		if( [[article status] isEqualToString: StatusUnread] ){
			oldest = article;
			break;
		}
	}
	return oldest;
}

-(Article *)newestArticle{
	Article *				newest = nil;
	NSMutableArray *		articleTemp = [NSMutableArray arrayWithArray: articles];
	
	if( [articles count] > 0 ){
		articleTemp = [NSMutableArray arrayWithArray: articles];
		[articleTemp sortUsingSelector: @selector(compareByDate:)];
		newest = [articleTemp lastObject];
	}
	return newest;
}


@end
