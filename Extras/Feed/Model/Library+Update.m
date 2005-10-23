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

#import "Library+Update.h"

#import "RSSReader.h"
#import "AtomReader.h"
#import "Prefs.h"

@implementation Library (Update)

-(void)refreshFeed:(KNFeed *)aFeed{
	//KNDebug(@"LIB: refreshFeed");
	if( [feedsToUpdate indexOfObject: aFeed] == NSNotFound ){
		[feedsToUpdate addObject: aFeed];
	}
}

-(BOOL)refreshAll{
	NSEnumerator *			enumerator = [[rootItem itemsOfType: FeedItemTypeFeed] objectEnumerator];
	KNFeed *					feed = nil;
	
	[feedsToUpdate removeAllObjects];
	while((feed = [enumerator nextObject])){
		[feedsToUpdate addObject: feed];
	}
	return [self startUpdate];
}

-(void)refreshPending{
	NSEnumerator *			enumerator = [[rootItem itemsOfType: FeedItemTypeFeed] objectEnumerator];
	KNFeed *					feed = nil;
	
	//KNDebug(@"refreshPending called");
	while((feed = [enumerator nextObject])){
		if( [[feed valueForKeyPath:@"prefs.wantsUpdate"] boolValue] ){
			if( [feedsToUpdate indexOfObject: feed] == NSNotFound ){
				KNDebug(@"Will update source %@", feed);
				[feedsToUpdate addObject: feed];
			}
		}
	}
	if( [feedsToUpdate count] > 0 ){
		[self startUpdate];
	}
}

-(BOOL)startUpdate{
	if( KNNetworkReachablePolitely( @"apple.com" ) ){
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
    //KNDebug(@"LIB: Update Started. %d items to update", [feedsToUpdate count]);
    isUpdating = YES;
	unreadFeedCount = [rootItem unreadCount];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateStartedNotification object: nil];
}

-(void)willUpdateFeed:(KNFeed *)aFeed{
	[[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateWillUpdateFeedNotification object: aFeed];
}

-(void)updateFeed:(KNFeed *)aFeed headers:(NSDictionary *)headers articles:(NSArray *)articles{
	//KNDebug(@"Got updateFeed for %@", aFeed);
    NSEnumerator *          enumerator = nil;
    NSDictionary *          articleDict = nil;
    NSString *				propName = nil;
	
	[aFeed setLastError: @""];
	enumerator = [headers keyEnumerator];
	while( (propName=[enumerator nextObject]) ){
		[aFeed setValue:[headers objectForKey: propName] forKey: propName];
	}
	
	[aFeed willUpdateArticles];
	enumerator = [articles objectEnumerator];
    while((articleDict = [enumerator nextObject])){
		[aFeed refreshArticleWithDictionary: articleDict];
    }
	[aFeed expireArticles];
	[aFeed didUpdateArticles];
	
	//KNDebug(@"LIB: feed %@ updated", [feed title]);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateDidUpdateFeedNotification object: aFeed];
	[activeReaders removeObjectForKey: [aFeed sourceURL]];
	
	[self runNextUpdate];
}

-(void)updateFeed:(KNFeed *)aFeed error:(NSString *)reason{
	if( [[aFeed sourceType] isEqualToString: FeedSourceTypeUnknown] && [[activeReaders objectForKey: [aFeed sourceURL]] isKindOfClass:[RSSReader class]] ){
		AtomReader *			newReader = [[AtomReader alloc] initWithLibrary: self feed: aFeed];
		
		//KNDebug(@"LIB: retrying unknown feed as Atom");
		if( newReader ){
			[activeReaders setObject: newReader forKey: [aFeed sourceURL]];
			[newReader release];
		}
		
	}else{
		[aFeed setLastError: reason];
		//KNDebug(@"feed %@ error %@", [aFeed name], reason);
		[[NSNotificationCenter defaultCenter] postNotificationName: FeedUpdateDidUpdateFeedNotification object: aFeed];
		
		[activeReaders removeObjectForKey: [aFeed sourceURL]];
		[self runNextUpdate];
	}
}

-(void)runNextUpdate{
	KNFeed *				feed = nil;
	FeedReader *		newReader = nil;
	
	//KNDebug(@"runNextUpdate: %u left (%u:%u)", [feedsToUpdate count], [activeReaders count], [PREFS maxUpdateThreads]);
	//KNDebug(@"runNextUpdate: %u left (%@)", [feedsToUpdate count], activeReaders);
	if( [feedsToUpdate count] > 0U ){
		while( ((int)[activeReaders count] < [PREFS maxUpdateThreads]) && ([feedsToUpdate count] > 0U) ){
			
			newReader = nil;
			
			feed = [feedsToUpdate objectAtIndex:0];
			[feedsToUpdate removeObjectAtIndex: 0];
			
			if( [[feed sourceType] isEqualToString: FeedSourceTypeRSS] ||
				[[feed sourceType] isEqualToString: FeedSourceTypeUnknown]
			){
				newReader = [[RSSReader alloc] initWithLibrary: self feed: feed];
			}else if( [[feed sourceType] isEqualToString: FeedSourceTypeAtom] ){
				newReader = [[AtomReader alloc] initWithLibrary: self feed: feed];
			}
			
			if( newReader ){
				[activeReaders setObject: newReader forKey: [feed sourceURL]];
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
	isUpdating = NO;
	unsigned newUnreadCount = [rootItem unreadCount];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:FeedUpdateFinishedNotification object: nil 
		userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt: (newUnreadCount - unreadFeedCount)], @"NewArticleCount",
		nil]
	];
	if( unreadFeedCount < newUnreadCount ){
		unreadFeedCount = newUnreadCount;
		if(! [[PREFS notificationSoundName] isEqualToString: @""] ){
			NSSound *			notificationSound = [NSSound soundNamed: [PREFS notificationSoundName]];
			if( notificationSound ){
				[notificationSound play];
			}
		}
	}
}


@end
