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


#import "FeedWindowController+Articles.h"
#import "FeedWindowController+Sources.h"
#import "Library.h"
#import "Prefs.h"
#import "KNArticle.h"
#import "NSDate+KNExtras.h"

#import <WebKit/WebKit.h>

@implementation FeedWindowController (Articles)



-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(int)idx{
#pragma unused(tableView)
    id							value = nil;
    KNArticle *					article = nil;
    NSCell *					currentCell = nil;
    NSFontManager *				fontManager = [NSFontManager sharedFontManager];
	NSMutableDictionary *		attributes = [NSMutableDictionary dictionary];
    
    article = [articleCache objectAtIndex: idx];
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
			value = [[[NSMutableAttributedString alloc] initWithAttributedString: [article title]] autorelease];
			[value setAttributes: attributes range: NSMakeRange(0,[value length])];
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
				initWithString: [article feedName]
				attributes: attributes] autorelease];
        }else if( [[column identifier] isEqualToString: ArticleDate] ){
			value = [[[NSAttributedString alloc]
				initWithString:[[article date] naturalStringForWidth: [column width] withAttributes: attributes]
				attributes: attributes] autorelease];
				
		}else if( [[column identifier] isEqualToString: ArticleSourceURL] ){
			value = [[[NSAttributedString alloc]
				initWithString: [article sourceURL]
				attributes: attributes] autorelease];
			
		}else if( [[column identifier] isEqualToString: ArticleStatus] ){
			value = [[article status] isEqualToString: StatusRead] ? nil : [NSImage imageNamed: [article status]];
		
		}else if( [[column identifier] isEqualToString: ArticleIsOnServer] ){
			value = [article isOnServer] ? [NSImage imageNamed: ArticleOnServerImage] : nil;
		}
    }
    return value;
}

-(int)numberOfRowsInTableView:(NSTableView *)tableView{
#pragma unused(tableView)
    return [articleCache count];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification{
#pragma unused(notification)
	NSIndexSet *				selection = [articleTableView selectedRowIndexes];
	
	KNDebug(@"article selection changed");
	[PREFS setArticleSelectionIndexes: selection];
	if( [selection count] == 1 ){
		[self setDisplayedArticle: [articleCache objectAtIndex: [selection firstIndex]]];
	}else{
		[self setDisplayedArticle: nil];
	}
	
	[articleTableView reloadData];
}


-(void)tableView:(NSTableView *)tableView didClickTableColumn:(NSTableColumn *)column{
    [tableView setHighlightedTableColumn: column];
}

-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)column row:(int)idx{
#pragma unused(tableView,column,idx)
    return NO;
}

-(void)tableViewColumnDidMove:(NSNotification *)notification{
#pragma unused(notification)
    //KNDebug(@"column did move");
    [self rememberVisibleColumns: self];
}

-(void)tableViewColumnDidResize:(NSNotification *)notification{
#pragma unused(notification)
    if( ! disableResizeNotifications ){
        //KNDebug(@"column did resize");
        [self rememberVisibleColumns: self];
    }
}

-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors{
#pragma unused(oldDescriptors)
	KNDebug(@"sortDiscriptorsChanged");
	
	[PREFS setSortDescriptors: [tableView sortDescriptors]];
	[self refreshArticleCache];
	[articleTableView reloadData];
}


@end
