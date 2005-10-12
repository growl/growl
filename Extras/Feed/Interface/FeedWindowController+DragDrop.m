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


#import "FeedWindowController+DragDrop.h"
#import "Library+Items.h"
#import "Library+Active.h"
#import "Library+Update.h"
#import "KNFeed.h"
#import "KNArticle.h"
#import "NSString+KNTruncate.h"


@implementation FeedWindowController (DragDrop)

-(NSArray *)draggedFeedItems{ return draggedFeedItems; }
-(NSArray *)draggedArticles{ return draggedArticles; }

-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard{
	if( draggedFeedItems ){ [draggedFeedItems release]; }
	draggedFeedItems = [items retain];
	currentDragSource = outlineView;
	[pboard declareTypes:[NSArray arrayWithObjects: DragDropFeedItemPboardType, NSStringPboardType, nil] owner: self];
	[pboard setData: [NSData data] forType: DragDropFeedItemPboardType];
	return YES;
}

-(unsigned int)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)childIndex{
	BOOL					targetNodeIsValid = YES;
	NSEnumerator *			enumerator;
	id						draggedItem;
	
	if( (item != nil) && (childIndex==NSOutlineViewDropOnItemIndex) && (![LIB isFolderItem: item]) ){
		targetNodeIsValid = NO;
	}
	
	
	if( targetNodeIsValid &&
		(([info draggingSource]==outlineView) || ([info draggingSource]==articleTableView)) &&
		[[info draggingPasteboard] availableTypeFromArray:
			[NSArray arrayWithObjects: DragDropFeedItemPboardType, DragDropFeedArticlePboardType, nil]] != nil ){
		
		if( [info draggingSource] == feedOutlineView ){
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while((draggedItem = [enumerator nextObject])){
				if( [LIB isItem: item descendentOfItem: draggedItem] ){
					targetNodeIsValid = NO;
					break;
				}
			}
		}
	}
	
	return targetNodeIsValid ? NSDragOperationGeneric : NSDragOperationNone;
}

-(BOOL)outlineView:(NSOutlineView*)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(int)childIndex{
	NSPasteboard *				pboard = [info draggingPasteboard];
	BOOL						dropOn = (childIndex == NSOutlineViewDropOnItemIndex);
	NSEnumerator *				enumerator;
	id							draggedItem;
	BOOL						didAccept = NO;
	int							newIndex = childIndex;
	
	
	// These types are internally handled
	if( [pboard availableTypeFromArray: [NSArray arrayWithObjects: DragDropFeedItemPboardType,DragDropFeedArticlePboardType,nil]] ){
		
		// set our index in case of general drop
		if( [LIB isFolderItem: targetItem] && dropOn ){
			KNDebug(@"Item is dropOn and folder for target %@", targetItem);
			//newIndex = [LIB childCountOfItem: targetItem];
			newIndex = 0;
		}
			
		
		//KNDebug(@"CONT: we reset our childIndex from %d to %d", childIndex, newIndex);
		if( [info draggingSource] == outlineView ){
			[feedOutlineView deselectAll: self];
			
			// Actually move all the items
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while((draggedItem = [enumerator nextObject])){
				KNDebug(@"moving item %@ to %@ (%d)", draggedItem, targetItem, newIndex);
				[LIB moveItem: draggedItem toParent: targetItem index: newIndex];
			}
			[feedOutlineView reloadData];
			
			// Reset our selection
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while((draggedItem = [enumerator nextObject])){
				[feedOutlineView selectRow: [feedOutlineView rowForItem:draggedItem] byExtendingSelection: YES];
			}
			didAccept = YES;
			[draggedFeedItems release];
			draggedFeedItems = nil;
		}
		
		if( [info draggingSource] == articleTableView ){
			KNDebug(@"CONT: drag from article table");
			NSMutableArray *			articleSelection = [NSMutableArray array];
			NSNumber *					draggedArticleIndex;
			
			
			enumerator = [[self draggedArticles] objectEnumerator];
			while((draggedArticleIndex = [enumerator nextObject])){
				KNArticle *				article = [LIB activeArticleAtIndex: [draggedArticleIndex intValue]];

				draggedItem = [LIB newArticle: article inItem: targetItem atIndex: newIndex];
				[articleSelection addObject: draggedItem];
			}
			[feedOutlineView reloadData];
			[feedOutlineView deselectAll: self];
			
			enumerator = [articleSelection objectEnumerator];
			while((draggedItem = [enumerator nextObject])){
				[feedOutlineView selectRow: [feedOutlineView rowForItem: draggedItem] byExtendingSelection: YES];
			}
			
			didAccept = YES;
			[draggedArticles release];
			draggedArticles = nil;
		}
	}else if( [pboard availableTypeFromArray: [NSArray arrayWithObjects: NSStringPboardType,nil]] ){
		NSString *				draggedString = [pboard stringForType: NSStringPboardType];
		NSArray *				sources = [draggedString componentsSeparatedByString:@"\n"];
		NSString *				newSource;
		KNFeed *					newFeed;
		int						feedsAdded = 0;
		
		enumerator = [sources objectEnumerator];
		while((newSource = [enumerator nextObject])){
			NSMutableString *			cleanSource = [NSMutableString stringWithString: newSource];

			[cleanSource replaceOccurrencesOfString:@"feed:" withString:@"http:" options:NSCaseInsensitiveSearch range:NSMakeRange(0,5)];
			newFeed = [[KNFeed alloc] init];
			[newFeed setSourceURL: cleanSource];
			[newFeed setName: cleanSource];
			if( [LIB newFeed: newFeed inItem: targetItem atIndex: newIndex ] ){
				[LIB refreshFeed: newFeed];
				feedsAdded++;
			}
			[newFeed release];
		}
		
		if( feedsAdded > 0 ){
			[LIB startUpdate];
			didAccept = YES;
		}
	}
	
	return didAccept;
}

-(BOOL)tableView:(NSTableView *)tableView writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard{
	if( draggedArticles ){ [draggedArticles release]; }
	draggedArticles = rows;
	[draggedArticles retain];
	currentDragSource = tableView;
	[pboard declareTypes:[NSArray arrayWithObjects: DragDropFeedArticlePboardType, NSStringPboardType, nil] owner: self];
	[pboard setData: [NSData data] forType: DragDropFeedArticlePboardType];
	
	return YES;
}

-(void)pasteboard:(NSPasteboard *)pboard provideDataForType:(NSString *)type{
	NSEnumerator *				enumerator;
	KNArticle *					article;
	KNFeed *						feed;
	id							feedItem;
	NSNumber *					articleIndex;
	NSMutableString *			draggedString = [NSMutableString string];
	NSEnumerator *				folderEnumerator;
	
	if( [type isEqualToString: NSStringPboardType] ){
		
		if( currentDragSource == articleTableView ){
			enumerator = [[self draggedArticles] objectEnumerator];
			while((articleIndex = [enumerator nextObject])){
				article = [LIB activeArticleAtIndex: [articleIndex intValue]];
				if( ![[article link] isEqualToString: @""] ){
					[draggedString appendFormat: @"%@\n", [article link]];
				}
			}
		}else if( currentDragSource == feedOutlineView ){
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while((feedItem = [enumerator nextObject])){
				if( [LIB isFeedItem: feedItem] ){
					[draggedString appendFormat: @"%@\n", [[LIB feedForItem: feedItem] sourceURL]];
					
				}else if( [LIB isFolderItem: feedItem] ){
					folderEnumerator = [[LIB feedsInFolder: feedItem] objectEnumerator];
					while((feed = [folderEnumerator nextObject])){
						[draggedString appendFormat: @"%@\n", [feed sourceURL]];
					}
					
				}else if( [LIB isArticleItem: feedItem] ){
					article = [LIB articleForItem: feedItem];
					if( ! [[article link] isEqualToString: @""] ){
						[draggedString appendFormat: @"%@\n", [article link]];
					}
					
				}
			}
		}
		[pboard setString: [draggedString trimWhitespace] forType: type];
	}
}


@end
