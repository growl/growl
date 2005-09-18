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
#import "Article.h"

#import "FeedDelegate.h"
#import "FeedLibrary.h"
#import "Feed.h"
#import "Prefs.h"
#import "NSDate+KNExtras.h"
#import "NSString+KNTruncate.h"
#import "KNUtility.h"

#define ArticleKeyArchiveKey @"guid"
#define ArticlePubDateArchiveKey @"pubDate"
#define ArticleDescriptionArchiveKey @"description"

#define UNIQUEKEYLENGTH 20

@implementation Article

-(id)initWithFeed:(Feed *)aFeed dictionary:(NSDictionary *)aDict{
    self = [super init];
    if( self ){
        feed = aFeed;
        
        if( [aDict objectForKey: ArticleTitle] ){
            title = [[aDict objectForKey: ArticleTitle] copy];
        }else{
            title = [[NSString stringWithString:@"Untitled Article"] retain];
        }
        
        if( [aDict objectForKey: ArticleContent] ){
            content = [[aDict objectForKey: ArticleContent] copy];
        }else{
            content = [[NSString alloc] init];
        }
        
        if( [aDict objectForKey: ArticleAuthor] ){
            author = [[aDict objectForKey: ArticleAuthor] copy];
        }else{
            author = [[NSString alloc] init];
        }
        
        if( [aDict objectForKey: ArticleKey] ){ 
            key = [[aDict objectForKey: ArticleKey] copy];
        }else{
            KNDebug(@"No KEY for article!!!");
            key = [[[NSDate date] description] copy];
        }
        
        if( [aDict objectForKey: ArticleSource] ){
            source = [[aDict objectForKey: ArticleSource] copy];
        }else{
            source = [[NSString alloc] init];
        }
        
        if( [aDict objectForKey: ArticleCategory] ){
            category = [[aDict objectForKey: ArticleCategory] copy];
        }else{
            category = [[NSString alloc] init];
        }
        
        if( [aDict objectForKey: ArticleDate] ){
            //pubDate = [[NSDate alloc] initWithString: [aDict objectForKey: ArticlePubDate]];
            date = [[aDict objectForKey: ArticleDate] copy];
        }else{
            date = [[NSDate alloc] init];
        }
        
        if( [aDict objectForKey: ArticleLink] ){
            link = [[aDict objectForKey: ArticleLink] copy];
        }else{
            link = [[NSString alloc] init];
        }
        
        if( [aDict objectForKey: ArticleComments] ){
            comments = [[aDict objectForKey: ArticleComments] copy];
        }else{
            comments = [[NSString alloc] init];
        }
		
		if( [aDict objectForKey: ArticleSourceURL] ){
			sourceURL = [[aDict objectForKey: ArticleSourceURL] copy];
		}else{
			sourceURL = [[NSString alloc] init];
		}
		
		if( [aDict objectForKey: ArticleTorrentURL] ){
			torrent = [[aDict objectForKey: ArticleTorrentURL] copy];
		}else{
			torrent = [[NSString alloc] init];
		}
		
		uniqueKey = [KNUniqueKeyWithLength(UNIQUEKEYLENGTH) retain];
		previewCachePath = nil;
        
        status = [[NSString stringWithString:StatusUnread] retain];
		userTitle = [[NSString stringWithString: @""] retain];
		isOnServer = YES;
		
		[self registerForNotifications];
    }
    return self;
}

-(void)dealloc{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
    [title release];
	[userTitle release];
    [content release];
    [author release];
    [key release];
    [source release];
	[sourceURL release];
    [category release];
    [date release];
    [link release];
    [status release];
	[uniqueKey release];
	[torrent release];
	if( previewCachePath ){ [previewCachePath release]; }
    [super dealloc];
}

-(void)registerForNotifications{
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(invalidateCache:)
		name:NotifyArticleFontNameChanged object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(invalidateCache:)
		name:NotifyArticleFontSizeChanged object: nil
	];
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(invalidateCache:)
		name:NotifyArticleTorrentSchemeChanged object: nil
	];
}

-(id)initWithCoder:(NSCoder *)coder{
//	id					linkData = nil;
//	id					commentsData = nil;
	
	//KNDebug(@"ARTICLE: initWithCoder");
    self = [super init];
    if( self ){
		// These haven't changed
        feed = [coder decodeObjectForKey:ArticleFeed];
        title = [[coder decodeObjectForKey:ArticleTitle] retain];
		author = [[coder decodeObjectForKey:ArticleAuthor] retain];
        source = [[coder decodeObjectForKey:ArticleSource] retain];
        category = [[coder decodeObjectForKey:ArticleCategory] retain];
        link = [[coder decodeObjectForKey:ArticleLink] retain];
        comments = [[coder decodeObjectForKey:ArticleComments] retain];
		
		content = [coder decodeObjectForKey: ArticleContent];
		if( ! content ){ content = [coder decodeObjectForKey: ArticleDescriptionArchiveKey]; }
		[content retain];
		
		date = [coder decodeObjectForKey: ArticleDate];
		if( ! date ){ date = [coder decodeObjectForKey: ArticlePubDateArchiveKey]; }
		[date retain];
		
		key = [coder decodeObjectForKey: ArticleKey];
		if( ! key ){ key = [coder decodeObjectForKey: ArticleKeyArchiveKey]; }
		[key retain];
        		
        status = [coder decodeObjectForKey:ArticleStatus];
        if( status ){
            [status retain];
        }else{
            status = [[NSString stringWithString: StatusUnread] retain];
        }
		
		sourceURL = [coder decodeObjectForKey: ArticleSourceURL];
		if( sourceURL ){
			[sourceURL retain];
		}else{
			sourceURL = [[NSString alloc] init];
		}
		
		userTitle = [coder decodeObjectForKey: ArticleUserTitle];
		if( ! userTitle ){
			userTitle = [NSString stringWithString: @""];
		}
		[userTitle retain];
		
		previewCachePath = [coder decodeObjectForKey: ArticlePreviewCachePath];
		if( previewCachePath ){ [previewCachePath retain]; }
		
		uniqueKey = [coder decodeObjectForKey: ArticleUniqueKey];
		if( ! uniqueKey ){
			uniqueKey = KNUniqueKeyWithLength(UNIQUEKEYLENGTH);
		}
		[uniqueKey retain];
		
		torrent = [coder decodeObjectForKey: ArticleTorrentURL];
		if( ! torrent ){
			torrent = [NSString stringWithString: @""];
		}
		[torrent retain];
		
		isOnServer = NO;
		[self registerForNotifications];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject: feed forKey: ArticleFeed];
    [coder encodeObject: title forKey: ArticleTitle];
	[coder encodeObject: userTitle forKey: ArticleUserTitle];
    [coder encodeObject: content forKey: ArticleContent];
    [coder encodeObject: author forKey: ArticleAuthor];
    [coder encodeObject: key forKey: ArticleKey];
    [coder encodeObject: source forKey: ArticleSource];
	[coder encodeObject: sourceURL forKey: ArticleSourceURL];
    [coder encodeObject: category forKey: ArticleCategory];
    [coder encodeObject: date forKey: ArticleDate];
    [coder encodeObject: comments forKey: ArticleComments];
    [coder encodeObject: status forKey: ArticleStatus];
    [coder encodeObject: link forKey: ArticleLink];
	[coder encodeObject: torrent forKey: ArticleTorrentURL];
	if( previewCachePath ){
		[coder encodeObject: previewCachePath forKey: ArticlePreviewCachePath];
	}
	[coder encodeObject: uniqueKey forKey: ArticleUniqueKey];
}

-(NSString *)description{
    return [NSString stringWithFormat: @"%@ <%@>", title, link];
}

-(NSString *)feedName{
	return [feed title];
}

-(Feed *)feed{
    return feed;
}

-(NSString *)key{
    return key;
}

-(NSComparisonResult)compareByDate:(Article *)article{
	return [[self date] compare: [article date]];
}

/*
-(NSComparisonResult)compare:(Article *)article{
    NSString *              sortKey = [[[NSApp delegate] feedLibrary] sortKey];
    NSDictionary *          statusRankKeys = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt: 3], StatusUnread,
                                    [NSNumber numberWithInt: 2], StatusUpdated,
                                    [NSNumber numberWithInt: 1], StatusRead,
                            nil];
    
    if( [sortKey isEqualToString: ArticleTitle] ){
        return [[self title] caseInsensitiveCompare: [article title]];
    }else if( [sortKey isEqualToString: ArticleAuthor] ){
        return [[self author] caseInsensitiveCompare: [article author]];
    }else if( [sortKey isEqualToString: ArticleDate] ){
        return [[self date] compare: [article date]];
    }else if( [sortKey isEqualToString: ArticleStatus] ){
        return( [(NSNumber *)[statusRankKeys objectForKey: [self status]] compare: (NSNumber *)[statusRankKeys objectForKey:[article status]]] );
    }else if( [sortKey isEqualToString: ArticleCategory] ){
        return [[self category] caseInsensitiveCompare: [article category]];
    }else if( [sortKey isEqualToString: ArticleFeed] ){
        return [[[self feed] title] caseInsensitiveCompare: [[article feed] title]];
    }else{
        return [[self key] caseInsensitiveCompare: [article key]];
    }
}
*/


-(NSString *)title{
    return title;
}

-(void)setTitle:(NSString *)aTitle{
    if( aTitle && ![aTitle isEqualToString: title] ){
        [title autorelease];
        title = [aTitle copy];
        //KNDebug(@"ARTICLE: updated title");
        [self setStatus: StatusUpdated];
    }
}

-(NSString *)userTitle{
	return userTitle;
}

-(void)setUserTitle:(NSString *)aTitle{
	[userTitle autorelease];
	userTitle = [aTitle retain];
}

-(NSString *)content{
    return content;
}

-(void)setContent:(NSString *)aContent{
    if( aContent && ![aContent isEqualToString: content] ){
        [content autorelease];
        content = [[NSString stringWithString: aContent] retain];
        //KNDebug(@"ARTICLE: updated content");
        [self setStatus: StatusUpdated];
    }
}

-(NSString *)author{
    return author;
}

-(void)setAuthor:(NSString *)anAuthor{
    if( anAuthor && ![anAuthor isEqualToString: author] ){
        //KNDebug(@"ARTICLE: updated author %@ -> %@", anAuthor, author);
        [author autorelease];
        author = [[NSString stringWithString: anAuthor] retain];
        [self setStatus: StatusUpdated];
    }
}

-(NSString *)source{
    return source;
}

-(void)setSource:(NSString *)aSource{
    if( aSource && ![aSource isEqualToString: source] ){
        [source autorelease];
        source = [[NSString stringWithString: aSource] retain];
        //KNDebug(@"ARTICLE: updated source");
        [self setStatus: StatusUpdated];
    }
}

-(NSString *)sourceURL{
	return sourceURL;
}

-(void)setSourceURL:(NSString *)aSourceURL{
	if( aSourceURL && ![aSourceURL isEqualToString: sourceURL] ){
		[sourceURL autorelease];
		sourceURL = [[NSString stringWithString: aSourceURL] retain];
		KNDebug(@"ARTICLE: Changed sourceURL to %@", sourceURL);
		[self setStatus: StatusUpdated];
	}
}

-(NSString *)category{
    return category;
}

-(void)setCategory:(NSString *)aCategory{
    if( aCategory && ![aCategory isEqualToString: category] ){
        [category autorelease];
        category = [[NSString stringWithString: aCategory] retain];
        //KNDebug(@"ARTICLE: updated category");
        [self setStatus: StatusUpdated];
    }
}

-(NSString *)comments{
    return comments;
}

-(void)setComments:(NSString *)aComments{
    if( aComments && ![aComments isEqualToString: comments] ){
        [comments autorelease];
        comments = [[NSString stringWithString: aComments] retain];
        //KNDebug(@"ARTICLE: updated comments");
        [self setStatus: StatusUpdated];
    }
}

-(NSDate *)date{
    return date;
}

-(void)setDate:(NSDate *)aDate{
    if( ![aDate isEqualToDate: date] ){
        [date autorelease];
        date = [aDate copy];
		//KNDebug(@"ARTICLE: updated date");
        [self setStatus: StatusUpdated];
    }
}

-(NSString *)link{
    return link;
}

-(void)setLink:(NSString *)aLink{
	//KNDebug(@"ARTICLE: setLink");// %@", aLink);
    if( aLink && ![aLink isEqualToString: link] ){
        [link autorelease];
        link = [[NSString stringWithString: aLink] retain];
        //KNDebug(@"ARTICLE: updated link (%d) %@", [link retainCount], link);
        [self setStatus: StatusUpdated];
    }
}

-(NSString *)torrent{
	return torrent;
}

-(void)setTorrent:(NSString *)aTorrentURL{
	if( aTorrentURL && ![aTorrentURL isEqualToString: torrent] ){
		[torrent autorelease];
		torrent = [[NSString stringWithString: aTorrentURL] retain];
		[self setStatus: StatusUpdated];
	}
}

-(NSString *)status{
    return status;
}

-(void)setStatus:(NSString *)aStatus{
    if(! [aStatus isEqualToString: status] ){
        if( !([aStatus isEqualToString: StatusUpdated] && [status isEqualToString:StatusUnread]) ){
            [status autorelease];
            status = [[NSString stringWithString: aStatus] retain];
            [[[NSApp delegate] feedLibrary] makeDirty];
            //KNDebug(@"SetStatus to %@", status);
			[self setPreviewCachePath: nil];
        }
    }
}

-(BOOL)isOnServer{
	return isOnServer;
}

-(void)setIsOnServer:(BOOL)serverFlag{
	isOnServer = serverFlag;
}

-(void)setPreviewCachePath:(NSString *)path{
	if( previewCachePath != nil ){
		[previewCachePath autorelease];
		previewCachePath = nil;
	}
	if( path ){
		previewCachePath = [path retain];
	}
}

-(NSString *)previewCachePath{
	NSFileManager *				fileManager = [NSFileManager defaultManager];
	
	//KNDebug(@"ARTICLE: previewCachePath %@", previewCachePath);
	if( ! previewCachePath ){
		//KNDebug(@"generating for new path");
		[self generateCache];
	}else if( ! [fileManager fileExistsAtPath: previewCachePath] ){
		//KNDebug(@"generating for existing path %@", previewCachePath);
		[self generateCache];
	}
	
	return previewCachePath;
}

-(void)generateCache{
	NSMutableString *			displayedHTML = [NSMutableString string];
	NSString *                  dateOutput = [NSString string];
	
	KNDebug(@"ARTICLE: Generating article cache. font size is %d", (int) [PREFS articleFontSize]);
	
	[displayedHTML appendFormat:@"<html><head><base href=\"%@\"/><body>", [self link]];
	[displayedHTML appendFormat:@"<style>.feed_label{font-size:9pt;font-weight:bold;}</style>"];
	[displayedHTML appendFormat:@"<style>.feed_header{font-size:9pt; padding-left:5px;}</style>"];
	[displayedHTML appendFormat:@"<style>body,td{font-size:%dpt; font-family:%@;}</style>", (int)[PREFS articleFontSize], [PREFS articleFontName]];
	[displayedHTML appendFormat:@"<table cellpadding=\"0\" cellspacing=\"0\">"];
	[displayedHTML appendFormat:@"<tr><td align=\"right\" valign=\"top\" class=\"feed_label\">Title:</td>"];
	[displayedHTML appendFormat:@"<td valign=\"top\" class=\"feed_header\"><a title=\"Open article in default browser\" href=\"%@\">%@</a></td></tr>", [self link], [self title]];
	
	if( ! [[self author] isEqualToString: @""] ){
		[displayedHTML appendFormat:@"<tr><td align=\"right\" valign=\"top\" class=\"feed_label\">Author:</td>"];
		[displayedHTML appendFormat:@"<td valign=\"top\" class=\"feed_header\"><a title=\"Send email to %@\" href=\"mailto:%@\">%@</a></td></tr>", [self author], [self author], [self author]];
	}
	
	if( ! [[self category] isEqualToString: @""] ){
		[displayedHTML appendFormat:@"<tr><td align=\"right\" valign=\"top\" class=\"feed_label\">Category:</td>"];
		[displayedHTML appendFormat:@"<td valign=\"top\" class=\"feed_header\">%@</td></tr>", [self category]];
	}
	
	if( ! [[self torrent] isEqualToString: @""] ){
		NSMutableString *			torrentURL = [NSMutableString stringWithString: [self torrent]];
		
		if( [PREFS useTorrentScheme] ){
			[torrentURL replaceOccurrencesOfString:@"http://" withString:@"torrent://" options: NSCaseInsensitiveSearch range:NSMakeRange(0,[torrentURL length])];
		}
		[displayedHTML appendFormat:@"<tr><td align=\"right\" valign=\"top\" class=\"feed_label\">Torrent:</td>"];
		[displayedHTML appendFormat:@"<td valign=\"top\" class=\"feed_header\"><a title=\"Download torrent file\" href=\"%@\">%@</a></td></tr>", torrentURL, torrentURL];
	}
	
	if( [self date] ){
		dateOutput = [[self date] naturalString];
	}
	if( ! [[self source] isEqualToString:@""] ){
		[displayedHTML appendFormat:@"<tr><td align=\"right\" valign=\"top\" class=\"feed_label\">Source:</td>"];
		if( [[self sourceURL] isEqualToString:@""] ){
			[displayedHTML appendFormat:@"<td valign=\"top\" class=\"feed_header\">%@</td></tr>", [self source]];
		}else{
			[displayedHTML appendFormat:@"<td valign=\"top\" class=\"feed_header\"><a href=\"%@\" title=\"Open source %@ in default browser\">%@</a></td></tr>",[self sourceURL], [self sourceURL], [self sourceURL], [self source]];
		}
	}
	[displayedHTML appendFormat:@"<tr><td align=\"right\" valign=\"top\" class=\"feed_label\">Date:</td>"];
	[displayedHTML appendFormat:@"<td valign=\"top\" class=\"feed_header\">%@</td></tr>", dateOutput];
	
	
	[displayedHTML appendFormat:@"</table>"];
	[displayedHTML appendFormat:@"<hr>"];
	[displayedHTML appendString: [self content]];
	[displayedHTML appendFormat:@"</body></html>"];
	
	//KNDebug(@"ARTICLE: finding cache location");
	//KNDebug(@"ARTICLE: cache for our feed is in: %@", [feed cacheLocation]);
	NSString *					cacheLocation = [[[feed cacheLocation] stringByAppendingPathComponent: uniqueKey] stringByAppendingPathExtension:@"html"];
	//KNDebug(@"ARTICLE: About to cache to %@", cacheLocation);
	if( cacheLocation ){
		BOOL					written = NO;
		NSError *				error;
		
		if( [displayedHTML respondsToSelector: @selector(writeToFile:atomically:encoding:error:)] ){
			written = [displayedHTML writeToFile: cacheLocation atomically: YES encoding: NSUTF8StringEncoding error:&error];
		}else{
			written = [displayedHTML writeToURL: [NSURL fileURLWithPath: cacheLocation] atomically: YES];
		}
		
		if( written ){
			[self setPreviewCachePath: cacheLocation];
		}else{
			KNDebug(@"ARTICLE: Unable to write preview cache to %@", cacheLocation);
		}
	}
}

-(void)deleteCache{
	NSFileManager *				fileManager = [NSFileManager defaultManager];
	
	KNDebug(@"ARTICLE: about to clear cache file");// %@", previewCachePath);
	if( previewCachePath ){
		//KNDebug(@"ARTICLE: attempting to delete file %@", previewCachePath);
		[fileManager removeFileAtPath: previewCachePath handler: nil];
	}
	[self setPreviewCachePath: nil];
}

-(void)invalidateCache:(NSNotification *)notification{
#pragma unused(notification)
	[self deleteCache];
}
@end
