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
#import "FeedWindowController+Status.h"

#import "Prefs.h"
#import "Library.h"
#import "Library+Update.h"
#import "KNFeed.h"
#import "KNArticle.h"

#import "KNShelfSplitView.h"
#import "FeedOutlineView.h"
#import "ImageTextCell.h"
#import <WebKit/WebKit.h>

#define DISPLAY_VIEW_MIN_HEIGHT 100
#define ARTICLE_VIEW_MIN_WIDTH 200
#define SOURCE_VIEW_MIN_WIDTH 100


@implementation FeedWindowController (Setup)

-(void)awakeFromNib{
	KNDebug(@"awakeFromNib");
	
	[mainShelfView setFrame: [[[self window] contentView] frame]];
	
	[displaySplitView retain];
	[displaySplitView removeFromSuperview];
	[mainShelfView setContentView: displaySplitView];
	
	[feedSourceScrollView retain];
	[feedSourceScrollView removeFromSuperview];
	[mainShelfView setShelfView: feedSourceScrollView];
	[feedSourceScrollView release];
	
	[mainShelfView setDelegate: self];
	[mainShelfView setTarget: self];
	[mainShelfView setAction: @selector(newFeed:)];
	[mainShelfView setContextButtonMenu: feedContextMenu];
	[mainShelfView setContextButtonImage: [NSImage imageNamed: @"ContextActionButton"]];
	[mainShelfView setActionButtonImage: [NSImage imageNamed: @"AddButton"]];
	
	[feedOutlineView setAutosaveExpandedItems: YES];
	
	[displayWebView setMaintainsBackForwardList:NO];
	[displayWebView setPolicyDelegate: self];
	[displayWebView setUIDelegate: self];
	[displayWebView setResourceLoadDelegate: self];
    
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
		
		if( ! [[columnRecord objectForKey: ColumnIdentifier] isEqualToString: ArticleDate] ){
			[column setSortDescriptorPrototype: 
				[[[NSSortDescriptor alloc] initWithKey: [columnRecord objectForKey:ColumnIdentifier] 
					ascending:YES 
					selector:@selector(localizedCaseInsensitiveCompare:)
				] autorelease]
			];
		}else{
			[column setSortDescriptorPrototype: [[[NSSortDescriptor alloc] initWithKey: [columnRecord objectForKey:ColumnIdentifier] ascending:YES] autorelease]];
		}
        
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
	
	NSImage *		errorImage = [NSImage imageNamed:FeedErrorImage];
	float			badgeSize = 16;
	[errorImage setScalesWhenResized: YES];
	[errorImage setSize: NSMakeSize(badgeSize,badgeSize)];
	
	folderErrorImage = [[NSImage alloc] initWithSize: NSMakeSize(16,16)];
	[folderErrorImage lockFocus];
	[folderImage drawInRect: NSMakeRect(0,0,16,16) fromRect: NSMakeRect(0,0,16,16) operation: NSCompositeCopy fraction: 1.0];
	[errorImage drawInRect: NSMakeRect(0,0,badgeSize,badgeSize) fromRect: NSMakeRect(0,0,badgeSize,badgeSize) operation: NSCompositeSourceOver fraction: 1.0];
	[folderErrorImage unlockFocus];
	
	tableWrapStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	[tableWrapStyle setLineBreakMode: NSLineBreakByTruncatingTail];
	
	ImageTextCell *				dataCell = [[[ImageTextCell alloc] initTextCell:@""] autorelease];
	[dataCell setEditable: YES];
	[dataCell setWraps: YES];
	[[feedOutlineView tableColumnWithIdentifier: @"feedName"] setDataCell: dataCell];
	
	[feedOutlineView selectRowIndexes: [PREFS sourceSelectionIndexes] byExtendingSelection: NO];
	[self refreshArticleCache];
	[articleTableView selectRowIndexes: [PREFS articleSelectionIndexes] byExtendingSelection: NO];
        
    // Register for notifications of updates
	[self registerForNotifications];
	
    [articleTableView setDoubleAction: @selector(articleDoubleClicked:) ];
	[feedOutlineView setDoubleAction: @selector(feedDoubleClicked:) ];
	
	[feedOutlineView registerForDraggedTypes: [NSArray arrayWithObjects:DragDropFeedItemPboardType,DragDropFeedArticlePboardType, NSStringPboardType, nil]];
    
	[feedOutlineView sizeLastColumnToFit];
    [self restoreSplitSize];
	[self updateStatus];
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
        
    [self setWindowTitle];
    disableResizeNotifications = NO;
}

-(void)updateKeyViewLoop{
	BOOL			sourceVisible = ! [mainShelfView isShelfVisible];
	BOOL			previewVisible = ! [displaySplitView isSubviewCollapsed: [[displaySplitView subviews] objectAtIndex:1]];
	
	if( previewVisible ){
		[articleTableView setNextKeyView: displayWebView];
		if( sourceVisible ){
			[displayWebView setNextKeyView: feedOutlineView];
			[feedOutlineView setNextKeyView: articleTableView];
		}else{
			[displayWebView setNextKeyView: articleTableView];
		}
	}else{
		if( sourceVisible ){
			[articleTableView setNextKeyView: feedOutlineView];
			[feedOutlineView setNextKeyView: articleTableView];
		}else{
			[articleTableView setNextKeyView: articleTableView];
		}
	}
}

#pragma mark -
#pragma mark SplitView support

-(void)restoreSplitSize{
    NSView *            articleClip = [[displaySplitView subviews] objectAtIndex:0];
    NSView *            displayClip = [[displaySplitView subviews] objectAtIndex:1];
    NSRect              articleFrame = [articleClip frame];
    NSRect              displayFrame = [displayClip frame];
    
	articleFrame.size.height = [PREFS articleListHeight];
    displayFrame.size.height = [PREFS displayHeight];
    [articleClip setFrame: articleFrame];
    [displayClip setFrame: displayFrame];
    [displaySplitView adjustSubviews];
}

-(void)splitViewDidResizeSubviews:(NSNotification *)notification{
	NSSplitView *			splitView = [notification object];
	
	if( (splitView == displaySplitView) && [displaySplitView inLiveResize] ){
		NSRect              articleFrame = [[[displaySplitView subviews] objectAtIndex:0] frame];
		NSRect              displayFrame = [[[displaySplitView subviews] objectAtIndex:1] frame];
		[PREFS setArticleListHeight: articleFrame.size.height];
		[PREFS setDisplayHeight: displayFrame.size.height];
	}

	[self updateKeyViewLoop];
}

-(BOOL)splitView:(NSSplitView *)aSplitView canCollapseSubview:(NSView *)aSubview{
	if( aSplitView == displaySplitView ){
		return( aSubview == [[displaySplitView subviews] objectAtIndex:1] );
	}
	return NO;
}

-(float)splitView:(NSSplitView *)aSplitView constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset{
#pragma unused( offset )
	if( aSplitView == displaySplitView ){
		proposedMax = [aSplitView frame].size.height - DISPLAY_VIEW_MIN_HEIGHT;
	}
	
	return proposedMax;
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
	NSWorkspaceLaunchOptions	options = [PREFS launchExternalInBackground] ? NSWorkspaceLaunchWithoutActivation : 0;

	if( [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue] == WebNavigationTypeLinkClicked ){
		[listener ignore];
		[[NSWorkspace sharedWorkspace] openURLs: [NSArray arrayWithObject:[request URL]] withAppBundleIdentifier:NULL options: options additionalEventParamDescriptor: NULL launchIdentifiers:NULL];
	}else{
		[listener use];
	}
	
	return;
}

-(void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInfo modifierFlags:(unsigned int)modifierFlags{
#pragma unused( sender, modifierFlags )
	if( elementInfo ){
		[self webKitMouseover: [elementInfo objectForKey:WebElementLinkURLKey]];
	}else{
		[self webKitMouseover: nil];
	}
}

-(id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request fromDataSource:(WebDataSource *)dataSource{
#pragma unused( sender, dataSource )
	[self webKitStartLoading: [[request URL] absoluteString]];
	return [[request URL] absoluteString];
}

-(void)webView:(WebView *)sender resource:(id)resourceKey didFinishLoadingFromDataSource:(WebDataSource *)dataSource{
#pragma unused( sender, dataSource )
	[self webKitEndLoading: resourceKey];
}

-(void)webView:(WebView *)sender resource:(id)resourceKey didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource{
#pragma unused( sender, error, dataSource )
	[self webKitEndLoading: resourceKey];
}

@end
