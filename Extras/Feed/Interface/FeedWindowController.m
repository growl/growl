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

#import "FeedDelegate.h"
#import "Library.h"
#import "Library+Update.h"
#import "Library+Items.h"
#import "Library+Active.h"
#import "Library+Utility.h"

#import "KNFeed.h"
#import "KNArticle.h"
#import "Prefs.h"
#import "LibraryToolbar.h"
#import "ImageTextCell.h"
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
        disableResizeNotifications = YES;
		inspector = [[InspectorController alloc] init];
        feedLibraryToolbar = [[LibraryToolbar alloc] initWithWindow: [self window]];
		//articleFont = [NSFont fontWithName:[PREFS articleFontName] size:[PREFS articleFontSize]];
		//articleListFont = [NSFont fontWithName: [PREFS articleListFontName] size: [PREFS articleListFontSize]];
		currentUpdatingFeedTitle = [[NSString string] retain];
    }
    return self;
}

-(void)dealloc{
    [viewColumns release];
	[inspector release];
    [feedLibraryToolbar release];
	[currentUpdatingFeedTitle release];
	
    [super dealloc];
}


-(void)awakeFromNib{
    //[anItem name] = [[NSApp delegate] [anItem name]];
    
    //KNDebug(@"awakeFromNib");
    
	[feedOutlineView setAutosaveExpandedItems: YES];
    
	[removeFeedButton setToolTip:@"Remove selected Feed(s) from the library"];
	[addFeedButton setToolTip:@"Add a new feed to the library"];
	
	//[self setDisplayedArticle: nil];
	[displayWebView setMaintainsBackForwardList:NO];
	[displayWebView setPolicyDelegate: self];
    
    // Set up our View->Columns menu
    NSEnumerator *              enumerator = [viewColumns objectEnumerator];
    NSMutableDictionary *       columnRecord;
    NSDictionary *              savedColumnRecord;
    NSTableColumn *             column;
    NSMenuItem *                columnsMenuItem = [[[[NSApp mainMenu] itemWithTitle:@"View"] submenu] itemWithTitle:@"Columns"];
    NSMenuItem *                newMenuItem;
    NSArray *                   visibleColumns = [PREFS visibleArticleColumns];
    NSImageCell *               imageCell;
    
    while((columnRecord = [enumerator nextObject])){
        column = [[NSTableColumn alloc] initWithIdentifier: [columnRecord objectForKey:ColumnIdentifier]];
        [columnRecord setObject: column forKey:ColumnHeaderObject];
		[column release];
        [columnRecord setObject: ColumnStateOff forKey: ColumnState];
        
        [column setTableView: articleTableView];
        [column setEditable: NO];
        [column setResizable: YES];
        [column setWidth: [[columnRecord objectForKey:ColumnWidth] floatValue]];
		[column setSortDescriptorPrototype: [[[NSSortDescriptor alloc] initWithKey: [columnRecord objectForKey:ColumnIdentifier] ascending:YES] autorelease]];
        
        [[column headerCell] setTitle: [columnRecord objectForKey:ColumnName]];
        
        if( [[columnRecord objectForKey: ColumnIdentifier] isEqualToString: ArticleStatus] ){
            [column setResizable:NO];
            imageCell = [[NSImageCell alloc] init];
            [column setDataCell: imageCell];
            [imageCell release];
            [[column headerCell] setImage: [NSImage imageNamed: ColumnStatusImageName]];
        }
		//[[column dataCell] setFont: articleListFont];
		
		if( [[column dataCell] respondsToSelector: @selector(setDrawsBackground:)] ){
			[[column dataCell] setDrawsBackground: NO];
		}
        
        if( [[columnRecord objectForKey: ColumnCanDisable] boolValue] ){
            newMenuItem = [[NSMenuItem alloc] initWithTitle: [columnRecord objectForKey:ColumnName] 
                                action:@selector(columnVisibilityDidChange:) 
                                keyEquivalent:@""
                            ];
            [newMenuItem setTag: [viewColumns indexOfObject: columnRecord]];
            [[columnsMenuItem submenu] addItem: newMenuItem];
            [columnRecord setObject: newMenuItem forKey: ColumnMenuItem];
			[newMenuItem release];
        }
    }
    
    enumerator = [[articleTableView tableColumns] objectEnumerator];
    while((column = [enumerator nextObject])){
        [articleTableView removeTableColumn: column];
    }
    
    //KNDebug(@"About to load saved columns");
    enumerator = [visibleColumns objectEnumerator];
    while((savedColumnRecord = [enumerator nextObject])){
        columnRecord = [viewColumns objectAtIndex: [[savedColumnRecord objectForKey:ColumnIndex] intValue]];
        [columnRecord setObject: ColumnStateVisible forKey: ColumnState];
        [columnRecord setObject: [savedColumnRecord objectForKey:ColumnWidth] forKey: ColumnWidth];
        [[columnRecord objectForKey: ColumnHeaderObject] setWidth: [[savedColumnRecord objectForKey: ColumnWidth] floatValue]];
        [articleTableView addTableColumn: [columnRecord objectForKey: ColumnHeaderObject]];
        if( [columnRecord objectForKey:ColumnCanDisable] ){
            [[columnRecord objectForKey:ColumnMenuItem] setState: NSOnState];
        }
        column = [columnRecord objectForKey: ColumnHeaderObject];
        
		if( [[column identifier] isEqualToString: [[[LIB sortDescriptors] objectAtIndex:0] key] ] ){
            [articleTableView setHighlightedTableColumn: column];
        }
    }
    [articleTableView sizeLastColumnToFit];
	[articleTableView setSortDescriptors: [LIB sortDescriptors]];

	folderImage = [[[NSWorkspace sharedWorkspace] iconForFile: @"/System/Library"] retain];
	[folderImage setScalesWhenResized:YES];
	[folderImage setSize: NSMakeSize(16,16)];
	
	tableWrapStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[tableWrapStyle setLineBreakMode: NSLineBreakByTruncatingTail];
	
	ImageTextCell *				dataCell = [[[ImageTextCell alloc] initTextCell:@""] autorelease];
	[dataCell setEditable: YES];
	[dataCell setWraps: YES];
	[[feedOutlineView tableColumnWithIdentifier: @"feedName"] setDataCell: dataCell];
	
    // Set our feed selection
    [feedOutlineView reloadData];

    NSMutableIndexSet *         selectedFeeds = [NSMutableIndexSet indexSet];
    id                          feedItem;
    enumerator = [[LIB activeItems] objectEnumerator];
    while((feedItem = [enumerator nextObject])){
        //KNDebug(@"getting row index (%d) for item %@", [feedOutlineView rowForItem: feedItem], feedItem);
        [selectedFeeds addIndex: [feedOutlineView rowForItem: feedItem]];
    }
    //KNDebug(@"found selectedFeeds: %@", selectedFeeds);
    [feedOutlineView selectRowIndexes:selectedFeeds byExtendingSelection: NO];
    [feedOutlineView sizeLastColumnToFit];
    
    // Set our article selection
	//[self articleListFontChanged: nil];
    //[articleTableView reloadData];
	//[articleTableView tile];
	
	KNArticle *					article = nil;
	
	enumerator = [[LIB activeArticles] objectEnumerator];
	while( (article = [enumerator nextObject]) ){
		[articleTableView selectRow: [LIB indexOfActiveArticle: article] byExtendingSelection: YES];
	}
    
    // Set our 'remove feed' button state
    if( [[LIB activeItems] count] > 0 ){
        [removeFeedButton setEnabled: YES];
    }else{
        [removeFeedButton setEnabled: NO];
    }
    
    // Register for notifications of updates
	[self registerForNotifications];
	
    [articleTableView setDoubleAction: @selector(articleDoubleClicked:) ];
	[feedOutlineView setDoubleAction: @selector(feedDoubleClicked:) ];
	
	[feedOutlineView registerForDraggedTypes: [NSArray arrayWithObjects:DragDropFeedItemPboardType,DragDropFeedArticlePboardType, NSStringPboardType, nil]];
    
    [feedDrawer setContentSize: NSMakeSize( [PREFS feedDrawerSize].width, [feedDrawer contentSize].height )];
	[feedOutlineView sizeLastColumnToFit];
    [self restoreSplitSize];
	
	[self updateStatus];
	
	[articleTableView setNextKeyView: displayWebView];
	if( ([feedDrawer state] == NSDrawerClosedState) || ([feedDrawer state] == NSDrawerClosingState) ){
		[displayWebView setNextKeyView: articleTableView];
	}else{
		[displayWebView setNextKeyView: feedOutlineView];
		[feedOutlineView setNextKeyView: articleTableView];
	}

}

-(void)registerForNotifications{
	[[NSNotificationCenter defaultCenter] addObserver: self 
        selector: @selector(feedUpdateFinished:) 
        name:FeedUpdateFinishedNotification object: nil
    ];
    [[NSNotificationCenter defaultCenter] addObserver: self 
        selector: @selector(feedUpdateStarted:) 
        name:FeedUpdateStartedNotification object: nil
    ];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(feedWillUpdate:)
		name:FeedUpdateWillUpdateFeedNotification object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(feedDidUpdate:)
		name:FeedUpdateDidUpdateFeedNotification object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(articleListFontChanged:)
		name:NotifyArticleListFontNameChanged object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(articleFontChanged:)
		name:NotifyArticleFontNameChanged object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(articleFontChanged:)
		name:NotifyArticleFontSizeChanged object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(torrentSchemeChanged:)
		name:NotifyArticleTorrentSchemeChanged object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(articleExpiredColorChanged:)
		name:NotifyArticleExpiredColorChanged object: nil
	];
}

-(void)windowDidLoad{
    
    //KNDebug(@"Controller: windowDidLoad");
    
    [self setShouldCascadeWindows: NO];
    if( ! [[self window] setFrameAutosaveName: @"feedMainWindow"] ){
        KNDebug(@"Unable to set autosave!");
    }
    [[self window] setFrameUsingName: @"feedMainWindow"];
    
    if( [PREFS feedDrawerState] ){
        [feedDrawer open];
        //[feedDrawerButton setTitle:@"Hide Feeds"];
    }else{
        [feedDrawer close];
        //[feedDrawerButton setTitle:@"Show Feeds"];
    }
    
    [self setWindowTitle];
    disableResizeNotifications = NO;
}

-(void)windowWillClose:(NSNotification *)notification{
#pragma unused(notification)
    //KNDebug(@"Controller: windowWillClose");
    //[[anItem name] save];
    //[NSApp terminate: self];
}

-(void)setWindowTitle{
    NSString *              title = @"Feed";
    int                     feedCount = [[LIB activeItems] count];
    int                     unreadCount = [LIB activeUnreadCount];
	
    //KNDebug(@"CONT: setWindowtitle. ActiveFeedItems count: %d", feedCount);
    if( feedCount == 1 ){
        title = [NSString stringWithFormat:@"%@ : %@", title, [LIB nameForItem: [[LIB activeItems] objectAtIndex:0]] ];
    }else if( feedCount > 1){
        title = [NSString stringWithFormat:@"%@ : %d Sources Selected", title, feedCount];
    }
    
    if( unreadCount > 0 ){
        title = [NSString stringWithFormat:@"%@ (%d Unread)", title, unreadCount];
    }
    
    [[self window] setTitle: title];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    if( [menuItem action] == @selector(removeFeedItem:) ){
		
		if( [[LIB activeItems] count] == 0 ){ return NO;}
		
		if( [[LIB activeItems] count] == 1 ){
			id				item = [[LIB activeItems] objectAtIndex:0];
			
			if( [LIB isFolderItem: item] ){
				[menuItem setTitle: @"Delete Folder"];
			}else if( [LIB isFeedItem: item] ){
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
		if( [[LIB activeItems] count] == 0 ){
			[menuItem setTitle: @"Update"];
			return NO;
		}else{
			if( [[LIB activeItems] count] == 1 ){
				if( [LIB isFolderItem: [[LIB activeItems] objectAtIndex:0]] ){
					[menuItem setTitle: @"Update Folder"];
				}else if( [LIB isFeedItem: [[LIB activeItems] objectAtIndex:0]] ){
					[menuItem setTitle: @"Update Feed"];
				}else if( [LIB isArticleItem: [[LIB activeItems] objectAtIndex:0]] ){
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
		if( [LIB activeUnreadCount] <= 0 ){
			return NO;
		}
	}else if( [menuItem action] == @selector(getInfo:) ){
		if( [[LIB activeItems] count] == 1 ){
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
			return( [[LIB activeItems] count] > 0 );
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
		return( [LIB activeUnreadCount] > 0 );
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
	NSMutableString *			status = [NSMutableString stringWithFormat:@"%d articles", [LIB activeArticleCount]];
	
	//KNDebug(@"updateStatus - %@", status);
	if( isUpdating ){
		[status appendFormat:@" - Updating %@", currentUpdatingFeedTitle];
	}
	[statusTextField setStringValue: status];
}

-(IBAction)reloadData{
	
	[feedOutlineView reloadData];
	[articleTableView reloadData];
	
	[self updateStatus];
	[self setWindowTitle];
	[[NSApp delegate] updateDockIcon];
	
	NSEnumerator *				enumerator = [[LIB activeArticles] objectEnumerator];
	KNArticle *					article = nil;
	
	[articleTableView deselectAll: self];
	while( (article = [enumerator nextObject]) ){
		[articleTableView selectRowIndexes: [[article parent] currentChildIndexes] byExtendingSelection: YES];
	}
	
	// Set our item in our inspector
	if( [[LIB activeItems] count] == 1 ){
		[inspector setItem: [[LIB activeItems] objectAtIndex:0]];
	}else{
		[inspector setItem: nil];
	}
}

-(void)setDisplayedArticle:(KNArticle *)anArticle{
	NSString *					previewCachePath = nil;
    NSURL *                     base = nil;
    
    KNDebug(@"CONT: setDisplayedArticle");
    
    if( anArticle ){
		[anArticle setStatus: StatusRead];
		previewCachePath = [anArticle previewCachePath];
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
		[self setDisplayedArticle: [LIB activeArticleAtIndex: [[articleTableView selectedRowIndexes] firstIndex]]];
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
	NSEnumerator *			enumerator;
	NSEnumerator *			folderEnumerator;
	id						feedItem;
	KNFeed *					feed;
	
	KNDebug(@"CONT: refreshItem");
	enumerator = [[LIB activeItems] objectEnumerator];
	while((feedItem = [enumerator nextObject])){
		if( [LIB isFeedItem: feedItem] ){
			[LIB refreshFeed: [LIB feedForItem:feedItem]];
		}else if( [LIB isFolderItem: feedItem] ){
			folderEnumerator = [[LIB feedsInFolder: feedItem] objectEnumerator];
			while((feed = [folderEnumerator nextObject])){
				[LIB refreshFeed: feed];
			}
		}
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
			[LIB removeItem: [LIB activeArticleAtIndex: currentIndex]];
			currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
		}
		
		[articleTableView deselectAll: self];
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
			
        selectedFeeds = [feedOutlineView selectedRowIndexes];
        currentIndex = [selectedFeeds firstIndex];
        while( currentIndex != NSNotFound ){
			KNDebug(@"CONT: will remove item %@ at %u", [feedOutlineView itemAtRow: currentIndex], currentIndex);
            [LIB removeItem: [feedOutlineView itemAtRow: currentIndex]];
			KNDebug(@"CONT: removedItem at %u", currentIndex);
            currentIndex = [selectedFeeds indexGreaterThanIndex: currentIndex];
        }
		[self reloadData];
		[feedOutlineView deselectAll: self];
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
		articleLink = [[LIB activeArticleAtIndex: currentIndex] link];
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
	NSEnumerator *				enumerator = [[LIB activeItems] objectEnumerator];
	KNFeed *						feed;
	KNArticle *					article;
	id							feedItem;
	NSMutableArray *			feedLinks = [NSMutableArray array];
	NSString *					feedLink;
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	
	while((feedItem = [enumerator nextObject])){
		if( [LIB isFeedItem: feedItem] ){
			feed = [LIB feedForItem: feedItem];
			feedLink = [feed link];
			if( ! [feedLink isEqualToString: @""] ){
				[feedLinks addObject: [NSURL URLWithString: feedLink]];
			}
		}else if( [LIB isArticleItem: feedItem] ){
			article = [LIB articleForItem: feedItem];
			feedLink = [article link];
			if( ! [feedLink isEqualToString: @""] ){
				[feedLinks addObject: [NSURL URLWithString: feedLink]];
			}
		}
	}
	if( [feedLinks count] > 0 ){
		[[NSWorkspace sharedWorkspace] openURLs: feedLinks
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
	
	//[self openFeedsExternal: sender];
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
		if( ! [[[LIB activeArticleAtIndex: currentIndex] status] isEqualToString: StatusRead] ){
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
		[[LIB activeArticleAtIndex: currentIndex] setStatus: newStatus];
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	
	[self reloadData];
}

-(NSString *)activeArticleStatus{
	NSEnumerator *			enumerator = [[LIB activeFeeds] objectEnumerator];
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
		enumerator = [[LIB activeFeeds] objectEnumerator];
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
		[LIB newArticle: [LIB activeArticleAtIndex: currentIndex] inItem: nil atIndex: [LIB childCountOfItem: nil]];
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	[feedOutlineView reloadData];
}

-(IBAction)nextUnread:(id)sender{
#pragma unused(sender)
	int					currentIndex = 0;
	int					articleCount = [LIB activeArticleCount];
	int					i;
	KNArticle *			article;
	int					nextIndex = -1;
	
	KNDebug(@"CONT: nextUnread");
	/*
	article = [LIB oldestUnreadActiveArticle];
	if( article ){
		[LIB setActiveArticle: article];
		[articleTableView selectRow: [LIB indexOfActiveArticle: article] byExtendingSelection: NO];
		[articleTableView scrollRowToVisible: [LIB indexOfActiveArticle: article]];
	}else{
		KNDebug(@"CONT: no oldestUnreadActiveArticle found in current sources");
	}
	*/
	
	currentIndex = [[articleTableView selectedRowIndexes] lastIndex];
	if( currentIndex == NSNotFound ){
		currentIndex = 0;
	}
	
	for(i=currentIndex+1;i<articleCount;i++){
		article = [LIB activeArticleAtIndex: i];
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
	NSEnumerator *				enumerator = [[LIB activeFeeds] objectEnumerator];
	KNFeed *						feed;
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
	NSEnumerator *				enumerator = [[LIB activeItems] objectEnumerator];
	KNFeed *						feed;
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
	
	if( [[LIB activeItems] count] == 1 ){
		item = [[LIB activeItems] objectAtIndex: 0];
	}
	[inspector setItem: item];
	[[inspector window] makeKeyAndOrderFront: self];
}

#pragma mark -
#pragma mark Drawer Support

-(void)drawerDidOpen:(NSNotification *)notification{
#pragma unused(notification)
    [PREFS setFeedDrawerState: YES];
	[articleTableView setNextKeyView: displayWebView];
	[displayWebView setNextKeyView: feedOutlineView];
	[feedOutlineView setNextKeyView: articleTableView];
}

-(void)drawerDidClose:(NSNotification *)notification{
#pragma unused(notification)
    [PREFS setFeedDrawerState: NO];
	[articleTableView setNextKeyView: displayWebView];
	[displayWebView setNextKeyView: articleTableView];
}

-(NSSize)drawerWillResizeContents:(NSDrawer *)drawer toSize:(NSSize)aSize{
#pragma unused(drawer)
    [feedOutlineView sizeLastColumnToFit];
    [PREFS setFeedDrawerSize: aSize];
    return aSize;
}

#pragma mark -
#pragma mark Split View support

-(void)restoreSplitSize{
    NSView *            articleClip = [[displaySplitView subviews] objectAtIndex:0];
    NSView *            displayClip = [[displaySplitView subviews] objectAtIndex:1];
    NSRect              articleFrame = [articleClip frame];
    NSRect              displayFrame = [displayClip frame];
    
    //KNDebug(@"CONT: Restoring split sizes");
    
    articleFrame.size.height = [PREFS articleListHeight];
    displayFrame.size.height = [PREFS displayHeight];
    [articleClip setFrame: articleFrame];
    [displayClip setFrame: displayFrame];
    [displaySplitView adjustSubviews];
}

-(void)splitViewDidResizeSubviews:(NSNotification *)notification{
#pragma unused(notification)
    NSRect              articleFrame = [[[displaySplitView subviews] objectAtIndex:0] frame];
    NSRect              displayFrame = [[[displaySplitView subviews] objectAtIndex:1] frame];
    
    //KNDebug(@"CONT: Saving split sizes");
    [PREFS setArticleListHeight: articleFrame.size.height+1];
    [PREFS setDisplayHeight: displayFrame.size.height-1];
    
    [articleTableView scrollRowToVisible: [LIB activeArticleCount]-1];
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

#pragma mark -
#pragma mark WebView Support
-(void)webView:(WebView *)sender 
			decidePolicyForNavigationAction:(NSDictionary *)actionInformation
			request:(NSURLRequest *)request 
			frame:(WebFrame *)frame 
			decisionListener:(id<WebPolicyDecisionListener>)listener
{
#pragma unused(sender,frame)
	//KNDebug(@"WEB: policyDecision for %@", request);
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	
	//KNDebug(@"WEB: policyDecision for %@ (%d)", actionInformation, WebNavigationTypeLinkClicked);
	if( [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue] == WebNavigationTypeLinkClicked ){
		//KNDebug(@"WEB: Will open URL %@ external", [request URL]);
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURLs: [NSArray arrayWithObject:[request URL]] withAppBundleIdentifier:NULL options: options additionalEventParamDescriptor: NULL launchIdentifiers:NULL];
	}else{
		//KNDebug(@"WEB: Will open URL %@ internal", [request URL]);
		[listener use];
	}
	
	return;
	
	if( isLoadingDisplay ){
		KNDebug(@"WEB: Will open URL %@ internal", [request URL]);
		[listener use];
		isLoadingDisplay = NO;
	}else{
		KNDebug(@"WEB: Will open URL %@ external", [request URL]);
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURL: [request URL]];
	}
	return;
}

@end
