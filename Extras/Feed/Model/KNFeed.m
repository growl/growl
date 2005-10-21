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

#import "KNFeed.h"

#import "Library.h"
#import "Prefs.h"
#import "KNArticle.h"

#define FeedFaviconImageDefault [NSImage imageNamed:@"FeedDefault"]
@implementation KNFeed

-(id)init{
	if( (self = [super init]) ){
		sourceURL = [[NSString string] retain];
		sourceType = [[NSString stringWithString: FeedSourceTypeUnknown] retain];
		faviconURL = [[NSString string] retain];
		summary = [[NSString string] retain];
		link = [[NSString string] retain];
		lastError = [[NSString string] retain];
		imageURL = [[NSString string] retain];
		
		faviconImage = [FeedFaviconImageDefault retain];
	}
	return self;
}

-(id)initWithCoder:(NSCoder *)aCoder{
	if( (self = [super initWithCoder: aCoder]) ){
		sourceURL = [[aCoder decodeObjectForKey: FeedSourceURL] retain];
		sourceType = [[aCoder decodeObjectForKey: FeedSourceType] retain];
		faviconURL = [[aCoder decodeObjectForKey: FeedFaviconURL] retain];
		summary = [[aCoder decodeObjectForKey: FeedSummary] retain];
		link = [[aCoder decodeObjectForKey: FeedLink] retain];
		lastError = [[aCoder decodeObjectForKey: FeedLastError] retain];
		imageURL = [[aCoder decodeObjectForKey: FeedImageURL] retain];
		
		faviconImage = [aCoder decodeObjectForKey: FeedFaviconImage];
		if(! faviconImage ){
			faviconImage = FeedFaviconImageDefault;
		}
		[faviconImage retain];
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)aCoder{
	[aCoder encodeObject: sourceURL forKey: FeedSourceURL];
	[aCoder encodeObject: sourceType forKey: FeedSourceType];
	[aCoder encodeObject: faviconURL forKey: FeedFaviconURL];
	[aCoder encodeObject: summary forKey: FeedSummary];
	[aCoder encodeObject: link forKey: FeedLink];
	[aCoder encodeObject: lastError forKey: FeedLastError];
	[aCoder encodeObject: imageURL forKey: FeedImageURL];
	
	if(! [faviconImage isEqual: FeedFaviconImageDefault] ){
		[aCoder encodeObject: faviconImage forKey: FeedFaviconImage];
	}
	
	[super encodeWithCoder: aCoder];
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] postNotificationName: FeedItemReleaseNotification object: self];
	
	[sourceURL release];
	[sourceType release];
	[faviconURL release];
	[faviconImage release];
	[summary release];
	[link release];
	[lastError release];
	[imageURL release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Properties

-(NSString *)type{
	return FeedItemTypeFeed;
}

-(void)setSourceURL:(NSString *)aSourceURL{
	if( !aSourceURL ){ ItemThrow(@"Attempt to set nil URL for Source"); }
	[sourceURL autorelease];
	sourceURL = [aSourceURL retain];
}

-(NSString *)sourceURL{
	return sourceURL;
}

-(void)setSourceType:(NSString *)aSourceType{
	if( [aSourceType isEqualToString: FeedSourceTypeRSS] ||
		[aSourceType isEqualToString: FeedSourceTypeAtom] ||
		[aSourceType isEqualToString: FeedSourceTypeUnknown]
	){
		[sourceType autorelease];
		sourceType = [[NSString stringWithString:aSourceType] retain];
	}else{
		ItemThrow(@"Attempt to set unknown source type for Feed");
	}
}

-(NSString *)sourceType{
	return sourceType;
}

-(void)setFaviconURL:(NSString *)aFaviconURL{
	if( !aFaviconURL ){ ItemThrow(@"Attempt to set nil favicon URL for Feed"); }
	[faviconURL autorelease];
	faviconURL = [aFaviconURL retain];
}

-(NSString *)faviconURL{
	return faviconURL;
}

-(void)setFaviconImage:(NSImage *)aFaviconImage{
	if( !aFaviconImage ){ ItemThrow(@"Attempt to set nil favicon Image for Feed"); }
	[faviconImage autorelease];
	faviconImage = [aFaviconImage retain];
}

-(NSImage *)faviconImage{
	return faviconImage;
}

-(void)setSummary:(NSString *)aSummary{
	if( aSummary == nil ){ ItemThrow(@"Attempt to set nil summary for Feed"); }
	[summary autorelease];
	summary = [aSummary retain];
}

-(NSString *)summary{
	return summary;
}

-(void)setLink:(NSString *)aLink{
	if( !aLink ){ ItemThrow(@"Attempt to set nil link for Feed"); }
	[link autorelease];
	link = [aLink retain];
}

-(NSString *)link{
	return link;
}

-(void)setLastError:(NSString *)anError{
	if( !anError ){ ItemThrow(@"Attempt to set nil error for Feed"); }
	[lastError autorelease];
	lastError = [anError retain];
}

-(NSString *)lastError{
	return lastError;
}

-(void)setImageURL:(NSString *)anImageURL{
	if( ! anImageURL ){ ItemThrow(@"Attempt to set nil image URL for Feed"); }
	[imageURL autorelease];
	imageURL = [anImageURL retain];
}

-(NSString *)imageURL{
	return imageURL;
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
			value = [NSNumber numberWithBool: ((delay + [[self valueForKeyPath:@"prefs.lastUpdateAttempt"] timeIntervalSinceNow]) <= 0)];
		}
	}
	return value;
}

-(void)setValue:(id)aValue forKeyPath:(NSString *)keyPath{
	
	if( ![[self valueForKeyPath: keyPath] isEqual: aValue] ){
		[LIB makeDirty];
	}
	[super setValue:aValue forKeyPath:keyPath];
}

-(void)setValue:(id)aValue forKey:(NSString *)aKey{
	
	if( ![[self valueForKey: aKey] isEqual: aValue] ){
		[LIB makeDirty];
	}
	[super setValue:aValue forKey:aKey];
}

#pragma mark -
#pragma mark Child Restrictions

-(void)addChild:(KNItem *)aChild{
	if( ! [[aChild type] isEqualToString: FeedItemTypeArticle] ){
		ItemThrow(@"Attempt to add non-article child to Feed");
	}
	[super addChild: aChild];
}

-(void)insertChild:(KNItem *)aChild atIndex:(unsigned)anIndex{
	if( ![[aChild type] isEqualToString: FeedItemTypeArticle] ){
		ItemThrow(@"Attempt to add non-article child to Feed");
	}
	[super insertChild: aChild atIndex: anIndex];
}

-(void)removeChildAtIndex:(unsigned)anIndex{
	KNArticle *					article = [self childAtIndex: anIndex];
	
	if( [article isOnServer] ){
		[article setIsSuppressed: YES];
	}else{
		[super removeChildAtIndex: anIndex];
	}
}

#pragma mark -
#pragma mark Update Support

-(void)willUpdateArticles{
	NSEnumerator *					articleEnumerator = [[self itemsOfType:FeedItemTypeArticle] objectEnumerator];
	KNArticle *						article = nil;
	
	while( (article = [articleEnumerator nextObject]) ){
		[article setIsOnServer:NO];
	}
	
	[self setValue:[NSDate date] forKeyPath:@"prefs.lastUpdateAttempt"];
}

-(void)didUpdateArticles{
	[self setValue:[NSDate date] forKeyPath:@"prefs.lastUpdate"];
	
	KNDebug(@"update finished for %@", self);
	// Purge any suppressed articles that are no longer on server
	NSEnumerator *				enumerator = [[self itemsWithProperty:ArticleIsSuppressed equalTo:[NSNumber numberWithBool: YES]] objectEnumerator];
	KNArticle *					article = nil;
	
	while( (article = [enumerator nextObject]) ){
		if( ! [article isOnServer] ){
			[self removeChild: article];
		}
	}
	[LIB makeDirty];
}

-(void)refreshArticleWithDictionary:(NSDictionary *)articleDict{
	NSEnumerator *					propertyEnumerator = [articleDict keyEnumerator];
	NSString *						property = nil;
	NSEnumerator *					articleEnumerator = [[self itemsOfType:FeedItemTypeArticle] objectEnumerator];
	KNArticle *						article = nil;
	BOOL							didCreate = NO;
	
	while( (article = [articleEnumerator nextObject]) ){
		if( [[article guid] isEqualToString: [articleDict objectForKey:ArticleGuid]] ){
			break;
		}
	}
	
	if( ! article ){
		article = [[KNArticle alloc] init];
		[self addChild: article];
		[article release];
		didCreate = YES;
	}
	
	while( (property = [propertyEnumerator nextObject]) ){
		[article setValue: [articleDict objectForKey: property] forKey: property];
	}
	
	[article setIsOnServer: YES];
	
	if( didCreate ){
		[[NSNotificationCenter defaultCenter] postNotificationName:FeedDidCreateArticleNotification object: self];
	}
}

-(void)expireArticles{
	NSTimeInterval				expireInterval = [[self valueForKeyPath:@"prefs.expireInterval"] doubleValue];
	
	if( expireInterval != -1 ){
		NSEnumerator *			enumerator = [[self itemsOfType: FeedItemTypeArticle] objectEnumerator];
		KNArticle *				article = nil;
		NSDate *				expireDate = nil;
		
		while( (article = [enumerator nextObject]) ){
			expireDate = [[article date] addTimeInterval: expireInterval];
			if( ([expireDate timeIntervalSinceNow] < 0) && (![[article status] isEqualToString: StatusUnread]) ){
				if( [article isOnServer] ){
					[article setIsSuppressed: YES];
				}else{
					[self removeChild: article];
				}
			}
		}
	}
}

-(KNArticle *)newestArticle{
	NSMutableArray *			articles = [self itemsOfType:FeedItemTypeArticle];
	KNArticle *					article = nil;
	
	if( [articles count] > 0 ){
		[articles sortUsingSelector: @selector(compareByDate:)];
		article = [articles objectAtIndex:0];
	}
	return article;
}

-(KNArticle *)oldestUnread{
	NSMutableArray *			articles = [self itemsOfType:FeedItemTypeArticle];
	
	[articles sortUsingSelector:@selector(compareByDate:)];
	
	NSEnumerator *				enumerator = [articles reverseObjectEnumerator];
	KNArticle *					article = nil;
	
	while( (article = [enumerator nextObject]) ){
		if( [[article status] isEqualToString: StatusUnread] ){
			return article;
		}
	}
	return nil;
}
@end
