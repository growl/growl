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

#import <Foundation/Foundation.h>

#define PREFS [Prefs sharedPrefs]

#define NotifyArticleFontNameChanged @"ArticleFontNameChanged"
#define NotifyArticleFontSizeChanged @"ArticleFontSizeChanged"
#define NotifyArticleListFontNameChanged @"ArticleListFontNameChanged"
#define NotifyArticleListFontSizeChanged @"ArticleListFontSizeChanged"
#define NotifyArticleExpiredColorChanged @"ArticleExpiredColorChanged"
#define NotifyArticleTorrentSchemeChanged @"ArticleTorrentSchemeChanged"

#define ColumnName @"Name"
#define ColumnIdentifier @"Identifier"
#define ColumnHeaderObject @"HeaderObject"
#define ColumnState @"State"
#define ColumnCanDisable @"CanDisable"
#define ColumnWidth @"Width"
#define ColumnMenuItem @"MenuItem"
#define ColumnIndex @"Index"

#define ColumnStateOff @"Off"
#define ColumnStateVisible @"Visible"
#define ColumnStateSelected @"Selected"

#define UNIT_NEVER -1
#define UNIT_MINUTES 60
#define UNIT_HOURS (UNIT_MINUTES * 60)
#define UNIT_DAYS (UNIT_HOURS * 24)
#define UNIT_WEEKS (UNIT_DAYS * 7)
#define UNIT_MONTHS (UNIT_DAYS * 30)

@interface Prefs : NSObject {

}

+(id)sharedPrefs;

-(BOOL)feedDrawerState;
-(void)setFeedDrawerState:(BOOL)isOpen;
-(NSSize)feedDrawerSize;
-(void)setFeedDrawerSize:(NSSize)aSize;

-(void)setSourceListWidth:(float)aWidth;
-(float)sourceListWidth;
-(void)setArticleListHeight:(float)aHeight;
-(float)articleListHeight;
-(void)setDisplayHeight:(float)aHeight;
-(float)displayHeight;

-(double)updateUnits;
-(void)setUpdateUnits:(double)units;
-(double)updateLength;
-(void)setUpdateLength:(double)length;

-(NSTimeInterval)updateInterval;
-(NSTimeInterval)retryInterval;

-(NSTimeInterval)articleExpireInterval;
-(void)setArticleExpireInterval:(NSTimeInterval)expireInterval;

-(NSArray *)visibleArticleColumns;
-(void)setVisibleArticleColumns:(NSArray *)columnList;

-(BOOL)warnWhenDeletingArticles;
-(void)setWarnWhenDeletingArticles:(BOOL)shouldWarn;

-(BOOL)showUnreadInDock;
-(void)setShowUnreadInDock:(BOOL)showUnread;

-(BOOL)launchExternalInBackground;
-(void)setLaunchExternalInBackground:(BOOL)shouldBackground;

-(NSString *)articleListFontName;
-(void)setArticleListFontName:(NSString *)fontName;
-(NSString *)articleFontName;
-(void)setArticleFontName:(NSString *)fontName;
-(float)articleListFontSize;
-(void)setArticleListFontSize:(float)fontSize;
-(float)articleListFontSize;
-(void)setArticleFontSize:(float)fontSize;
-(float)articleFontSize;

-(NSColor *)expiredArticleColor;
-(void)setExpiredArticleColor:(NSColor *)color;

-(BOOL)showDebugMenu;
-(void)setDebugging:(BOOL)debug;
-(BOOL)debugging;

-(BOOL)shouldCheckProtocolRegistration;
-(void)setShouldCheckProtocolRegistration:(BOOL)shouldCheck;

-(NSString *)notificationSoundName;
-(void)setNotificationSoundName:(NSString *)soundName;
/*
-(NSString *)registeredProtocolHandlerAppPath;
-(void)setRegisteredProtocolHandlerAppPath:(NSString *)appPath;
*/

-(int)maxUpdateThreads;
-(void)setMaxUpdateThreads:(int)maxUpdate;

-(NSTimeInterval)requestTimeoutInterval;
-(void)setRequestTimeoutInterval:(NSTimeInterval)interval;

-(NSString *)userAgentString;
-(void)setUserAgentString:(NSString *)userAgent;

-(BOOL)useTorrentScheme;
-(void)setUseTorrentScheme:(BOOL)shouldUseTorrent;

-(NSIndexSet *)articleSelectionIndexes;
-(void)setArticleSelectionIndexes:(NSIndexSet *)anIndexSet;
-(NSIndexSet *)sourceSelectionIndexes;
-(void)setSourceSelectionIndexes:(NSIndexSet *)anIndexSet;
-(NSArray *)sortDescriptors;
-(void)setSortDescriptors:(NSArray *)descriptors;

-(BOOL)showStatusBar;
-(void)setShowStatusBar:(BOOL)shouldShowStatusBar;
@end
