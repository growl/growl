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

#import "FeedWindowController+Setup.h"
#import "FeedWindowController+Sources.h"
#import "Prefs.h"
#import "Library.h"
#import "Library+Update.h"
#import "KNFeed.h"
#import "KNArticle.h"

#import "ImageTextCell.h"
#import <WebKit/WebKit.h>


@implementation FeedWindowController (Setup)

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
        
		if( [[column identifier] isEqualToString: [[[PREFS sortDescriptors] objectAtIndex:0] key] ] ){
            [articleTableView setHighlightedTableColumn: column];
        }
    }
    [articleTableView sizeLastColumnToFit];
	[articleTableView setSortDescriptors: [PREFS sortDescriptors]];

	folderImage = [[[NSWorkspace sharedWorkspace] iconForFile: @"/System/Library"] retain];
	[folderImage setScalesWhenResized:YES];
	[folderImage setSize: NSMakeSize(16,16)];
	
	tableWrapStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[tableWrapStyle setLineBreakMode: NSLineBreakByTruncatingTail];
	
	ImageTextCell *				dataCell = [[[ImageTextCell alloc] initTextCell:@""] autorelease];
	[dataCell setEditable: YES];
	[dataCell setWraps: YES];
	[[feedOutlineView tableColumnWithIdentifier: @"feedName"] setDataCell: dataCell];
	
	[feedOutlineView selectRowIndexes: [PREFS sourceSelectionIndexes] byExtendingSelection: NO];
	[self refreshArticleCache];
	[articleTableView selectRowIndexes: [PREFS articleSelectionIndexes] byExtendingSelection: NO];
    
    // Set our 'remove feed' button state
	if( [[feedOutlineView selectedRowIndexes] count] > 0 ){
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
    
	#warning Disabled auto-scroll to current when resizing
    //[articleTableView scrollRowToVisible: [LIB activeArticleCount]-1];
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
