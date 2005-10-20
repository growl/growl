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


#import "FeedWindowController+Sources.h"
#import "InspectorController.h"
#import "Library.h"
#import "KNFeed.h"
#import "KNArticle.h"
#import "Prefs.h"


@implementation FeedWindowController (Sources)

#pragma mark -
#pragma mark Source Introspection

-(unsigned)unreadCountForSelection{
	KNDebug(@"unreadCountForSelection");
	return [self unreadCountWithIndexes: [feedOutlineView selectedRowIndexes]];
}

-(unsigned)unreadCountWithIndexes:(NSIndexSet *)anIndexSet{
	unsigned			unreadCount = 0;
	unsigned			currentIndex = [anIndexSet firstIndex];
	
	while( currentIndex != NSNotFound ){
		unreadCount += [[feedOutlineView itemAtRow: currentIndex] unreadCount];
		currentIndex = [anIndexSet indexGreaterThanIndex: currentIndex];
	}
	
	return unreadCount;
}

-(void)refreshArticleCache{
	
	KNDebug(@"refreshArticleCache");
	/* First, save off our selected article objects based on the current selection */
	NSIndexSet *				selectedArticleIndexes = [articleTableView selectedRowIndexes];
	unsigned					currentArticle = [selectedArticleIndexes firstIndex];
	NSMutableArray *			selectedArticles = [NSMutableArray array];
	while( currentArticle != NSNotFound ){
		[selectedArticles addObject: [articleCache objectAtIndex: currentArticle]];
		currentArticle = [selectedArticleIndexes indexGreaterThanIndex: currentArticle];
	}
	
	/* clear the current cache and generate the new cache based on the feed selection */
	[articleCache removeAllObjects];
	
	NSMutableSet *				activeFeeds = [NSMutableSet set];
	NSIndexSet *				selectedSourceIndexes = [feedOutlineView selectedRowIndexes];
	unsigned					currentSource = [selectedSourceIndexes firstIndex];
	
	while( currentSource != NSNotFound ){
		[activeFeeds addObjectsFromArray: [[[feedOutlineView itemAtRow: currentSource] uniqueItemsOfType:FeedItemTypeArticle] allObjects]];
		currentSource = [selectedSourceIndexes indexGreaterThanIndex: currentSource];
	}
	
	/* sort the resulting cache based on the sort descriptors */
	[articleCache sortUsingDescriptors: [PREFS sortDescriptors]];
	
	/* Finally, flip through the resulting cache and re-select any remaining articles from before */
	NSEnumerator *				enumerator = [selectedArticles objectEnumerator];
	KNArticle *					article = nil;
	NSMutableIndexSet *			newSelection = [NSMutableIndexSet indexSet];
	while( (article = [enumerator nextObject]) ){
		if( [articleCache indexOfObject: article] != NSNotFound ){
			[newSelection addIndex: [articleCache indexOfObject: article]];
		}
	}
	[articleTableView selectRowIndexes: newSelection byExtendingSelection: NO];
}

-(NSSet *)selectedFeeds{
	NSIndexSet *					selectedItems = [feedOutlineView selectedRowIndexes];
	unsigned						currentIndex = [selectedItems firstIndex];
	NSMutableSet *					feedSet = [NSMutableSet set];
	
	while( currentIndex != NSNotFound ){
		NSEnumerator *				enumerator = [[[feedOutlineView itemAtRow: currentIndex] itemsOfType: FeedItemTypeFeed] objectEnumerator];
		KNFeed *					feed;
		while( (feed = [enumerator nextObject]) ){
			[feedSet addObject: feed];
		}
		currentIndex = [selectedItems indexGreaterThanIndex: currentIndex];
	}
	
	return feedSet;
}

#pragma mark -
#pragma mark NSOutlineView Delegate Methods
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)column item:(id)item{
#pragma unused(outlineView,column,item)
	KNDebug(@"shouldEditTAbleColumn");
    //return( ([[outlineView selectedRowIndexes] count] == 1) && [LIB isFolderItem: item] );
	return YES;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification{
#pragma unused(notification)
	
	KNDebug(@"source selection changed");
	[PREFS setSourceSelectionIndexes: [feedOutlineView selectedRowIndexes]];
	[self refreshArticleCache];
	[articleTableView reloadData];
	[self updateStatus];
	[self setWindowTitle];
	
	// Set our item in our inspector
	if( [[feedOutlineView selectedRowIndexes] count] == 1 ){
		[inspector setItem: [feedOutlineView itemAtRow: [[feedOutlineView selectedRowIndexes] firstIndex]]];
	}else{
		[inspector setItem: nil];
	}
}

-(id)outlineView:(NSOutlineView *)outlineView child:(int)anIndex ofItem:(id)item{
#pragma unused(outlineView)
	if( ! item ){
		item = [LIB rootItem];
	}
	return [item childAtIndex: ((anIndex >= 0) ? anIndex : NSNotFound)];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
#pragma unused(outlineView)
	if( ! item ){
		item = [LIB rootItem];
	}
    return [[item type] isEqualToString:FeedItemTypeItem];
}

-(int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
#pragma unused(outlineView)
	if( ! item ){
		item = [LIB rootItem];
	}
    return [item childCount];
}

-(void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
#pragma unused(outlineView,tableColumn)
	NSImage *				sourceImage = nil;
	NSImage *				cellImage = nil;
	
	if( ! item ){
		item = [LIB rootItem];
	}
	
	if( [[item type] isEqualToString: FeedItemTypeItem] ){
		sourceImage = folderImage;
	}else if( [[item type] isEqualToString: FeedItemTypeFeed] ){
		if( ![[(KNFeed *)item lastError] isEqualToString:@""] ){
			sourceImage = [NSImage imageNamed:FeedErrorImage];
		}else{
			sourceImage = [(KNFeed *)item faviconImage];
		}
	}else if( [[item type] isEqualToString: FeedItemTypeArticle] ){
		sourceImage = [NSImage imageNamed:BookmarkImage];
	}
	
	if( sourceImage ){
		cellImage = [sourceImage copy];
		[cellImage setScalesWhenResized: YES];
		[cellImage setSize: NSMakeSize( 16, 16 )];
		[cell setImage: cellImage];
		[cellImage release];
	}
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)column byItem:(id)item{
#pragma unused(outlineView)
	if( ! item ){ item = [LIB rootItem]; }
	
    NSAttributedString *		value;
	NSCell *					currentCell = [column dataCell];
    NSFontManager *				fontManager = [NSFontManager sharedFontManager];
	NSMutableDictionary *		attributes = [NSMutableDictionary dictionary];
    
	[attributes setObject: tableWrapStyle forKey: NSParagraphStyleAttributeName];
	
	NSMutableString *			rawValue = nil;
	
	if( [item valueForKeyPath:@"prefs.userSetName"] && ![[item valueForKeyPath:@"prefs.userSetName"] isEqualToString:@""]){
		rawValue = [NSMutableString stringWithString: [item valueForKeyPath:@"prefs.userSetName"]];
	}else{
		rawValue = [NSMutableString stringWithString: [(KNItem *)item name]];
	}
	
	if( ([item unreadCount] > 0) && ([feedOutlineView editedRow] != [feedOutlineView rowForItem: item]) ){
		[attributes setObject: [fontManager convertFont: [currentCell font] toHaveTrait:NSBoldFontMask] forKey: NSFontAttributeName];
		[rawValue appendFormat: @" (%d)", [item unreadCount]];
	}else{
		[attributes setObject: [fontManager convertFont: [currentCell font] toNotHaveTrait:NSBoldFontMask] forKey: NSFontAttributeName];
	}
	
	if( [[item type] isEqualToString:FeedItemTypeFeed] && ![[item lastError] isEqualToString:@""] ){
		[attributes setObject:[NSColor redColor] forKey: NSForegroundColorAttributeName];
	}
	
	value = [[[NSAttributedString alloc] initWithString: rawValue attributes: attributes] autorelease];

	return value;
}

-(NSString *)outlineView:(NSOutlineView *)outlineView toolTipForTableColumn:(NSTableColumn *)column row:(int)rowIndex{
#pragma unused(outlineView,column)
	KNItem *				item = [feedOutlineView itemAtRow: rowIndex];
	
	if( item ){
		if( [[item type] isEqualToString:FeedItemTypeFeed] ){
			if( ![[(KNFeed *)item lastError] isEqualToString:@""] ){
				return [(KNFeed *)item lastError];
			}else{
				return [(KNFeed *)item sourceURL];
			}
		}else if( [[item type] isEqualToString:FeedItemTypeItem] ){
			return [NSString stringWithFormat: @"Contains %d feeds", [[item itemsOfType: FeedItemTypeFeed] count]];
		}else if( [[item type] isEqualToString:FeedItemTypeArticle] ){
			return [NSString stringWithFormat: @"Feed: %@", [(KNArticle *)item feedName]];
		}
	}
	return nil;
}

-(void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)column byItem:(id)item{
#pragma unused(outlineView,column)
	[(KNItem *)item setName: object];
}

-(id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item{
#pragma unused(outlineView)
	if( ! item ){ item = [LIB rootItem]; }
	return [item key];
}

-(id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object{
#pragma unused(outlineView)
	return [LIB itemForKey: object];
}


@end
