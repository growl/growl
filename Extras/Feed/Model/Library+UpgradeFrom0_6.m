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

#import "Library+UpgradeFrom0_6.h"
#import "Article.h"
#import "Feed.h"
#import "Prefs.h"

#define LibraryFeedRoot @"FeedRoot"
#define LibraryDeletedArticleKeys @"DeletedArticleKeys"
#define LibrarySortDescriptors @"SortDescriptors"

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

@implementation Library (UpgradeFrom0_6)
-(BOOL)version0_6Exists{
	return [[NSFileManager defaultManager] fileExistsAtPath: [[Library defaultLibraryFolder] stringByAppendingPathComponent:@"Library.feed"]];
}

-(BOOL)upgrade0_6{

	NSData *				fileData = [[NSFileManager defaultManager] contentsAtPath: [[Library defaultLibraryFolder] stringByAppendingPathComponent:@"Library.feed"]];
	if( ! fileData ){ return NO; }
	
	NSMutableDictionary *	library = nil;
	library = [NSKeyedUnarchiver unarchiveObjectWithData: fileData];
	if( ! library ){ return NO; }
	
	// Start walking the tree
	NSDictionary *			oldRoot = [library objectForKey: LibraryFeedRoot];
	if( ! oldRoot ){ return NO; }
	
	KNDebug(@"Loaded old root: %u items", [oldRoot count]);
	NSEnumerator *			enumerator = [oldRoot objectEnumerator];
	NSDictionary *			child = nil;
	NSArray *				killList = [library objectForKey:LibraryDeletedArticleKeys];
	
	while( (child = [enumerator nextObject]) ){
		[self import0_6Item: child intoItem: [self rootItem] ignoringArticles: killList];
	}
	
	// Bring over our sort descriptors. This is the only 'pref' we're pulling from the old library
	if( [library objectForKey: LibrarySortDescriptors] ){
		[PREFS setSortDescriptors: [library objectForKey: LibrarySortDescriptors]];
	}
	
	return YES;
}


-(void)import0_6Item:(NSDictionary *)oldChild intoItem:(KNItem *)newParent ignoringArticles:(NSArray *)ignoredArticles{
		
	if( [[oldChild objectForKey: TreeItemType] isEqualToString: TreeItemTypeFolder] ){
		KNItem *				newItem = [[KNItem alloc] init];
		
		[newItem setName: [oldChild objectForKey:TreeItemName]];
		[newParent addChild: newItem];
		
		NSEnumerator *			enumerator = [[oldChild objectForKey: TreeChildArray] objectEnumerator];
		NSDictionary *			child = nil;
		
		while( (child = [enumerator nextObject]) ){
			[self import0_6Item: child intoItem: newItem ignoringArticles: ignoredArticles];
		}
		
	}else if( [[oldChild objectForKey: TreeItemType] isEqualToString: TreeItemTypeFeed] ){
		Feed *					oldFeed = [oldChild objectForKey: TreeFeedObject];
		KNFeed *				newFeed = [[KNFeed alloc] init];
		
		if( oldFeed ){
			// Transfer over basic properties
			[newFeed setName: [oldFeed title]];
			if( ! [[oldFeed userTitle] isEqualToString: @""] ){
				[newFeed setValue:[oldFeed userTitle] forKey:@"prefs.userSetName"];
			}
			[newFeed setSourceURL: [oldFeed source]];
			[newFeed setSourceType: [oldFeed type]];
			[newFeed setFaviconImage: [oldFeed icon]];
			[newFeed setSummary: [oldFeed summary]];
			[newFeed setLink: [oldFeed link]];
			[newFeed setImageURL: [oldFeed image]];
			if( [oldFeed error] ){
				[newFeed setLastError: [oldFeed error]];
			}
						
			// Bring in the articles
			NSEnumerator *				enumerator = [[oldFeed articles] objectEnumerator];
			Article *					oldArticle = nil;
			
			while( (oldArticle = [enumerator nextObject]) ){
				KNArticle *					newArticle = [[KNArticle alloc] init];
				
				[newArticle setName: [oldArticle title]];
				[newArticle setGuid: [oldArticle key]];
				[newArticle setLink: [oldArticle link]];
				[newArticle setSourceURL: [oldArticle sourceURL]];
				[newArticle setCommentsURL: [oldArticle comments]];
				[newArticle setAuthor: [oldArticle author]];
				[newArticle setCategory: [oldArticle category]];
				[newArticle setDate: [oldArticle date]];
				[newArticle setContent: [oldArticle content]];
				[newArticle setStatus: [oldArticle status]];
				
				[newArticle setIsOnServer: YES];
				
				if( ignoredArticles && ([ignoredArticles indexOfObject: [oldArticle key]] != NSNotFound) ){
					[newArticle setIsSuppressed: YES];
				}
				
				[newFeed addChild: newArticle];
			}
			
			[newParent addChild: newFeed];
		}
		
	}else if( [[oldChild objectForKey: TreeItemType] isEqualToString: TreeItemTypeArticle] ){
		Article *					oldArticle =  [oldChild objectForKey: TreeArticleObject];
		
		if( oldArticle ){
			KNArticle *					newArticle = [[KNArticle alloc] init];
			
			[newArticle setName: [oldArticle title]];
			[newArticle setGuid: [oldArticle key]];
			[newArticle setLink: [oldArticle link]];
			[newArticle setSourceURL: [oldArticle sourceURL]];
			[newArticle setCommentsURL: [oldArticle comments]];
			[newArticle setAuthor: [oldArticle author]];
			[newArticle setCategory: [oldArticle category]];
			[newArticle setDate: [oldArticle date]];
			[newArticle setContent: [oldArticle content]];
			[newArticle setIsOnServer: [oldArticle isOnServer]];
			[newArticle setStatus: [oldArticle status]];
			
			[newParent addChild: newArticle];
		}
	}
}

@end
