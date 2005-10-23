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
#import "Prefs.h"
#import "KNUtility.h"
#import "FeedDelegate.h"
#import "KNArticle.h"
#define FEED_DRAWER_STATE @"DrawerState"
#define FEED_DRAWER_STATE_DEFAULT YES
#define FEED_CURRENT_SELECTION @"CurrentFeedSelection"
#define FEED_CURRENT_SELECTION_DEFAULT -1
#define ARTICLE_CURRENT_SELECTION @"CurrentArticleSelection"
#define ARTICLE_CURRENT_SELECTION_DEFAULT -1
#define FEED_UPDATE_INTERVAL @"FeedUpdateInterval"
#define FEED_UPDATE_INTERVAL_DEFAULT 1800
#define FEED_UPDATE_UNITS @"FeedUpdateUnits"
#define FEED_UPDATE_UNITS_DEFAULT UNIT_MINUTES
#define FEED_UPDATE_LENGTH @"FeedUpdateLength"
#define FEED_UPDATE_LENGTH_DEFAULT 15
#define FEED_RETRY_INTERVAL @"FeedRetryInterval"
#define FEED_RETRY_INTERVAL_DEFAULT 300
#define VISIBLE_ARTICLE_COLUMNS @"VisibleArticleColumns"
#define FEED_DRAWER_SIZE @"FeedDrawerSize"
#define FEED_DRAWER_SIZE_DEFAULT NSMakeSize(200,0)
#define SOURCE_LIST_WIDTH @"SourceListWidth"
#define SOURCE_LIST_WIDTH_DEFAULT 200
#define ARTICLE_LIST_HEIGHT @"ArticleListHeight"
#define ARTICLE_LIST_HEIGHT_DEFAULT 300
#define DISPLAY_HEIGHT @"DisplayHeight"
#define DISPLAY_HEIGHT_DEFAULT 100
#define ARTICLE_EXPIRE_INTERVAL @"ArticleExpireInterval"
#define ARTICLE_EXPIRE_INTERVAL_DEFAULT -1
#define ARTICLE_DELETE_WARNING @"ArticleDeleteWarning"
#define ARTICLE_DELETE_WARNING_DEFAULT YES
#define SHOW_UNREAD_IN_DOCK @"ShowUnreadInDock"
#define SHOW_UNREAD_IN_DOCK_DEFAULT YES
#define LAUNCH_EXTERNAL_IN_BACKGROUND @"LaunchExternalInBackground"
#define LAUNCH_EXTERNAL_IN_BACKGROUND_DEFAULT YES
#define ARTICLE_LIST_FONT_NAME @"ArticleListFontName"
#define ARTICLE_LIST_FONT_NAME_DEFAULT [[NSFont systemFontOfSize:10] familyName]
#define ARTICLE_LIST_FONT_SIZE @"ArticleListFontSize"
#define ARTICLE_LIST_FONT_SIZE_DEFAULT [NSFont systemFontSize]
#define ARTICLE_FONT_NAME @"ArticleFontName"
#define ARTICLE_FONT_NAME_DEFAULT [[NSFont systemFontOfSize:10] familyName]
#define ARTICLE_FONT_SIZE @"ArticleFontSize"
#define ARTICLE_FONT_SIZE_DEFAULT [NSFont smallSystemFontSize]
#define ARTICLE_EXPIRED_COLOR @"ArticleExpiredColor"
#define ARTICLE_EXPIRED_COLOR_DEFAULT [NSColor blackColor]
#define SHOW_DEBUG_MENU @"ShowDebugMenu"
#define DEBUGGING @"Debugging"
#define DEBUGGING_DEFAULT NO
#define SHOULD_CHECK_PROTOCOL_REGISTRATION @"ShouldCheckProtocolRegistration"
#define SHOULD_CHECK_PROTOCOL_REGISTRATION_DEFAULT NO
#define NOTIFICATION_SOUND_NAME @"NotificaionSoundName"
#define NOTIFICATION_SOUND_NAME_DEFAULT @""
#define MAX_UPDATE_THREADS @"MaxUpdateThreads"
#define MAX_UPDATE_THREADS_DEFAULT 5
#define REQUEST_TIMEOUT_INTERVAL @"RequestTimeoutInterval"
#define REQUEST_TIMEOUT_INTERVAL_DEFAULT 5
#define USER_AGENT_STRING @"UserAgentString"
#define USER_AGENT_STRING_DEFAULT @"Feed (0.6.5)"
#define USE_TORRENT_SCHEME @"UseTorrentScheme"
#define USE_TORRENT_SCHEME_DEFAULT NO
#define ARTICLE_SELECTION_INDEXES @"ArticleSelectionIndexes"
#define SOURCE_SELECTION_INDEXES @"SourceSelectionIndexes"
#define SORT_DESCRIPTORS @"SortDescriptors"


#define DEFAULTS [NSUserDefaults standardUserDefaults]

@implementation Prefs

static Prefs * sharedPrefsObject = nil;
+(id)sharedPrefs{
    return sharedPrefsObject ? sharedPrefsObject : [[self alloc] init];
}

-(void)dealloc{
    if( self != sharedPrefsObject ){ [super dealloc]; }
}

-(id)init{
    if( sharedPrefsObject ){ [self release]; }
    else if((self = [super init])){
        sharedPrefsObject = self;
    }
    return sharedPrefsObject;
}

-(BOOL)feedDrawerState{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    
    if( [defaults objectForKey: FEED_DRAWER_STATE] ){
        return [[defaults objectForKey: FEED_DRAWER_STATE] boolValue];
    }else{
        return FEED_DRAWER_STATE_DEFAULT;
    }
}

-(void)setFeedDrawerState:(BOOL)isOpen{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [NSNumber numberWithBool: isOpen] forKey: FEED_DRAWER_STATE];
}

-(NSSize)feedDrawerSize{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    
    if( [defaults objectForKey: FEED_DRAWER_SIZE] ){
        return NSSizeFromString([defaults objectForKey: FEED_DRAWER_SIZE]);
    }else{
        return FEED_DRAWER_SIZE_DEFAULT;
    }
}

-(void)setFeedDrawerSize:(NSSize)aSize{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: NSStringFromSize(aSize) forKey: FEED_DRAWER_SIZE];
}

-(NSTimeInterval)updateInterval{
    return( [self updateUnits] * [self updateLength] );
}

-(double)updateUnits{
    if( [DEFAULTS objectForKey: FEED_UPDATE_UNITS] ){
        return [[DEFAULTS objectForKey: FEED_UPDATE_UNITS] doubleValue];
    }else{
        return FEED_UPDATE_UNITS_DEFAULT;
    }
}

-(void)setUpdateUnits:(double)units{
    [DEFAULTS setObject: [NSNumber numberWithDouble: units] forKey: FEED_UPDATE_UNITS];
}

-(double)updateLength{
    if( [DEFAULTS objectForKey: FEED_UPDATE_LENGTH] ){
        return [[DEFAULTS objectForKey: FEED_UPDATE_LENGTH] doubleValue];
    }else{
        return FEED_UPDATE_LENGTH_DEFAULT;
    }
}

-(void)setUpdateLength:(double)length{
    [DEFAULTS setObject: [NSNumber numberWithDouble:length] forKey: FEED_UPDATE_LENGTH];
}

-(void)setSourceListWidth:(float)aWidth{
	[DEFAULTS setObject: [NSNumber numberWithFloat: aWidth] forKey: SOURCE_LIST_WIDTH];
}

-(float)sourceListWidth{
	if( [DEFAULTS objectForKey: SOURCE_LIST_WIDTH] ){
		return [[DEFAULTS objectForKey: SOURCE_LIST_WIDTH] floatValue];
	}else{
		return SOURCE_LIST_WIDTH_DEFAULT;
	}
}

-(void)setArticleListHeight:(float)aHeight{
    [DEFAULTS setObject: [NSNumber numberWithFloat: aHeight] forKey: ARTICLE_LIST_HEIGHT];
}

-(float)articleListHeight{
    if( [DEFAULTS objectForKey: ARTICLE_LIST_HEIGHT] ){
        return [[DEFAULTS objectForKey: ARTICLE_LIST_HEIGHT] floatValue];
    }else{
        return ARTICLE_LIST_HEIGHT_DEFAULT;
    }
}

-(void)setDisplayHeight:(float)aHeight{
    [DEFAULTS setObject: [NSNumber numberWithFloat: aHeight] forKey: DISPLAY_HEIGHT];
}

-(float)displayHeight{
    if( [DEFAULTS objectForKey: DISPLAY_HEIGHT] ){
        return [[DEFAULTS objectForKey: DISPLAY_HEIGHT] floatValue];
    }else{
        return DISPLAY_HEIGHT_DEFAULT;
    }

}

-(void)setUpdateInterval:(NSTimeInterval)delay{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: [NSNumber numberWithDouble: delay] forKey: FEED_UPDATE_INTERVAL];
}

-(NSTimeInterval)retryInterval{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    
    if( [defaults objectForKey: FEED_RETRY_INTERVAL] ){
        return (NSTimeInterval) [[defaults objectForKey: FEED_RETRY_INTERVAL] doubleValue];
    }else{
        return (NSTimeInterval) FEED_RETRY_INTERVAL_DEFAULT;
    }
}


-(NSArray *)visibleArticleColumns{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    
    if( [defaults objectForKey: VISIBLE_ARTICLE_COLUMNS ] ){
        return [defaults objectForKey: VISIBLE_ARTICLE_COLUMNS];
    }else{
        NSArray *defaultVisibleColumns = [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt: 0], ColumnIndex,
                [NSNumber numberWithFloat: 20], ColumnWidth,
            nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
                [NSNumber numberWithInt: 1], ColumnIndex,
                [NSNumber numberWithFloat: 200], ColumnWidth,
            nil],
			[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt: 4], ColumnIndex,
				[NSNumber numberWithFloat: 75], ColumnWidth,
			nil],
        nil];

        return defaultVisibleColumns;
    }
}

-(void)setVisibleArticleColumns:(NSArray *)columnList{
    NSUserDefaults *            defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: columnList forKey:VISIBLE_ARTICLE_COLUMNS];
}

-(NSTimeInterval)articleExpireInterval{
	if( [DEFAULTS objectForKey: ARTICLE_EXPIRE_INTERVAL] ){
		return [[DEFAULTS objectForKey: ARTICLE_EXPIRE_INTERVAL] doubleValue];
	}else{
		return ARTICLE_EXPIRE_INTERVAL_DEFAULT;
	}
}

-(void)setArticleExpireInterval:(NSTimeInterval)expireInterval{
	[DEFAULTS setObject: [NSNumber numberWithDouble: expireInterval] forKey: ARTICLE_EXPIRE_INTERVAL];
}

-(BOOL)warnWhenDeletingArticles{
	if( [DEFAULTS objectForKey: ARTICLE_DELETE_WARNING] ){
		return [[DEFAULTS objectForKey: ARTICLE_DELETE_WARNING] boolValue];
	}else{
		return ARTICLE_DELETE_WARNING_DEFAULT;
	}
}

-(void)setWarnWhenDeletingArticles:(BOOL)shouldWarn{
	[DEFAULTS setObject: [NSNumber numberWithBool: shouldWarn] forKey: ARTICLE_DELETE_WARNING];
}

-(BOOL)showUnreadInDock{
	if( [DEFAULTS objectForKey: SHOW_UNREAD_IN_DOCK] ){
		return [[DEFAULTS objectForKey: SHOW_UNREAD_IN_DOCK] boolValue];
	}else{
		return SHOW_UNREAD_IN_DOCK_DEFAULT;
	}
}

-(void)setShowUnreadInDock:(BOOL)showUnread{
	[DEFAULTS setObject: [NSNumber numberWithBool: showUnread] forKey: SHOW_UNREAD_IN_DOCK];
	//[[NSApp delegate] updateDockIcon];
}

-(BOOL)launchExternalInBackground{
	if( [DEFAULTS objectForKey: LAUNCH_EXTERNAL_IN_BACKGROUND] ){
		return [[DEFAULTS objectForKey: LAUNCH_EXTERNAL_IN_BACKGROUND] boolValue];
	}else{
		return LAUNCH_EXTERNAL_IN_BACKGROUND_DEFAULT;
	}
}

-(void)setLaunchExternalInBackground:(BOOL)shouldBackground{
	[DEFAULTS setObject: [NSNumber numberWithBool: shouldBackground] forKey: LAUNCH_EXTERNAL_IN_BACKGROUND];
}


-(NSString *)articleListFontName{
	if( [DEFAULTS objectForKey: ARTICLE_LIST_FONT_NAME] ){
		return [DEFAULTS objectForKey: ARTICLE_LIST_FONT_NAME];
	}else{
		return ARTICLE_LIST_FONT_NAME_DEFAULT;
	}
}

-(void)setArticleListFontName:(NSString *)fontName{
	[DEFAULTS setObject: fontName forKey: ARTICLE_LIST_FONT_NAME];
	[[NSNotificationCenter  defaultCenter] postNotificationName: NotifyArticleListFontNameChanged object: nil];
}

-(NSString *)articleFontName{
	if( [DEFAULTS objectForKey: ARTICLE_FONT_NAME] ){
		return [DEFAULTS objectForKey: ARTICLE_FONT_NAME];
	}else{
		return ARTICLE_FONT_NAME_DEFAULT;
	}
}

-(void)setArticleFontName:(NSString *)fontName{
	[DEFAULTS setObject: fontName forKey: ARTICLE_FONT_NAME];
	[[NSNotificationCenter  defaultCenter] postNotificationName: NotifyArticleFontNameChanged object: nil];
}

-(float)articleListFontSize{
	if( [DEFAULTS objectForKey: ARTICLE_LIST_FONT_SIZE] ){
		return [[DEFAULTS objectForKey: ARTICLE_LIST_FONT_SIZE] floatValue];
	}else{
		return ARTICLE_LIST_FONT_SIZE_DEFAULT;
	}
}

-(void)setArticleListFontSize:(float)fontSize{
	[DEFAULTS setObject: [NSNumber numberWithFloat: fontSize] forKey: ARTICLE_LIST_FONT_SIZE];
	[[NSNotificationCenter  defaultCenter] postNotificationName: NotifyArticleListFontSizeChanged object: nil];
}

-(float)articleFontSize{
	if( [DEFAULTS objectForKey: ARTICLE_FONT_SIZE] ){
		return [[DEFAULTS objectForKey: ARTICLE_FONT_SIZE] floatValue];
	}else{
		return ARTICLE_FONT_SIZE_DEFAULT;
	}
}

-(void)setArticleFontSize:(float)fontSize{
	[DEFAULTS setObject: [NSNumber numberWithFloat: fontSize] forKey: ARTICLE_FONT_SIZE];
	KNDebug(@"PREFS: in database value for font size is %f", [[DEFAULTS objectForKey: ARTICLE_FONT_SIZE] floatValue]);
	[[NSNotificationCenter  defaultCenter] postNotificationName: NotifyArticleFontSizeChanged object: nil];
}

-(NSColor *)expiredArticleColor{
	if( [DEFAULTS objectForKey: ARTICLE_EXPIRED_COLOR] ){
		return (NSColor *) [NSUnarchiver unarchiveObjectWithData: [DEFAULTS objectForKey: ARTICLE_EXPIRED_COLOR]];
	}else{
		return ARTICLE_EXPIRED_COLOR_DEFAULT;
	}
}

-(void)setExpiredArticleColor:(NSColor *)color{
	[DEFAULTS setObject: [NSArchiver archivedDataWithRootObject: color] forKey: ARTICLE_EXPIRED_COLOR];
	[[NSNotificationCenter defaultCenter] postNotificationName: NotifyArticleExpiredColorChanged object: nil];
}

-(BOOL)showDebugMenu{
	if( [DEFAULTS objectForKey: SHOW_DEBUG_MENU] ){
		return [[DEFAULTS objectForKey: SHOW_DEBUG_MENU] boolValue];
	}else{
		return NO;
	}
}

-(void)setDebugging:(BOOL)debug{
	[DEFAULTS setObject: [NSNumber numberWithBool: debug] forKey: DEBUGGING];
}

-(BOOL)debugging{
	if( [DEFAULTS objectForKey: DEBUGGING] ){
		return [[DEFAULTS objectForKey: DEBUGGING] boolValue];
	}else{
		return DEBUGGING_DEFAULT;
	}
}

-(BOOL)shouldCheckProtocolRegistration{
	if( [DEFAULTS objectForKey: SHOULD_CHECK_PROTOCOL_REGISTRATION] ){
		return [[DEFAULTS objectForKey: SHOULD_CHECK_PROTOCOL_REGISTRATION] boolValue];
	}else{
		return SHOULD_CHECK_PROTOCOL_REGISTRATION_DEFAULT;
	}
}

-(void)setShouldCheckProtocolRegistration:(BOOL)shouldCheck{
	[DEFAULTS setObject: [NSNumber numberWithBool: shouldCheck] forKey: SHOULD_CHECK_PROTOCOL_REGISTRATION];
}

-(NSString *)notificationSoundName{
	if( [DEFAULTS objectForKey: NOTIFICATION_SOUND_NAME] ){
		return [DEFAULTS objectForKey: NOTIFICATION_SOUND_NAME];
	}else{
		return NOTIFICATION_SOUND_NAME_DEFAULT;
	}
}

-(void)setNotificationSoundName:(NSString *)soundName{
	[DEFAULTS setObject: soundName forKey: NOTIFICATION_SOUND_NAME];
}

-(int)maxUpdateThreads{
	if( [DEFAULTS objectForKey: MAX_UPDATE_THREADS] ){
		return [[DEFAULTS objectForKey: MAX_UPDATE_THREADS] intValue];
	}else{
		return MAX_UPDATE_THREADS_DEFAULT;
	}
}

-(void)setMaxUpdateThreads:(int)maxUpdate{
	[DEFAULTS setObject: [NSNumber numberWithInt: maxUpdate] forKey: MAX_UPDATE_THREADS];
}

-(NSTimeInterval)requestTimeoutInterval{
	if( [DEFAULTS objectForKey: REQUEST_TIMEOUT_INTERVAL] ){
		return [[DEFAULTS objectForKey: REQUEST_TIMEOUT_INTERVAL] doubleValue];
	}else{
		return REQUEST_TIMEOUT_INTERVAL_DEFAULT;
	}
}

-(void)setRequestTimeoutInterval:(NSTimeInterval)interval{
	[DEFAULTS setObject: [NSNumber numberWithDouble: interval] forKey: REQUEST_TIMEOUT_INTERVAL];
}

-(NSString *)userAgentString{
	if( [DEFAULTS objectForKey: USER_AGENT_STRING] ){
		return [DEFAULTS objectForKey: USER_AGENT_STRING];
	}else{
		return USER_AGENT_STRING_DEFAULT;
	}
}

-(void)setUserAgentString:(NSString *)userAgent{
	[DEFAULTS setObject: userAgent forKey: USER_AGENT_STRING];
}

-(BOOL)useTorrentScheme{
	if( [DEFAULTS objectForKey: USE_TORRENT_SCHEME] ){
		return [[DEFAULTS objectForKey: USE_TORRENT_SCHEME] boolValue];
	}else{
		return USE_TORRENT_SCHEME_DEFAULT;
	}
}

-(void)setUseTorrentScheme:(BOOL)shouldUseTorrent{
	[DEFAULTS setObject: [NSNumber numberWithBool: shouldUseTorrent] forKey: USE_TORRENT_SCHEME];
	[[NSNotificationCenter  defaultCenter] postNotificationName: NotifyArticleTorrentSchemeChanged object: nil];
}

-(NSIndexSet *)articleSelectionIndexes{
	if( [DEFAULTS objectForKey: ARTICLE_SELECTION_INDEXES] ){
		return (NSIndexSet *) [NSUnarchiver unarchiveObjectWithData: [DEFAULTS objectForKey: ARTICLE_SELECTION_INDEXES]];
	}else{
		return [NSIndexSet indexSet];
	}
}

-(void)setArticleSelectionIndexes:(NSIndexSet *)anIndexSet{
	[DEFAULTS setObject: [NSArchiver archivedDataWithRootObject: anIndexSet] forKey: ARTICLE_SELECTION_INDEXES];
}

-(NSIndexSet *)sourceSelectionIndexes{
	if( [DEFAULTS objectForKey: SOURCE_SELECTION_INDEXES] ){
		return (NSIndexSet *) [NSUnarchiver unarchiveObjectWithData: [DEFAULTS objectForKey: SOURCE_SELECTION_INDEXES]];
	}else{
		return [NSIndexSet indexSet];
	}
}

-(void)setSourceSelectionIndexes:(NSIndexSet *)anIndexSet{
	[DEFAULTS setObject: [NSArchiver archivedDataWithRootObject: anIndexSet] forKey: SOURCE_SELECTION_INDEXES];
}

-(NSArray *)sortDescriptors{
	if( [DEFAULTS objectForKey: SORT_DESCRIPTORS] ){
		return (NSArray *) [NSUnarchiver unarchiveObjectWithData: [DEFAULTS objectForKey: SORT_DESCRIPTORS]];
	}else{
		return [NSArray arrayWithObject: [[[NSSortDescriptor alloc] initWithKey: ArticleDate ascending: YES] autorelease]];
	}
}

-(void)setSortDescriptors:(NSArray *)descriptors{
	[DEFAULTS setObject: [NSArchiver archivedDataWithRootObject:descriptors] forKey: SORT_DESCRIPTORS];
}

@end
