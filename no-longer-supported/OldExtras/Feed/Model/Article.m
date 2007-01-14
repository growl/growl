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


-(void)dealloc{
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
		if( ! content ){ content = [NSString string]; }
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

-(Feed *)feed{
    return feed;
}

-(NSString *)key{
    return key;
}

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
        }
    }
}

-(BOOL)isOnServer{
	return isOnServer;
}

-(void)setIsOnServer:(BOOL)serverFlag{
	isOnServer = serverFlag;
}



@end
