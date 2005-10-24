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

#import <Cocoa/Cocoa.h>

#define ColumnStatusImageName @"Status"
#define ColumnOnServerImageName @"Status"
#define ArticleOnServerImage @"Updated"
#define BookmarkImage @"Bookmark"
#define FeedErrorImage @"FeedError"

#define DragDropFeedItemPboardType @"FeedItemPboardType"
#define DragDropFeedArticlePboardType @"FeedArticlePboardType"

@class FeedLibrary,KNArticle,LibraryToolbar,InspectorController;

@interface FeedWindowController : NSWindowController
{
	IBOutlet id mainSplitView;
    IBOutlet id articleTableView;
    IBOutlet id displaySplitView;
    IBOutlet id displayWebView;
    IBOutlet id feedOutlineView;
    IBOutlet id newFeedPanel;
    IBOutlet id feedURLTextField;
	IBOutlet id statusTextField;
	IBOutlet id statusProgressIndicator;
	IBOutlet id articleContextMenu;
	IBOutlet id feedContextMenu;
    
    NSArray *					viewColumns;
    BOOL						disableResizeNotifications;
    LibraryToolbar *			feedLibraryToolbar;
    BOOL						isUpdating;
	//NSString *					currentUpdatingFeedTitle;
	NSArray *					draggedFeedItems;
	NSArray *					draggedArticles;
	NSImage *					folderImage;
	NSImage *					folderErrorImage;
	BOOL						isLoadingDisplay;
	NSFont *					articleListFont;
	NSFont *					articleFont;
	NSView *					currentDragSource;
	NSMutableParagraphStyle *	tableWrapStyle;
	InspectorController *		inspector;
	NSMutableArray *			articleCache;
	NSMutableDictionary *		statusMessages;
}



-(IBAction)reloadData;
-(void)setDisplayedArticle:(KNArticle *)anArticle;

-(IBAction)refresh:(id)sender;
-(IBAction)refreshItem:(id)sender;
-(IBAction)newFeed:(id)sender;
-(IBAction)confirmNewFeed:(id)sender;
-(IBAction)removeArticle:(id)sender;
-(void)confirmRemoveArticle:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)info;
-(IBAction)removeFeedItem:(id)sender;
-(IBAction)newFolder:(id)sender;
-(IBAction)openArticlesExternal:(id)sender;
-(IBAction)articleDoubleClicked:(id)sender;
-(IBAction)openFeedsExternal:(id)sender;
-(IBAction)feedDoubleClicked:(id)sender;
-(IBAction)toggleArticleStatus:(id)sender;
-(IBAction)markAllRead:(id)sender;
-(IBAction)bookmarkArticle:(id)sender;
-(IBAction)nextUnread:(id)sender;
-(IBAction)validateSource:(id)sender;
-(IBAction)getInfo:(id)sender;

-(NSString *)selectedArticleStatus;
-(NSString *)activeArticleStatus;

-(void)rememberVisibleColumns:(id)sender;


-(void)setWindowTitle;


-(NSMenu *)menuForFeedRow:(int)row;
-(NSMenu *)menuForArticleRow:(int)row;
@end
