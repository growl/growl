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

#import "Library+Items.h"


@implementation Library (Items)


-(NSString *)typeForItem:(id)item{
	return [item type];
}

-(BOOL)isFolderItem:(id)item{
	if( !item ){ item = rootItem; }
	return [[item type] isEqualToString: FeedItemTypeItem];
}

-(BOOL)isFeedItem:(id)item{
	if( ! item ){ item = rootItem; }
	return [[item type] isEqualToString: FeedItemTypeFeed];
}

-(BOOL)isArticleItem:(id)item{
	if( ! item ){ item = rootItem; }
	return [[item type] isEqualToString: FeedItemTypeArticle];
}

-(BOOL)isItem:(id)item1 descendentOfItem:(id)item2{
	if( ! item1 ){ item1 = rootItem; }
	if( ! item2 ){ item2 = rootItem; }
	return ( [item2 itemForKey: [item1 key]] != nil );
}

-(id)newFolderNamed:(NSString *)name inItem:(id)item atIndex:(int)anIndex{
	KNItem *					newItem = [[KNItem alloc] init];
	
	if( ! item ){ item = rootItem; }
	[newItem setName: name];
	[(KNItem *)item insertChild: newItem atIndex: anIndex];
	[newItem release];
	
	return newItem;
}

-(id)newFeed:(KNFeed *)feed inItem:(id)item atIndex:(int)anIndex{
	if( ! item ){ item = rootItem; }
	[(KNItem *)item insertChild: feed atIndex: anIndex];
	
	return feed;
}

-(id)newArticle:(KNArticle *)article inItem:(id)item atIndex:(int)anIndex{
	if( ! item ){ item = rootItem; }
	[(KNItem *)item insertChild: article atIndex: anIndex];
	
	return article;
}

-(void)removeItem:(id)item{
	[self removeItem: item fromItem: [item parent]];
}

-(void)removeItem:(id)item fromItem:(id)parentItem{
	if( ! parentItem ){ parentItem = rootItem; }
	KNDebug(@"LIB removeItem from %@", parentItem);
	[parentItem removeChild: item];
}

-(void)moveItem:(id)item toParent:(id)newParent index:(int)anIndex{
	KNItem *				oldParent = (KNItem *) [item parent];
	
	if( ! oldParent ){ oldParent = rootItem; KNDebug(@"Using root as old parent");}
	if( ! newParent ){ newParent = rootItem; KNDebug(@"Using root as new parent");}
	KNDebug(@"About to move item %@ from %@ to %@ (%d)", item, oldParent, newParent, anIndex);
	
	[item retain];
	[oldParent removeChild: item];
	[newParent insertChild: item atIndex: anIndex];
	[item release];
}

-(NSString *)nameForItem:(id)item{
	if( ! item ){ item = rootItem; }
	return [item name];
}

-(NSString *)keyForItem:(id)item{
	if( ! item ){ item = rootItem; }
	return [item key];
}

-(id)itemForKey:(NSString *)key{
	return [rootItem itemForKey: key];
}

-(void)setName:(NSString *)name forItem:(id)item{
	if( ! item ){ item = rootItem; }
	[(KNItem *)item setName: name];
}

-(KNFeed *)feedForItem:(id)item{
	if( ! item ){ item = rootItem; }
	if( [self isFeedItem: item] ){
		return (KNFeed *) item;
	}
	return nil;
}

-(KNArticle *)articleForItem:(id)item{
	if( ! item ){ item = rootItem; }
	if( [self isArticleItem: item] ){
		return (KNArticle *)item;
	}
	return nil;
}

-(id)child:(int)anIndex ofItem:(id)item{
	if( ! item ){ item = rootItem; }
	return [item childAtIndex: anIndex];
}

-(BOOL)hasChildren:(id)item{
	if( ! item ){ item = rootItem; }
	return ([item childCount] > 0);
}

-(int)childCountOfItem:(id)item{
	if( ! item ){ item = rootItem; }
	return [item childCount];
}

-(unsigned)unreadCountForItem:(id)item{
	if( ! item ){ item = rootItem; }
	return [item unreadCount];
}

@end
