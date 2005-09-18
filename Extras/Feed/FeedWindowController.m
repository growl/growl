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
#import "FeedLibrary.h"
#import "Feed.h"
#import "Article.h"
#import "Prefs.h"
#import "LibraryToolbar.h"
#import "ImageTextCell.h"
#import <WebKit/WebKit.h>
#import "NSString+KNTruncate.h"
#import "NSDate+KNExtras.h"
#import "InspectorController.h"

#define FeedLibraryNibName @"FeedLibrary"
#define ColumnStatusImageName @"Status"
#define ColumnOnServerImageName @"Status"
#define ArticleOnServerImage @"Updated"
#define BookmarkImage @"Bookmark"
#define FeedErrorImage @"FeedError"

#define TOGGLE_FEED_DRAWER_MENU 1024
#define DragDropFeedItemPboardType @"FeedItemPboardType"
#define DragDropFeedArticlePboardType @"FeedArticlePboardType"

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
								[NSString stringWithString:ArticleOnServer], ColumnIdentifier,
								[NSNumber numberWithBool: YES], ColumnCanDisable,
								[NSNumber numberWithInt: 20], ColumnWidth,
							nil],
							[NSMutableDictionary dictionaryWithObjectsAndKeys:
								[NSString stringWithString:@"Source"], ColumnName,
								[NSString stringWithString:ArticleSource], ColumnIdentifier,
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
    feedLibrary = [[NSApp delegate] feedLibrary];
    
    //KNDebug(@"awakeFromNib");
    
	[feedOutlineView setAutosaveExpandedItems: YES];
    
	[removeFeedButton setToolTip:@"Remove selected Feed(s) from the library"];
	[addFeedButton setToolTip:@"Add a new feed to the library"];
	
	[self setDisplayedArticle: nil];
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
    
    while( columnRecord = [enumerator nextObject] ){
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
		}else if( [[columnRecord objectForKey: ColumnIdentifier] isEqualToString: ArticleOnServer] ){
			[column setResizable:NO];
			imageCell = [[NSImageCell alloc] init];
			[column setDataCell: imageCell];
			[imageCell release];
			[[column headerCell] setImage: [NSImage imageNamed: ColumnOnServerImageName]];
        //}else if( [[columnRecord objectForKey: ColumnIdentifier] isEqualToString: ArticleDate] ){
        //    [[column dataCell] setFormatter: [[[NSDateFormatter alloc] initWithDateFormat:@"%m/%d/%y" allowNaturalLanguage:NO] autorelease]];
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
    while( column = [enumerator nextObject] ){
        [articleTableView removeTableColumn: column];
    }
    
    //KNDebug(@"About to load saved columns");
    enumerator = [visibleColumns objectEnumerator];
    while( savedColumnRecord = [enumerator nextObject] ){
        columnRecord = [viewColumns objectAtIndex: [[savedColumnRecord objectForKey:ColumnIndex] intValue]];
        [columnRecord setObject: ColumnStateVisible forKey: ColumnState];
        [columnRecord setObject: [savedColumnRecord objectForKey:ColumnWidth] forKey: ColumnWidth];
        [[columnRecord objectForKey: ColumnHeaderObject] setWidth: [[savedColumnRecord objectForKey: ColumnWidth] floatValue]];
        [articleTableView addTableColumn: [columnRecord objectForKey: ColumnHeaderObject]];
        if( [columnRecord objectForKey:ColumnCanDisable] ){
            [[columnRecord objectForKey:ColumnMenuItem] setState: NSOnState];
        }
        column = [columnRecord objectForKey: ColumnHeaderObject];
        
		if( [[column identifier] isEqualToString: [[[feedLibrary sortDescriptors] objectAtIndex:0] key] ] ){
            [articleTableView setHighlightedTableColumn: column];
        }
    }
    [articleTableView sizeLastColumnToFit];
	[articleTableView setSortDescriptors: [feedLibrary sortDescriptors]];

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
    enumerator = [[feedLibrary activeFeedItems] objectEnumerator];
    while( feedItem = [enumerator nextObject] ){
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
    [articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection: NO];
    
    // Set our 'remove feed' button state
    if( [[feedLibrary activeFeedItems] count] > 0 ){
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
    KNDebug(@"Controller: windowWillClose");
    [feedLibrary save];
    //[NSApp terminate: self];
}

-(void)setWindowTitle{
    NSString *              title = @"Feed";
    int                     feedCount = [[feedLibrary activeFeedItems] count];
    int                     unreadCount = [feedLibrary activeUnreadCount];
	
    //KNDebug(@"CONT: setWindowtitle. ActiveFeedItems count: %d", feedCount);
    if( feedCount == 1 ){
        title = [NSString stringWithFormat:@"%@ : %@", title, [feedLibrary nameForItem: [[feedLibrary activeFeedItems] objectAtIndex:0]] ];
    }else if( feedCount > 1){
        title = [NSString stringWithFormat:@"%@ : %d Sources Selected", title, feedCount];
    }
    
    if( unreadCount > 0 ){
        title = [NSString stringWithFormat:@"%@ (%d Unread)", title, unreadCount];
    }
    
    [[self window] setTitle: title];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	//KNDebug(@"CONT: validateMenuItem %@", menuItem);
    if( [menuItem action] == @selector(removeFeedItem:) ){
		if( [[feedLibrary activeFeedItems] count] == 0 ){ return NO; }
		if( [[feedLibrary activeFeedItems] count] == 1 ){
			id				item = [[feedLibrary activeFeedItems] objectAtIndex:0];
			
			if( [feedLibrary isFolderItem: item] ){
				[menuItem setTitle: @"Delete Folder"];
			}else if( [feedLibrary isFeedItem: item] ){
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
	
	}else if( [menuItem action] == @selector(removeFeedItem:) ){
		[menuItem setTitle: @"Delete Feed"];
		if( ( [[self window] firstResponder] != feedOutlineView ) || ( [[feedLibrary activeFeedItems] count] == 0 ) ){
			return NO;
		}
		
		if( [[feedLibrary activeFeedItems] count] == 1 ){
			if( [feedLibrary isFolderItem: [[feedLibrary activeFeedItems] objectAtIndex:0]] ){
				[menuItem setTitle: @"Delete Folder"];
			}
		}else{
			[menuItem setTitle: @"Delete Selected"];
		}

	}else if( [menuItem action] == @selector(refreshItem:) ){
		if( [[feedLibrary activeFeedItems] count] == 0 ){
			[menuItem setTitle: @"Update"];
			return NO;
		}else{
			if( [[feedLibrary activeFeedItems] count] == 1 ){
				if( [feedLibrary isFolderItem: [[feedLibrary activeFeedItems] objectAtIndex:0]] ){
					[menuItem setTitle: @"Update Folder"];
				}else if( [feedLibrary isFeedItem: [[feedLibrary activeFeedItems] objectAtIndex:0]] ){
					[menuItem setTitle: @"Update Feed"];
				}else if( [feedLibrary isArticleItem: [[feedLibrary activeFeedItems] objectAtIndex:0]] ){
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
		if( [feedLibrary activeUnreadCount] <= 0 ){
			return NO;
		}
	}else if( [menuItem action] == @selector(getInfo:) ){
		if( [[feedLibrary activeFeedItems] count] == 1 ){
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
			return( [[feedLibrary activeFeedItems] count] > 0 );
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
		return( [feedLibrary activeUnreadCount] > 0 );
	}
    
    return YES;
}

-(void)feedUpdateStarted:(NSNotification *)notification{
	KNDebug(@"CONT: feedUpdateStarted");
    //[refreshAllButton setEnabled: NO];
    isUpdating = YES;
	[statusProgressIndicator startAnimation:self];
	[currentUpdatingFeedTitle autorelease];
	currentUpdatingFeedTitle = [[NSString string] retain];
}

-(void)feedWillUpdate:(NSNotification *)notification{
	NSString *					feedURL = [notification object];
	//KNDebug(@"CONT: Got a feed update notification for %@", feedURL);
	[currentUpdatingFeedTitle autorelease];
	currentUpdatingFeedTitle = [[[feedLibrary feedForSource: feedURL] title] retain];
	[self updateStatus];
}

-(void)feedDidUpdate:(NSNotification *)notification{
	[self reloadData];
}

-(void)feedUpdateFinished:(NSNotification *)notification{
	KNDebug(@"CONT: feedUpdateFinished");
	
	isUpdating = NO;
	[statusProgressIndicator stopAnimation:self];
    [feedLibrary refreshActiveArticles];
	[self reloadData];
	
    //[articleTableView scrollRowToVisible: [feedLibrary activeArticleCount]-1];
	//[self setDisplayedArticle: [feedLibrary activeArticle]];
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
    NSEnumerator *              enumerator = [[articleTableView tableColumns] objectEnumerator];
    NSTableColumn *             column;
    NSMutableArray *            columnArray = [NSMutableArray array];
    NSDictionary *              columnData;
    int                         i,index;
    
    while( column = [enumerator nextObject] ){
        //KNDebug(@"remembering column %@", [column identifier]);
        index = -1;
        for(i=0;i<[viewColumns count];i++){
            if( [[[viewColumns objectAtIndex:i] objectForKey:ColumnIdentifier] isEqualToString: [column identifier]] ){
                index = i;
                break;
            }
        }
        if( index > -1 ){
            columnData = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInt: index], ColumnIndex,
                    [NSNumber numberWithFloat: [column width]], ColumnWidth,
            nil];
            [columnArray addObject: columnData];
        }
    }
    [PREFS setVisibleArticleColumns: columnArray];
}

-(void)setDisplayedArticle:(Article *)anArticle{
	NSString *					previewCachePath = nil;
    NSURL *                     base = nil;
    
    KNDebug(@"CONT: setDisplayedArticle");
    
    if( anArticle ){
		[anArticle setStatus: StatusRead];
		previewCachePath = [anArticle previewCachePath];
        base = [NSURL URLWithString: [anArticle link]];
		[self reloadData];
    }
    
	//KNDebug(@"CONT: generated HTML for display: %@", displayedHTML);
    //KNDebug(@"baseURL: %@", base);
	isLoadingDisplay = YES;
	if( previewCachePath ){
		[[displayWebView mainFrame] loadRequest: [NSURLRequest requestWithURL: [NSURL fileURLWithPath: previewCachePath]]];
	}else{
		[[displayWebView mainFrame] loadHTMLString: @"" baseURL: base ];
	}
}

-(void)updateStatus{
	NSMutableString *			status = [NSMutableString stringWithFormat:@"%d articles", [feedLibrary activeArticleCount]];
	
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
	if( ! isUpdating ){ [[NSApp delegate] updateDockIcon]; }
	[articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection: NO];
}

#pragma mark-
#pragma mark Preference Notifications

-(void)articleListFontChanged:(NSNotification *)notification{
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
	//articleFont = [NSFont fontWithName: [PREFS articleFontName] size: [PREFS articleFontSize]];
	[self setDisplayedArticle: [feedLibrary activeArticle]];
}

-(void)articleExpiredColorChanged:(NSNotification *)notification{
	[articleTableView reloadData];
}

-(void)torrentSchemeChanged:(NSNotification *)notification{
	[self setDisplayedArticle: [feedLibrary activeArticle]];
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
	if( isUpdating ){
		[feedLibrary cancelUpdate];
	}else{
		[feedLibrary refreshAll];
	}
}

-(IBAction)refreshItem:(id)sender{
	NSEnumerator *			enumerator;
	NSEnumerator *			folderEnumerator;
	id						feedItem;
	Feed *					feed;
	
	KNDebug(@"CONT: refreshItem");
	enumerator = [[feedLibrary activeFeedItems] objectEnumerator];
	while( feedItem = [enumerator nextObject] ){
		if( [feedLibrary isFeedItem: feedItem] ){
			[feedLibrary refreshFeed: [feedLibrary feedForItem:feedItem]];
		}else if( [feedLibrary isArticleItem: feedItem] ){
			[feedLibrary refreshFeed: [[feedLibrary articleForItem: feedItem] feed]];
		}else if( [feedLibrary isFolderItem: feedItem] ){
			folderEnumerator = [[feedLibrary feedsInFolder: feedItem] objectEnumerator];
			while( feed = [folderEnumerator nextObject] ){
				[feedLibrary refreshFeed: feed];
			}
		}
	}
	[feedLibrary startUpdate];
}

- (IBAction)newFeed:(id)sender{
    [feedURLTextField setStringValue:@"http://"];
    [NSApp beginSheet: newFeedPanel modalForWindow: [self window] modalDelegate: nil didEndSelector: nil contextInfo: nil];
    [NSApp runModalForWindow: newFeedPanel];
    [NSApp endSheet: newFeedPanel];
    [newFeedPanel orderOut: self];   
}

-(IBAction)confirmNewFeed:(id)sender{
    Feed *              feed;
    int                 newIndex;
    
    newIndex = [feedLibrary childCountOfItem: nil];
    if(! [[feedURLTextField stringValue] isEqualToString: @""] ){
		NSMutableString *			cleanSource = [NSMutableString stringWithString: [feedURLTextField stringValue]];

		[cleanSource replaceOccurrencesOfString:@"feed:" withString:@"http:" options:NSCaseInsensitiveSearch range:NSMakeRange(0,5)];
        feed = [[Feed alloc] initWithSource: cleanSource ];
		KNDebug(@"CONT: created Feed: %@", feed);
        [feedLibrary newFeed: feed inItem: nil atIndex:newIndex];
		[feed release];
        //[feedOutlineView reloadData];
		[feedLibrary refreshFeed: feed];
        [feedLibrary startUpdate];
    
        [NSApp stopModal];
    }else{
        NSBeep();
    }
}

-(IBAction)removeArticle:(id)sender{
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
	NSIndexSet *				selectedArticles;
	int							currentIndex = -1;
	
	if( returnCode == NSAlertDefaultReturn ){
		selectedArticles = [articleTableView selectedRowIndexes];
		currentIndex = [selectedArticles firstIndex];
		while( currentIndex != NSNotFound ){
			[feedLibrary removeArticle: [feedLibrary activeArticleAtIndex: currentIndex]];
			//KNDebug(@"CONT: Will remove article %@", [[feedLibrary activeArticleAtIndex: currentIndex] title]);
			currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
		}
		[feedLibrary refreshActiveArticles];
		
		[feedLibrary save];
		[articleTableView deselectAll: self];
		[self reloadData];
	}
}

-(IBAction)removeFeedItem:(id)sender{
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
//-(IBAction)confirmRemoveFeedItem:(id)sender{
    NSIndexSet *                selectedFeeds;
    int                         currentIndex = -1;
    
    if( returnCode == NSAlertDefaultReturn ){
        //KNDebug(@"CONT: removeFeedItem");
        selectedFeeds = [feedOutlineView selectedRowIndexes];
        currentIndex = [selectedFeeds firstIndex];
        while( currentIndex != NSNotFound ){
            [feedLibrary removeItem: [feedOutlineView itemAtRow: currentIndex]];
            currentIndex = [selectedFeeds indexGreaterThanIndex: currentIndex];
        }
        [feedLibrary save];
		[feedOutlineView deselectAll: self];
		[self reloadData];
    }
}

-(IBAction)newFolder:(id)sender{
	id					folderItem = nil;
	
    folderItem = [feedLibrary newFolderNamed:@"Untitled Folder" inItem:nil atIndex:0];
    [feedLibrary makeDirty];
	[feedOutlineView selectRow:0 byExtendingSelection: NO];
	
	
	[feedLibrary setActiveFeedItems: [NSArray arrayWithObject: folderItem]];
	
	[self setDisplayedArticle: [feedLibrary activeArticle]];
    [feedOutlineView reloadData];
	[articleTableView reloadData];
	
	[feedOutlineView editColumn:[feedOutlineView columnWithIdentifier: @"feedName"] row:0 withEvent:nil select:YES];
}

-(IBAction)openArticlesExternal:(id)sender{
	NSIndexSet *				selectedArticles = [articleTableView selectedRowIndexes];
	int							currentIndex;
	NSMutableArray *			articleLinks = [NSMutableArray array];
	NSString *					articleLink;
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	
	if( [selectedArticles count] == 0 ){ return; }
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		articleLink = [[feedLibrary activeArticleAtIndex: currentIndex] link];
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
	NSEnumerator *				enumerator = [[feedLibrary activeFeedItems] objectEnumerator];
	Feed *						feed;
	Article *					article;
	id							feedItem;
	NSMutableArray *			feedLinks = [NSMutableArray array];
	NSString *					feedLink;
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	
	while( feedItem = [enumerator nextObject] ){
		if( [feedLibrary isFeedItem: feedItem] ){
			feed = [feedLibrary feedForItem: feedItem];
			feedLink = [feed link];
			if( ! [feedLink isEqualToString: @""] ){
				[feedLinks addObject: [NSURL URLWithString: feedLink]];
			}
		}else if( [feedLibrary isArticleItem: feedItem] ){
			article = [feedLibrary articleForItem: feedItem];
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
    KNDebug(@"header clicked!");
}

-(NSString *)selectedArticleStatus{
	NSIndexSet *			selectedArticles = [articleTableView selectedRowIndexes];
	int						currentIndex;
	
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		if( ! [[[feedLibrary activeArticleAtIndex: currentIndex] status] isEqualToString: StatusRead] ){
			return( StatusUnread );
		}
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	return StatusRead;
}

-(IBAction)toggleArticleStatus:(id)sender{
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
		[[feedLibrary activeArticleAtIndex: currentIndex] setStatus: newStatus];
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	
	[self reloadData];
}

-(NSString *)activeArticleStatus{
	NSEnumerator *			enumerator = [[feedLibrary activeFeeds] objectEnumerator];
	Feed *					feed;
	
	while( feed = [enumerator nextObject] ){
		if( [feed unreadArticleCount] > 0 ){
			return StatusUnread;
		}
	}
	return StatusRead;
}

-(IBAction)markAllRead:(id)sender{
	NSEnumerator *			enumerator = nil;
	Article *				article = nil;
	Feed *					feed = nil;
	
	if( [[self activeArticleStatus] isEqualToString: StatusUnread] ){
		enumerator = [[feedLibrary activeFeeds] objectEnumerator];
		while( feed = [enumerator nextObject] ){
			while( article = [feed oldestUnread] ){
				[article setStatus: StatusRead];
			}
		}
	}
	[self reloadData];
}

-(IBAction)resetArticleKillList:(id)sender{
	[feedLibrary resetArticleKillList];
}

-(IBAction)bookmarkArticle:(id)sender{
	NSIndexSet *			selectedArticles = [articleTableView selectedRowIndexes];
	int						currentIndex;
	
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		[feedLibrary newArticle: [feedLibrary activeArticleAtIndex: currentIndex] inItem: nil atIndex: [feedLibrary childCountOfItem: nil]];
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	[feedOutlineView reloadData];
}

-(IBAction)nextUnread:(id)sender{
	int					currentIndex = 0;
	int					articleCount = [feedLibrary activeArticleCount];
	int					i;
	Article *			article;
	int					nextIndex = -1;
	
	KNDebug(@"CONT: nextUnread");
	/*
	article = [feedLibrary oldestUnreadActiveArticle];
	if( article ){
		[feedLibrary setActiveArticle: article];
		[articleTableView selectRow: [feedLibrary indexOfActiveArticle: article] byExtendingSelection: NO];
		[articleTableView scrollRowToVisible: [feedLibrary indexOfActiveArticle: article]];
	}else{
		KNDebug(@"CONT: no oldestUnreadActiveArticle found in current sources");
	}
	*/
	
	currentIndex = [[articleTableView selectedRowIndexes] lastIndex];
	if( currentIndex == NSNotFound ){
		currentIndex = 0;
	}
	
	for(i=currentIndex+1;i<articleCount;i++){
		article = [feedLibrary activeArticleAtIndex: i];
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
	NSEnumerator *				enumerator = [[feedLibrary activeFeedItems] objectEnumerator];
	Feed *						feed;
	id							feedItem;
	NSMutableArray *			feedLinks = [NSMutableArray array];
	NSMutableString *			feedLink;
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;
	
	while( feedItem = [enumerator nextObject] ){
		if( [feedLibrary isFeedItem: feedItem] ){
			feed = [feedLibrary feedForItem: feedItem];
			feedLink = [NSMutableString stringWithString: [feed source]];
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
	NSEnumerator *				enumerator = [[feedLibrary activeFeedItems] objectEnumerator];
	Feed *						feed;
	id							feedItem;
	NSMutableArray *			feedLinks = [NSMutableArray array];
	
	while( feedItem = [enumerator nextObject] ){
		if( [feedLibrary isFeedItem: feedItem] ){
			feed = [feedLibrary feedForItem: feedItem];
			[feedLinks addObject: [feed source]];
		}
	}
	
	if( [feedLinks count] > 0 ){
		NSPasteboard *			pboard = [NSPasteboard generalPasteboard];
		[pboard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
		[pboard setString: [feedLinks componentsJoinedByString:@"\n"] forType: NSStringPboardType];
	}
}


-(IBAction)getInfo:(id)sender{
	id					item = nil;
	
	if( [[feedLibrary activeFeedItems] count] == 1 ){
		item = [[feedLibrary activeFeedItems] objectAtIndex: 0];
		
	}
	[inspector setItem: item];
	[[inspector window] makeKeyAndOrderFront: self];
}

#pragma mark -
#pragma mark Drawer Support

-(void)drawerDidOpen:(NSNotification *)notification{
    [PREFS setFeedDrawerState: YES];
	[articleTableView setNextKeyView: displayWebView];
	[displayWebView setNextKeyView: feedOutlineView];
	[feedOutlineView setNextKeyView: articleTableView];
}

-(void)drawerDidClose:(NSNotification *)notification{
    [PREFS setFeedDrawerState: NO];
	[articleTableView setNextKeyView: displayWebView];
	[displayWebView setNextKeyView: articleTableView];
}

-(NSSize)drawerWillResizeContents:(NSDrawer *)drawer toSize:(NSSize)aSize{
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
    NSRect              articleFrame = [[[displaySplitView subviews] objectAtIndex:0] frame];
    NSRect              displayFrame = [[[displaySplitView subviews] objectAtIndex:1] frame];
    
    //KNDebug(@"CONT: Saving split sizes");
    [PREFS setArticleListHeight: articleFrame.size.height+1];
    [PREFS setDisplayHeight: displayFrame.size.height-1];
    
    [articleTableView scrollRowToVisible: [feedLibrary activeArticleCount]-1];
}


#pragma mark -
#pragma mark Contextual Menu Support

-(NSMenu *)menuForFeedRow:(int)row{
	return feedContextMenu;
}

-(NSMenu *)menuForArticleRow:(int)row{
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
			
#pragma mark -
#pragma mark TableView Support

/*
-(void)tableView:(NSTableView *)tableView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)column row:(int)index{
	Article *			article = [feedLibrary activeArticleAtIndex: index];
	NSFontManager *		fontManager = [NSFontManager sharedFontManager];
	
	if( article ){
		if( [[article status] isEqualToString: StatusRead] ){
			[cell setFont: [fontManager convertFont: [cell font] toNotHaveTrait: NSBoldFontMask]];
		}else{
			[cell setFont: [fontManager convertFont: [cell font] toHaveTrait: NSBoldFontMask]];
		}
		
		if( [article isOnServer] ){
			[cell setFont: [fontManager convertFont: [cell font] toNotHaveTrait: NSItalicFontMask]];
		}else{
			[cell setFont: [fontManager convertFont: [cell font] toHaveTrait: NSItalicFontMask]];
		}
	}
}
*/

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)index{
    id                          value = nil;
    Article *                   article = nil;
    //BOOL                        isRead = NO;
    NSCell *                    currentCell = nil;
    NSFontManager *             fontManager = [NSFontManager sharedFontManager];
	NSMutableDictionary *		attributes = [NSMutableDictionary dictionary];
    
    article = [feedLibrary activeArticleAtIndex: index];
    if( article ){
		currentCell = [column dataCell];
		[currentCell setWraps: YES];
		[attributes setObject: tableWrapStyle forKey: NSParagraphStyleAttributeName];
		
		//KNDebug(@"CONT: setting attributes. Cell is %@", currentCell);
		//[attributes setObject: [NSNumber numberWithFloat: 10.0] forKey: NSBaselineOffsetAttributeName];
		if( [[article status] isEqualToString: StatusUnread] ){
			[attributes setObject: [fontManager convertFont: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] toHaveTrait: NSBoldFontMask] forKey: NSFontAttributeName];
		}else{
			[attributes setObject: [fontManager convertFont: [NSFont systemFontOfSize:[NSFont smallSystemFontSize]] toNotHaveTrait: NSBoldFontMask] forKey: NSFontAttributeName];
		}
		if( ![article isOnServer] ){
			[attributes setObject: [PREFS expiredArticleColor] forKey: NSForegroundColorAttributeName];
		}
		//KNDebug(@"CONT: attributes are %@", attributes);
		
        if( [[column identifier] isEqualToString: ArticleTitle] ){
            value = [[[NSAttributedString alloc] 
				initWithString: [article title]
				attributes: attributes] autorelease];
        }else if( [[column identifier] isEqualToString: ArticleAuthor] ){
            value = [[[NSAttributedString alloc]
				initWithString: [article author]
				attributes: attributes] autorelease];
        }else if( [[column identifier] isEqualToString: ArticleCategory] ){
            value = [[[NSAttributedString alloc]
				initWithString: [article category]
				attributes: attributes] autorelease];
        }else if( [[column identifier] isEqualToString: ArticleFeedName] ){
            value = [[[NSAttributedString alloc]
				initWithString: [[article feed] title]
				attributes: attributes] autorelease];
        }else if( [[column identifier] isEqualToString: ArticleDate] ){
			value = [[[NSAttributedString alloc]
				initWithString:[[article date] naturalStringForWidth: [column width] withAttributes: attributes]
				attributes: attributes] autorelease];
				
		}else if( [[column identifier] isEqualToString: ArticleSource] ){
			value = [[[NSAttributedString alloc]
				initWithString: [article source]
				attributes: attributes] autorelease];
			
		}else if( [[column identifier] isEqualToString: ArticleStatus] ){
			value = [[article status] isEqualToString: StatusRead] ? nil : [NSImage imageNamed: [article status]];
        }else if( [[column identifier] isEqualToString: ArticleOnServer] ){
			value = [article isOnServer] ? [NSImage imageNamed: ArticleOnServerImage] : nil;
		}
    }
    return value;
}

-(int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [feedLibrary activeArticleCount];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
    Article *                   article = nil;
	NSMutableArray *			articleIndexList = [NSMutableArray array];
	NSIndexSet *				selectedArticles;
	int							currentIndex;
    
	currentIndex = -1;
	selectedArticles = [articleTableView selectedRowIndexes];
	currentIndex = [selectedArticles firstIndex];
	while( currentIndex != NSNotFound ){
		[articleIndexList addObject: [NSNumber numberWithInt: currentIndex]];
		currentIndex = [selectedArticles indexGreaterThanIndex: currentIndex];
	}
	KNDebug(@"CONT: there are %d selected articles", [articleIndexList count]);
	
	if( [articleIndexList count] == 1 ){
		[feedLibrary setActiveArticleIndex: [[articleIndexList objectAtIndex:0] intValue]];
		
		id						item = [feedOutlineView itemAtRow: [[feedOutlineView selectedRowIndexes] firstIndex]];
		[feedLibrary setActiveArticle:[feedLibrary activeArticle] forItem: item];
	}else{
		[feedLibrary setActiveArticleIndex: NSNotFound];
	}
	article = [feedLibrary activeArticle];
	[self setDisplayedArticle: article];
	[articleTableView scrollRowToVisible: [feedLibrary activeArticleIndex]];
}


-(void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)column{
    [tableView setHighlightedTableColumn: column];
	/*
    [feedLibrary setSortKey: [column identifier]];
	//[[column headerCell] drawSortIndicatorWithFrame: [[column headerCell] cellFrame] inView: tableView ascending: YES priority: 0];
    [articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection: NO];
    [articleTableView reloadData];
	*/
}

-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)column row:(int)index{
    return NO;
}

-(void)tableViewColumnDidMove:(NSNotification *)notification{
    //KNDebug(@"column did move");
    [self rememberVisibleColumns: self];
}

-(void)tableViewColumnDidResize:(NSNotification *)notification{
    if( ! disableResizeNotifications ){
        //KNDebug(@"column did resize");
        [self rememberVisibleColumns: self];
    }
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
	//KNDebug(@"CONT: sortDescriptorsDidChange to %@", [tableView sortDescriptors]);
	[feedLibrary setSortDescriptors: [tableView sortDescriptors]];
	[feedLibrary sortActiveArticles];
	[articleTableView reloadData];
	[articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection:NO ];
}

#pragma mark -
#pragma mark OutlineView Support

-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)column item:(id)item{
    //return( ([[outlineView selectedRowIndexes] count] == 1) && [feedLibrary isFolderItem: item] );
	return YES;
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification{
    NSMutableArray *            feedList = [NSMutableArray array];
    NSIndexSet *                selectedFeeds;
    int                         currentIndex;
    
    
    //KNDebug(@"CONT: outlineViewSelectionDidChange");
    [removeFeedButton setEnabled: ([feedOutlineView selectedRow] != -1)];
    
    selectedFeeds = [feedOutlineView selectedRowIndexes];
    currentIndex = [selectedFeeds firstIndex];
    
    while( currentIndex != NSNotFound ){
        //KNDebug(@"CONT: Adding feed at index %d", currentIndex);
        [feedList addObject: [feedOutlineView itemAtRow: currentIndex]];
        currentIndex = [selectedFeeds indexGreaterThanIndex: currentIndex];
    }
    [feedLibrary setActiveFeedItems: feedList];
	
	currentIndex = [feedLibrary activeArticleIndex];
    [articleTableView reloadData];
	[feedLibrary setActiveArticleIndex: currentIndex];
	
    if( [feedLibrary activeArticleIndex] != NSNotFound ){
        //KNDebug(@"CONT: found an active article index %d", [feedLibrary activeArticleIndex]);
        [articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection: NO];
    }else{
		//KNDebug(@"CONT: no saved active article for %d", [feedLibrary activeArticleIndex]);
		
		Article *			article = nil;
		id					item = nil;
		
		[articleTableView deselectAll: self];
		
		currentIndex = [selectedFeeds firstIndex];
		while( currentIndex != NSNotFound ){
			item = [feedOutlineView itemAtRow: currentIndex];
			//KNDebug(@"CONT: Checking for saved selection in item %@", item);
			article = [feedLibrary activeArticleForItem: item];
			if( article ){
				//KNDebug(@"CONT: found saved selection %@", article);
				break;
			}
			currentIndex = [selectedFeeds indexGreaterThanIndex: currentIndex];
		}
		
		if( article ){
			KNDebug(@"CONT: found saved active article %@ for item", article);
			[feedLibrary setActiveArticle: article];
			[articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection: NO];
		}else if( [feedLibrary oldestUnreadActiveArticle] ){
			KNDebug(@"CONT: found unread article to select (%d)", [feedLibrary indexOfActiveArticle: [feedLibrary oldestUnreadActiveArticle]]);
			[feedLibrary setActiveArticle: [feedLibrary oldestUnreadActiveArticle]];
			[articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection: NO];
		}else if( [feedLibrary newestActiveArticle] ){
			KNDebug(@"CONT: no saved article - using newestActive");
			[feedLibrary setActiveArticle: [feedLibrary newestActiveArticle]];
			[articleTableView selectRow: [feedLibrary activeArticleIndex] byExtendingSelection: NO];
		}
    }
    
    //KNDebug(@"CONT: feed selection changed: Selected Article is %d", [articleTableView selectedRow]);
    [self setWindowTitle];
    
    //[articleTableView scrollRowToVisible: [feedLibrary activeArticleCount]-1];
	[self updateStatus];
	
	// Set our item in our inspector
	if( [selectedFeeds count] == 1 ){
		[inspector setItem: [feedOutlineView itemAtRow: [selectedFeeds firstIndex]]];
	}else{
		[inspector setItem: nil];
	}
}

-(id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item{
    return [feedLibrary child:index ofItem:item];
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    return [feedLibrary hasChildren: item];
}

-(int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    return [feedLibrary childCountOfItem:item];
}

-(void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item{
	NSImage *				sourceImage = nil;
	NSImage *				cellImage = nil;
	
	if( [feedLibrary isFolderItem:item] ){
		sourceImage = folderImage;
	}else if( [feedLibrary isFeedItem: item] ){
		if( [[feedLibrary feedForItem: item] error] ){
			sourceImage = [NSImage imageNamed:FeedErrorImage];
		}else{
			sourceImage = [[feedLibrary feedForItem: item] icon];
		}
	}else if( [feedLibrary isArticleItem: item] ){
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

-(NSString *)outlineView:(NSOutlineView *)outlineView toolTipForTableColumn:(NSTableColumn *)column row:(int)rowIndex{
	id					item = [feedOutlineView itemAtRow: rowIndex];
	Feed *				feed;
	
	if( item ){
		if( [feedLibrary isFeedItem: item] ){
			feed = [feedLibrary feedForItem: item];
			if( [feed error] ){
				return [feed error];
			}else{
				return [feed source];
			}
		}else if( [feedLibrary isFolderItem: item] ){
			return [NSString stringWithFormat: @"Contains %d feeds", [[feedLibrary feedsInFolder: item] count]];
		}else if( [feedLibrary isArticleItem: item] ){
			return [NSString stringWithFormat: @"Feed: %@", [[feedLibrary articleForItem: item] feedName]];
		}
	}
	return nil;
}

-(id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)column byItem:(id)item{
    NSAttributedString *		value;
	NSMutableString *			rawValue = [NSMutableString stringWithString: [feedLibrary nameForItem: item]];
	NSCell *					currentCell = [column dataCell];
    NSFontManager *				fontManager = [NSFontManager sharedFontManager];
	NSMutableDictionary *		attributes = [NSMutableDictionary dictionary];
    
	[attributes setObject: tableWrapStyle forKey: NSParagraphStyleAttributeName];
	
	if( ([feedLibrary unreadCountForItem: item] > 0) && ([feedOutlineView editedRow] != [feedOutlineView rowForItem: item]) ){
		[attributes setObject: [fontManager convertFont: [currentCell font] toHaveTrait:NSBoldFontMask] forKey: NSFontAttributeName];
		[rawValue appendFormat: @" (%d)", [feedLibrary unreadCountForItem: item]];
	}else{
		[attributes setObject: [fontManager convertFont: [currentCell font] toNotHaveTrait:NSBoldFontMask] forKey: NSFontAttributeName];
	}
	
	if( [feedLibrary isFeedItem: item] && [[feedLibrary feedForItem: item] error] ){
		[attributes setObject:[NSColor redColor] forKey: NSForegroundColorAttributeName];
	}
	
	/*
	if( [feedLibrary isArticleItem: item] ){
		[attributes setObject: [NSNumber numberWithInt:NSSingleUnderlineStyle] forKey:NSUnderlineStyleAttributeName ];
	}
	*/

	value = [[[NSAttributedString alloc] 
				//initWithString: [rawValue ellipsizeToWidth: [column width] withAttributes: attributes]
				initWithString: rawValue
				attributes: attributes] autorelease];

	return value;
}

-(void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)column byItem:(id)item{
	[feedLibrary setName: object forItem: item];
}

-(id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item{
	return [feedLibrary keyForItem: item];
}

-(id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object{
	return [feedLibrary itemForKey: object];
}

#pragma mark -
#pragma mark Drag & Drop Support

-(NSArray *)draggedFeedItems{ return draggedFeedItems; }
-(NSArray *)draggedArticles{ return draggedArticles; }

-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard{
	if( draggedFeedItems ){ [draggedFeedItems release]; }
	draggedFeedItems = items;
	[draggedFeedItems retain];
	currentDragSource = outlineView;
	[pboard declareTypes:[NSArray arrayWithObjects: DragDropFeedItemPboardType, NSStringPboardType, nil] owner: self];
	[pboard setData: [NSData data] forType: DragDropFeedItemPboardType];
	return YES;
}

-(unsigned int)outlineView:(NSOutlineView*)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)childIndex{
	BOOL					targetNodeIsValid = YES;
	NSEnumerator *			enumerator;
	id						draggedItem;
	
	if( (item != nil) && (childIndex==NSOutlineViewDropOnItemIndex) && (![feedLibrary isFolderItem: item]) ){
		targetNodeIsValid = NO;
	}
	
	
	if( targetNodeIsValid &&
		(([info draggingSource]==outlineView) || ([info draggingSource]==articleTableView)) &&
		[[info draggingPasteboard] availableTypeFromArray:
			[NSArray arrayWithObjects: DragDropFeedItemPboardType, DragDropFeedArticlePboardType, nil]] != nil ){
		
		if( [info draggingSource] == feedOutlineView ){
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while( draggedItem = [enumerator nextObject] ){
				if( [feedLibrary isItem: item descendentOfItem: draggedItem] ){
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
		if( [feedLibrary isFolderItem: targetItem] && dropOn ){
			//KNDebug(@"CONT: dropOn and folder");
			//newIndex = [feedLibrary childCountOfItem: targetItem];
		}
			
		
		//KNDebug(@"CONT: we reset our childIndex from %d to %d", childIndex, newIndex);
		if( [info draggingSource] == outlineView ){
			[feedOutlineView deselectAll: self];
			
			// Actually move all the items
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while( draggedItem = [enumerator nextObject] ){
				[feedLibrary moveItem: draggedItem toParent: targetItem index: newIndex];
			}
			[feedOutlineView reloadData];
			
			// Reset our selection
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while( draggedItem = [enumerator nextObject] ){
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
			while( draggedArticleIndex = [enumerator nextObject] ){
				Article *				article = [feedLibrary activeArticleAtIndex: [draggedArticleIndex intValue]];

				draggedItem = [feedLibrary newArticle: article inItem: targetItem atIndex: newIndex];
				[articleSelection addObject: draggedItem];
			}
			[feedOutlineView reloadData];
			[feedOutlineView deselectAll: self];
			
			enumerator = [articleSelection objectEnumerator];
			while( draggedItem = [enumerator nextObject] ){
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
		Feed *					newFeed;
		int						feedsAdded = 0;
		
		enumerator = [sources objectEnumerator];
		while( newSource = [enumerator nextObject] ){
			NSMutableString *			cleanSource = [NSMutableString stringWithString: newSource];

			[cleanSource replaceOccurrencesOfString:@"feed:" withString:@"http:" options:NSCaseInsensitiveSearch range:NSMakeRange(0,5)];
			newFeed = [[Feed alloc] initWithSource: cleanSource];
			if( [feedLibrary newFeed: newFeed inItem: targetItem atIndex: newIndex ] ){
				[feedLibrary refreshFeed: newFeed];
				feedsAdded++;
			}
			[newFeed release];
		}
		
		if( feedsAdded > 0 ){
			[feedLibrary startUpdate];
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
	Article *					article;
	Feed *						feed;
	id							feedItem;
	NSNumber *					articleIndex;
	NSMutableString *			draggedString = [NSMutableString string];
	NSEnumerator *				folderEnumerator;
	
	if( [type isEqualToString: NSStringPboardType] ){
		
		if( currentDragSource == articleTableView ){
			enumerator = [[self draggedArticles] objectEnumerator];
			while( articleIndex = [enumerator nextObject] ){
				article = [feedLibrary activeArticleAtIndex: [articleIndex intValue]];
				if( ![[article link] isEqualToString: @""] ){
					[draggedString appendFormat: @"%@\n", [article link]];
				}else{
					[draggedString appendFormat: @"%@\n", [[article feed] source]];
				}
			}
		}else if( currentDragSource == feedOutlineView ){
			enumerator = [[self draggedFeedItems] objectEnumerator];
			while( feedItem = [enumerator nextObject] ){
				if( [feedLibrary isFeedItem: feedItem] ){
					[draggedString appendFormat: @"%@\n", [[feedLibrary feedForItem: feedItem] source]];
					
				}else if( [feedLibrary isFolderItem: feedItem] ){
					folderEnumerator = [[feedLibrary feedsInFolder: feedItem] objectEnumerator];
					while( feed = [folderEnumerator nextObject] ){
						[draggedString appendFormat: @"%@\n", [feed source]];
					}
					
				}else if( [feedLibrary isArticleItem: feedItem] ){
					article = [feedLibrary articleForItem: feedItem];
					if( [[article link] isEqualToString: @""] ){
						[draggedString appendFormat: @"%@\n", [[article feed] source]];
					}else{
						[draggedString appendFormat: @"%@\n", [article link]];
					}
					
				}
			}
		}
		[pboard setString: [draggedString trimWhitespace] forType: type];
	}
}

@end
