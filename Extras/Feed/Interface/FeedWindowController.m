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

#import "FeedWindowController.h"
#import "FeedWindowController+Sources.h"

#import "FeedDelegate.h"
#import "Library.h"
#import "Library+Update.h"
#import "Library+Items.h"
#import "Library+Utility.h"

#import "KNFeed.h"
#import "KNArticle.h"
#import "Prefs.h"
#import "LibraryToolbar.h"
//#import "ImageTextCell.h"
#import <WebKit/WebKit.h>

#import "NSString+KNTruncate.h"
#import "NSDate+KNExtras.h"

#import "InspectorController.h"

#define FeedLibraryNibName @"FeedLibrary"
#define TOGGLE_FEED_DRAWER_MENU 1024

#define SOURCE_VALIDATION_URL @"http://feedvalidator.org/check.cgi?url="

@implementation FeedWindowController

-(id)init{
	//KNDebug(@"CONT: init before super");
    self = [super initWithWindowNibName:FeedLibraryNibName];
    if( self ){
		KNDebug(@"CONT: init");
        viewColumns = [[NSArray arrayWithObjects:
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithString:@""], ColumnName,
                                [NSString stringWithString:ArticleStatus], ColumnIdentifier,
                                [NSNumber numberWithBool: NO], ColumnCanDisable,
                                [NSNumber numberWithInt: 20], ColumnWidth,
                            nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithString:@"Title"], ColumnName,
                                [NSString stringWithString:ArticleTitle], ColumnIdentifier,
                                [NSNumber numberWithBool: NO], ColumnCanDisable,
                                [NSNumber numberWithInt: 200], ColumnWidth,
                            nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithString:@"Author"], ColumnName,
                                [NSString stringWithString:ArticleAuthor], ColumnIdentifier,
                                [NSNumber numberWithBool: YES], ColumnCanDisable,
                                [NSNumber numberWithInt: 60], ColumnWidth,
                            nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithString:@"Category"], ColumnName,
                                [NSString stringWithString:ArticleCategory], ColumnIdentifier,
                                [NSNumber numberWithBool: YES], ColumnCanDisable,
                                [NSNumber numberWithInt: 60], ColumnWidth,
                            nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithString:@"Date"], ColumnName,
                                [NSString stringWithString:ArticleDate], ColumnIdentifier,
                                [NSNumber numberWithBool: YES], ColumnCanDisable,
                                [NSNumber numberWithInt: 75], ColumnWidth,
                            nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithString:@"Feed"], ColumnName,
                                [NSString stringWithString:ArticleFeedName], ColumnIdentifier,
                                [NSNumber numberWithBool: YES], ColumnCanDisable,
                                [NSNumber numberWithInt: 60], ColumnWidth,
                            nil],
							[NSMutableDictionary dictionaryWithObjectsAndKeys:
								[NSString stringWithString:@"Server Status"], ColumnName,
								[NSString stringWithString:ArticleIsOnServer], ColumnIdentifier,
								[NSNumber numberWithBool: YES], ColumnCanDisable,
								[NSNumber numberWithInt: 20], ColumnWidth,
							nil],
							[NSMutableDictionary dictionaryWithObjectsAndKeys:
								[NSString stringWithString:@"Source"], ColumnName,
								[NSString stringWithString:ArticleSourceURL], ColumnIdentifier,
								[NSNumber numberWithBool: YES], ColumnCanDisable,
								[NSNumber numberWithInt: 60], ColumnWidth,
							nil],
                    nil] retain];
		articleCache = [[NSMutableArray array] retain];
        disableResizeNotifications = YES;
		inspector = [[InspectorController alloc] init];
        feedLibraryToolbar = [[LibraryToolbar alloc] initWithWindow: [self window]];
		currentUpdatingFeedTitle = [[NSString string] retain];
    }
    return self;
}

-(void)dealloc{
    [viewColumns release];
	[articleCache release];
	[inspector release];
    [feedLibraryToolbar release];
	[currentUpdatingFeedTitle release];
	
    [super dealloc];
}




-(void)setWindowTitle{
	KNDebug(@"setWindowTitle");
	
    NSString *              title = @"Feed";
    unsigned				unreadCount = 0U;
	NSSet *					sources = [self selectedFeeds];
	
    if( [sources count] == 1 ){
        title = [NSString stringWithFormat:@"%@ : %@", title, [[sources anyObject] name] ];
    }else if( [sources count] > 1 ){
        title = [NSString stringWithFormat:@"%@ : %d Sources Selected", title, [sources count]];
    }
    
	unreadCount = [self unreadCountForSelection];
    if( unreadCount > 0 ){
        title = [NSString stringWithFormat:@"%@ (%d Unread)", title, unreadCount];
    }
    
    [[self window] setTitle: title];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    if( [menuItem action] == @selector(removeFeedItem:) ){
		
		if( [[feedOutlineView selectedRowIndexes] count] == 0 ){ return NO; }
		
		if( [[feedOutlineView selectedRowIndexes] count] == 1 ){
			KNItem *		item = [feedOutlineView itemAtRow: [[feedOutlineView selectedRowIndexes] firstIndex]];
			
			if( [[item type] isEqualToString: FeedItemTypeItem] ){
				[menuItem setTitle: @"Delete Folder"];
			}else if( [[item type] isEqualToString: FeedItemTypeFeed] ){
				[menuItem setTitle: @"Delete Feed"];
			}
		}else{
			[menuItem setTitle: @"Delete Selected"];
		}
    }else if( [menuItem action] == @selector(removeArticle:) ){
		if( [[articleTableView selectedRowIndexes] count] > 0 ){
			if( [[articleTableView selectedRowIndexes] count] == 1 ){
				[menuItem setTitle: @"Delete Article"];
			}else{
				[menuItem setTitle: @"Delete Selected"];
			}
		}else{
			return NO;
		}
	
	}else if( [menuItem action] == @selector(refreshItem:) ){
		if( [[feedOutlineView selectedRowIndexes] count] == 0 ){
			[menuItem setTitle: @"Update"];
			return NO;
		}else{
			if( [[feedOutlineView selectedRowIndexes] count] == 1 ){
				KNItem *		item = [feedOutlineView itemAtRow: [[feedOutlineView selectedRowIndexes] firstIndex]];
				
				if( [[item type] isEqualToString: FeedItemTypeItem] ){
					[menuItem setTitle: @"Update Folder"];
				}else if( [[item type] isEqualToString: FeedItemTypeFeed] ){
					[menuItem setTitle: @"Update Feed"];
				}else if( [[item type] isEqualToString: FeedItemTypeArticle] ){
					[menuItem setTitle: @"Update"];
					return NO;
				}
			}else{
				[menuItem setTitle: @"Update Selected"];
			}
		}
		
		if( isUpdating ){ return NO; }
	}else if( [menuItem action] == @selector(refresh:) ){
		if( [[menuItem title] isEqualToString: @"Cancel Update"] ){
			return isUpdating;
		}else{
			return ! isUpdating;
		}
		
	}else if( [menuItem action] == @selector(toggleArticleStatus:) ){
		if( [[articleTableView selectedRowIndexes] count] == 0 ){ return NO; }
		
		if( [[self selectedArticleStatus] isEqualToString: StatusRead] ){
			[menuItem setTitle: @"Mark As Unread"];
		}else{
			[menuItem setTitle: @"Mark As Read"];
		}
		
	}else if( [menuItem action] == @selector(toggleFeedDrawer:) ){
		if( ([feedDrawer state] == NSDrawerClosedState) || ([feedDrawer state] == NSDrawerClosingState) ){
			[menuItem setTitle: @"Show Feeds..."];
		}else{
			[menuItem setTitle: @"Hide Feeds..."];
		}
		
	}else if( [menuItem action] == @selector(bookmarkArticle:) ){
		[menuItem setTitle: @"Bookmark Article"];
		if( [[articleTableView selectedRowIndexes] count] == 0 ){ return NO; }
		
		if( [[articleTableView selectedRowIndexes] count] > 1 ){
			[menuItem setTitle: @"Bookmark Selected"];
		}
		
	}else if( [menuItem action] == @selector(nextUnread:) ){
		if( [self unreadCountForSelection] <= 0 ){
			return NO;
		}
	}else if( [menuItem action] == @selector(getInfo:) ){
		if( [[feedOutlineView selectedRowIndexes] count] == 1 ){
			return YES;
		}
		return NO;
	}else if( [menuItem action] == @selector(markAllRead:) ){
		if( ![[self activeArticleStatus] isEqualToString: StatusUnread] ){
			return NO;
		}
	}
    return YES;
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem{
    if( [[toolbarItem itemIdentifier] isEqualToString: REMOVE_FEED] ){
		if( [[self window] firstResponder] == articleTableView ){
			return([[articleTableView selectedRowIndexes] count] > 0);
		}
		if( [[self window] firstResponder] == feedOutlineView ){
			return( [[feedOutlineView selectedRowIndexes] count] > 0 );
		}
		return NO;
    }
    
	if( [[toolbarItem itemIdentifier] isEqualToString: UPDATE_ALL] ){
		//[toolbarItem setMinSize: NSMakeSize( 50 , 32 )];
		if( isUpdating ){
			[toolbarItem setLabel: @"Cancel"];
			[toolbarItem setToolTip: @"Cancel the current update"];
		}else{
			[toolbarItem setLabel: @"Update"];
			[toolbarItem setToolTip: @"Update selected sources immediately"];
		}
	}
	
	if( [[toolbarItem itemIdentifier] isEqualToString: MARK_ALL_READ] ){
		return( [[self activeArticleStatus] isEqualToString: StatusUnread] );
	}
    
    return YES;
}

-(void)feedUpdateStarted:(NSNotification *)notification{
#pragma unused(notification)
	KNDebug(@"CONT: feedUpdateStarted");
    //[refreshAllButton setEnabled: NO];
    isUpdating = YES;
	[statusProgressIndicator startAnimation:self];
	[currentUpdatingFeedTitle autorelease];
	currentUpdatingFeedTitle = [[NSString string] retain];
}

-(void)feedWillUpdate:(NSNotification *)notification{
	KNFeed *					feed = [notification object];
	//KNDebug(@"CONT: Got a feed update notification for %@", feedURL);
	[currentUpdatingFeedTitle autorelease];
	currentUpdatingFeedTitle = [[feed name] retain];
	[self updateStatus];
}

-(void)feedDidUpdate:(NSNotification *)notification{
#pragma unused(notification)
	[self reloadData];
}

-(void)feedUpdateFinished:(NSNotification *)notification{
#pragma unused(notification)
	KNDebug(@"CONT: feedUpdateFinished");
	
	isUpdating = NO;
	[statusProgressIndicator stopAnimation:self];
    //[LIB refreshActiveArticles];
	[self reloadData];
	
    //[articleTableView scrollRowToVisible: [LIB activeArticleCount]-1];
	//[self setDisplayedArticle: [LIB activeArticle]];
}

#pragma mark -
#pragma mark Utility Methods

-(void)columnVisibilityDidChange:(id)sender{
    NSMutableDictionary *           columnRecord = [viewColumns objectAtIndex: [sender tag]];
    //KNDebug(@"Column Changed: %@", columnRecord );
    
    if( [[columnRecord objectForKey: ColumnState] isEqualToString: ColumnStateOff] ){
        [articleTableView addTableColumn: [columnRecord objectForKey: ColumnHeaderObject]];
        [columnRecord setObject: ColumnStateVisible forKey: ColumnState];
        [sender setState: NSOnState];
    }else{
        [articleTableView removeTableColumn: [columnRecord objectForKey: ColumnHeaderObject]];
        [columnRecord setObject: ColumnStateOff forKey: ColumnState];
        [sender setState: NSOffState];
    }
    
    [self rememberVisibleColumns: self];
}

-(void)rememberVisibleColumns:(id)sender{
#pragma unused(sender)
    NSEnumerator *              enumerator = [[articleTableView tableColumns] objectEnumerator];
    NSTableColumn *             column;
    NSMutableArray *            columnArray = [NSMutableArray array];
    NSDictionary *              columnData;
    int                         i,idx;
    
    while((column = [enumerator nextObject])){
        //KNDebug(@"remembering column %@", [column identifier]);
        idx = -1;
        for(i=0;i<(int)[viewColumns count];i++){
            if( [[[viewColumns objectAtIndex:i] objectForKey:ColumnIdentifier] isEqualToString: [column identifier]] ){
                idx = i;
                break;
            }
        }
        if( idx > -1 ){
            columnData = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt: idx], ColumnIndex,
                    [NSNumber numberWithFloat: [column width]], ColumnWidth,
            nil];
            [columnArray addObject: columnData];
        }
    }
    [PREFS setVisibleArticleColumns: columnArray];
}


-(void)updateStatus{
	NSMutableString *			status = [NSMutableString stringWithFormat:@"%d articles", [articleCache count]];
	
	//KNDebug(@"updateStatus - %@", status);
	if( isUpdating ){
		[status appendFormat:@" - Updating %@", currentUpdatingFeedTitle];
	}
	[statusTextField setStringValue: status];
}

-(IBAction)reloadData{
	KNDebug(@"WIN reloadData");
	[feedOutlineView reloadData];
	[self refreshArticleCache];
	[articleTableView reloadData];
	
	[self updateStatus];
	[self setWindowTitle];
	[[NSApp delegate] updateDockIcon];
}

-(void)setDisplayedArticle:(KNArticle *)anArticle{
	NSString *					previewCachePath = nil;
    NSURL *                     base = nil;
    
    KNDebug(@"CONT: setDisplayedArticle");
    
    if( anArticle ){
		[anArticle setStatus: StatusRead];
		//previewCachePath = [anArticle previewCachePath];
		previewCachePath = [LIB previewCacheForArticle: anArticle];
        base = [NSURL URLWithString: [anArticle link]];
		[[NSApp delegate] updateDockIcon];
		[feedOutlineView reloadData];
    }
    
    KNDebug(@"baseURL: %@", base);
	isLoadingDisplay = YES;
	if( previewCachePath ){
		[[displayWebView mainFrame] loadRequest: [NSURLRequest requestWithURL: [NSURL fileURLWithPath: previewCachePath]]];
	}else{
		[[displayWebView mainFrame] loadHTMLString: @"" baseURL: base ];
	}
}


#pragma mark-
#pragma mark Preference Notifications

-(void)articleListFontChanged:(NSNotification *)notification{
#pragma unused(notification)
	//NSEnumerator *				enumerator = [viewColumns objectEnumerator];
	//NSDictionary *				columnRec;
	return;
	
	KNDebug(@"CONT: changing list font");
	articleListFont = [NSFont fontWithName: [PREFS articleListFontName] size: [PREFS articleListFontSize]];
	/*while( columnRec = [enumerator nextObject] ){
		[[[columnRec objectForKey:ColumnHeaderObject] dataCell] setFont: articleListFont];
	}*/
	[articleTableView tile];
}

-(void)articleFontChanged:(NSNotification *)notification{
#pragma unused(notification)
	//articleFont = [NSFont fontWithName: [PREFS articleFontName] size: [PREFS articleFontSize]];
	if( [[articleTableView selectedRowIndexes] count] == 1 ){
		[self setDisplayedArticle: [articleCache objectAtIndex: [[articleTableView selectedRowIndexes] firstIndex]]];
	}else{
		[self setDisplayedArticle: nil];
	}
}

-(void)articleExpiredColorChanged:(NSNotification *)notification{
#pragma unused(notification)
	[articleTableView reloadData];
}

-(void)torrentSchemeChanged:(NSNotification *)notification{
#pragma unused(notification)
	#warning Disabled TorrentURL
	//[self setDisplayedArticle: [LIB activeArticle]];
}

#pragma mark -
#pragma mark Action Methods

-(IBAction)delete:(id)sender{
	id				activeView = [[self window] firstResponder];
	
	KNDebug(@"CONT: delete. STOP THIS!!!");
	if( activeView == articleTableView ){
		//KNDebug(@"CONT: article is active");
		[self removeArticle: sender];
	}else if( activeView == feedOutlineView ){
		//KNDebug(@"CONT: feed is active");
		[self removeFeedItem: sender];
	}
}

-(IBAction)toggleFeedDrawer:(id)sender{
    [feedDrawer toggle:sender];
}

/*
-(IBAction)cancelDialog:(id)sender{
    [NSApp stopModal];
}
*/

-(IBAction)refresh:(id)sender{
#pragma unused(sender)
	if( isUpdating ){
		[LIB cancelUpdate];
	}else{
		[LIB refreshAll];
	}
}

-(IBAction)refreshItem:(id)sender{
#pragma unused(sender)
	NSIndexSet *				selectedItems = [feedOutlineView selectedRowIndexes];
	unsigned					currentIndex = [selectedItems firstIndex];
	
	while( currentIndex != NSNotFound ){
		NSEnumerator *				enumerator = [[[feedOutlineView itemAtRow: currentIndex] itemsOfType: FeedItemTypeFeed] objectEnumerator];
		KNFeed *					feed = nil;
		
		while( (feed = [enumerator nextObject]) ){
			[LIB refreshFeed: feed];
		}
		
		currentIndex = [selectedItems indexGreaterThanIndex: currentIndex];
	}
	
	[LIB startUpdate];
}

- (IBAction)newFeed:(id)sender{
#pragma unused(sender)
    [feedURLTextField setStringValue:@"http://"];
    [NSApp beginSheet: newFeedPanel modalForWindow: [self window] modalDelegate: nil didEndSelector: nil contextInfo: nil];
    [NSApp runModalForWindow: newFeedPanel];
    [NSApp endSheet: newFeedPanel];
    [newFeedPanel orderOut: self];   
}

-(IBAction)confirmNewFeed:(id)sender{
#pragma unused(sender)
    KNFeed *              feed;
    int                 newIndex;
    
    newIndex = [LIB childCountOfItem: nil];
    if(! [[feedURLTextField stringValue] isEqualToString: @""] ){
		NSMutableString *			cleanSource = [NSMutableString stringWithString: [feedURLTextField stringValue]];

		[cleanSource replaceOccurrencesOfString:@"feed:" withString:@"http:" options:NSCaseInsensitiveSearch range:NSMakeRange(0,5)];
        feed = [[KNFeed alloc] init];
		
		KNDebug(@"CONT: created Feed: %@", feed);
		[feed setSourceURL: cleanSource];
		[feed setName: cleanSource];
        [LIB newFeed: feed inItem: nil atIndex:newIndex];
		KNDebug(@"CONT: added feed to lib %@", LIB);
		[feed release];
        [self reloadData];
		
		[LIB refreshFeed: feed];
        [LIB startUpdate];
    
        [NSApp stopModal];
    }else{
        NSBeep();
    }
}

-(IBAction)removeArticle:(id)sender{
#pragma unused(sender)
	if( [PREFS warnWhenDeletingArticles] ){
		NSBeginCriticalAlertSheet(
			@"Delete Article(s)",
			@"Delete",
			@"Cancel",
			nil,
			[self window],
			self,
			@selector(confirmRemoveArticle:returnCode:contextInfo:),
			nil,
			nil,
			@"Are you sure you want to delete the selected Article(s)?",
			nil
		);
	}else{
		[self confirmRemoveArticle: nil returnCode: NSAlertDefaultReturn contextInfo: nil];
	}
}

-(void)confirmRemoveArticle:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)info{
#pragma unused(sheet,info)
	NSIndexSet *				selectedArticles;
	int							currentIndex = -1;
	
	if( returnCode == NSAlertDefaultReturn ){
		selectedArticles = [articleTableView selectedRowIndexes];
		currentIndex = [selectedArticles firstIndex];
		while( currentIndex != NSNotFound ){
			[LIB removeItem: [articleCache objectAtIndex: currentIndex]];
			currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
		}
		
		[articleTableView deselectAll: self];
		[self refreshArticleCache];
		[self reloadData];
	}
}

-(IBAction)removeFeedItem:(id)sender{
#pragma unused(sender)
    NSBeginCriticalAlertSheet(
        @"Delete Item(s)",
        @"Delete",
        @"Cancel",
        nil,
        [self window],
        self,
        @selector(confirmRemoveFeedItem:returnCode:contextInfo:),
        nil,
        nil,
        @"Are you sure you want to delete the selected Item(s)?",
        nil
    );
}

-(void)confirmRemoveFeedItem:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)info{
#pragma unused(sheet,info)
    NSIndexSet *                selectedFeeds;
    int                         currentIndex = NSNotFound;
    
    if( returnCode == NSAlertDefaultReturn ){
        KNDebug(@"CONT: removeFeedItem");
		[inspector setItem: nil];
		[self setDisplayedArticle: nil];
			
        selectedFeeds = [feedOutlineView selectedRowIndexes];
        currentIndex = [selectedFeeds firstIndex];
        while( currentIndex != NSNotFound ){
			KNDebug(@"CONT: will remove item %@ at %u", [feedOutlineView itemAtRow: currentIndex], currentIndex);
            [LIB removeItem: [feedOutlineView itemAtRow: currentIndex]];
			KNDebug(@"CONT: removedItem at %u", currentIndex);
            currentIndex = [selectedFeeds indexGreaterThanIndex: currentIndex];
        }
		[feedOutlineView deselectAll: self];
		[self reloadData];
    }
}

-(IBAction)newFolder:(id)sender{
#pragma unused(sender)
	id					folderItem = nil;
	
    folderItem = [LIB newFolderNamed:@"Untitled Folder" inItem:nil atIndex:0];
	[self reloadData];
	
	[feedOutlineView selectRow:0 byExtendingSelection: NO];
	[feedOutlineView editColumn:[feedOutlineView columnWithIdentifier: @"feedName"] row:0 withEvent:nil select:YES];
}

-(IBAction)openArticlesExternal:(id)sender{
#pragma unused(sender)
	NSIndexSet *				selectedArticles = [articleTableView selectedRowIndexes];
	int							currentIndex;
	NSMutableArray *			articleLinks = [NSMutableArray array];
	NSString *					articleLink;
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	
	if( [selectedArticles count] == 0 ){ return; }
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		articleLink = [[articleCache objectAtIndex: currentIndex] link];
		if( ! [articleLink isEqualToString: @""] ){
			[articleLinks addObject: [NSURL URLWithString: articleLink]];
		}
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	
	if( [articleLinks count] > 0 ){
		[[NSWorkspace sharedWorkspace] openURLs: articleLinks
			withAppBundleIdentifier: NULL options: options
			additionalEventParamDescriptor: NULL launchIdentifiers:NULL
		];
	}
}

-(IBAction)articleDoubleClicked:(id)sender{
    
	if( [articleTableView clickedRow] == -1 ){
		KNDebug(@"CONT: doubleClick not in row");
		return;
	}
	
    [self openArticlesExternal: sender];
}

-(IBAction)openFeedsExternal:(id)sender{
#pragma unused(sender)
	NSIndexSet *					selectedItems = [feedOutlineView selectedRowIndexes];
	unsigned						currentIndex = [selectedItems firstIndex];
	NSMutableSet *					feedSet = [NSMutableSet set];
	
	while( currentIndex != NSNotFound ){
		NSEnumerator *			enumerator = [[[feedOutlineView itemAtRow: currentIndex] itemsOfType: FeedItemTypeFeed] objectEnumerator];
		KNFeed *				feed;
		while( (feed = [enumerator nextObject]) ){
			if( ! [[feed link] isEqualToString: @""] ){
				[feedSet addObject: [NSURL URLWithString: [feed link]]];
			}
		}
	}
	
	NSWorkspaceLaunchOptions		options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	if( [feedSet count] > 0 ){
		[[NSWorkspace sharedWorkspace] openURLs: [feedSet allObjects]
			withAppBundleIdentifier: NULL options: options
			additionalEventParamDescriptor: NULL launchIdentifiers:NULL
		];
	}
}

-(IBAction)feedDoubleClicked:(id)sender{
	if( [feedOutlineView clickedRow] == -1 ){
		return;
	}
	
	[self getInfo: sender];
}

-(IBAction)columnHeaderClicked:(id)sender{
#pragma unused(sender)
    KNDebug(@"header clicked!");
}

-(NSString *)selectedArticleStatus{
	NSIndexSet *			selectedArticles = [articleTableView selectedRowIndexes];
	int						currentIndex;
	
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		if( ! [[(KNArticle *)[articleCache objectAtIndex: currentIndex] status] isEqualToString: StatusRead] ){
			return( StatusUnread );
		}
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	return StatusRead;
}

-(IBAction)toggleArticleStatus:(id)sender{
#pragma unused(sender)
	NSString *				currentStatus = [self selectedArticleStatus];
	NSString *				newStatus;
	NSIndexSet *			selectedArticles = [articleTableView selectedRowIndexes];
	int						currentIndex;
	
	if( [currentStatus isEqualToString: StatusRead] ){
		newStatus = StatusUnread;
	}else{
		newStatus = StatusRead;
	}
	
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		[[articleCache objectAtIndex: currentIndex] setStatus: newStatus];
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	
	[self reloadData];
}

-(NSString *)activeArticleStatus{
	NSEnumerator *				enumerator = [[self selectedFeeds] objectEnumerator];
	KNFeed *					feed;
	
	while((feed = [enumerator nextObject])){
		if( [feed unreadCount] > 0 ){
			return StatusUnread;
		}
	}
	return StatusRead;
}

-(IBAction)markAllRead:(id)sender{
#pragma unused(sender)
	NSEnumerator *			enumerator = nil;
	KNArticle *				article = nil;
	KNFeed *					feed = nil;
	
	if( [[self activeArticleStatus] isEqualToString: StatusUnread] ){
		enumerator = [[self selectedFeeds] objectEnumerator];
		while((feed = [enumerator nextObject])){
			while((article = [feed oldestUnread])){
				[article setStatus: StatusRead];
			}
		}
	}
	[self reloadData];
}

-(IBAction)resetArticleKillList:(id)sender{
#pragma unused(sender)
	[LIB resetArticleKillList];
}

-(IBAction)bookmarkArticle:(id)sender{
#pragma unused(sender)
	NSIndexSet *			selectedArticles = [articleTableView selectedRowIndexes];
	int						currentIndex;
	
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		[LIB newArticle: [articleCache objectAtIndex: currentIndex] inItem: nil atIndex: [[LIB rootItem] childCount]];
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	[feedOutlineView reloadData];
}

-(IBAction)nextUnread:(id)sender{
#pragma unused(sender)
	int					currentIndex = 0;
	int					articleCount = [articleCache count];
	int					i;
	KNArticle *			article;
	int					nextIndex = -1;
	
	KNDebug(@"CONT: nextUnread");
	currentIndex = [[articleTableView selectedRowIndexes] lastIndex];
	if( currentIndex == NSNotFound ){
		currentIndex = 0;
	}
	
	for(i=currentIndex+1;i<articleCount;i++){
		article = [articleCache objectAtIndex: i];
		if(! [[article status] isEqualToString: StatusRead] ){
			nextIndex = i;
			KNDebug(@"CONT: found an unread at index %d", nextIndex);
			break;
		}
	}
	
	if( nextIndex > -1 ){
		[articleTableView selectRow: nextIndex byExtendingSelection: NO];
		[articleTableView scrollRowToVisible: nextIndex];
	}
	
}

-(IBAction)validateSource:(id)sender{
#pragma unused(sender)
	NSEnumerator *				enumerator = [[self selectedFeeds] objectEnumerator];
	KNFeed *					feed;
	id							feedItem;
	NSMutableArray *			feedLinks = [NSMutableArray array];
	NSMutableString *			feedLink;
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	
	while((feedItem = [enumerator nextObject])){
		if( [LIB isFeedItem: feedItem] ){
			feed = [LIB feedForItem: feedItem];
			feedLink = [NSMutableString stringWithString: [feed sourceURL]];
			if( ! [feedLink isEqualToString: @""] ){
				[feedLink replaceOccurrencesOfString:@"&" withString:@"%26" options: NSLiteralSearch range: NSMakeRange(0,[feedLink length])];
				[feedLink replaceOccurrencesOfString:@"?" withString:@"%3F" options: NSLiteralSearch range: NSMakeRange(0,[feedLink length])];
				[feedLink replaceOccurrencesOfString:@" " withString:@"%20" options: NSLiteralSearch range: NSMakeRange(0,[feedLink length])];
				[feedLink replaceOccurrencesOfString:@"+" withString:@"%20" options: NSLiteralSearch range: NSMakeRange(0,[feedLink length])];
				[feedLink replaceOccurrencesOfString:@"=" withString:@"%3D" options: NSLiteralSearch range: NSMakeRange(0,[feedLink length])];
				[feedLink insertString: SOURCE_VALIDATION_URL atIndex: 0];
				NSURL *			validationURL = [NSURL URLWithString: feedLink];
				
				if( validationURL != nil ){
					[feedLinks addObject: validationURL];
					KNDebug(@"CONT: adding validation link: %@", validationURL);
				}else{
					KNDebug(@"CONT: unable to create validation URL %@", validationURL);
				}
			}
		}
	}
	if( [feedLinks count] > 0 ){
		KNDebug(@"CONT: launching external %@", feedLinks);
		[[NSWorkspace sharedWorkspace] openURLs: feedLinks
			withAppBundleIdentifier: NULL options: options
			additionalEventParamDescriptor: NULL launchIdentifiers:NULL
		];
	}
	KNDebug(@"CONT: did launch");
}

-(IBAction)copySourceURL:(id)sender{
#pragma unused(sender)
	NSEnumerator *				enumerator = [[self selectedFeeds] objectEnumerator];
	KNFeed *					feed;
	id							feedItem;
	NSMutableArray *			feedLinks = [NSMutableArray array];
	
	while((feedItem = [enumerator nextObject])){
		if( [LIB isFeedItem: feedItem] ){
			feed = [LIB feedForItem: feedItem];
			[feedLinks addObject: [feed sourceURL]];
		}
	}
	
	if( [feedLinks count] > 0 ){
		NSPasteboard *			pboard = [NSPasteboard generalPasteboard];
		[pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
		[pboard setString: [feedLinks componentsJoinedByString:@"\n"] forType: NSStringPboardType];
	}
}


-(IBAction)getInfo:(id)sender{
#pragma unused(sender)
	id					item = nil;
	
	if( [[feedOutlineView selectedRowIndexes] count] == 1 ){
		item = [feedOutlineView itemAtRow: [[feedOutlineView selectedRowIndexes] firstIndex]];
	}
	[inspector setItem: item];
	[[inspector window] makeKeyAndOrderFront: self];
}

#pragma mark -
#pragma mark Contextual Menu Support

-(NSMenu *)menuForFeedRow:(int)row{
#pragma unused(row)
	return feedContextMenu;
}

-(NSMenu *)menuForArticleRow:(int)row{
#pragma unused(row)
	return articleContextMenu;
}



@end
