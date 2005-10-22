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
#import "Feed.h"
#import "Article.h"
#import "FeedDelegate.h"
#import "FeedLibrary.h"
#import "Prefs.h"
#import "NSString+KNTruncate.h"
#import "KNUtility.h"

#define FeedSourceURLArchiveKey @"sourceurl"
#define FeedDescriptionArchiveKey @"description"

#define FeedDefaultIcon @"FeedDefault"

#define UNIQUEKEYLENGTH 20

@implementation Feed

-(void)dealloc{
	//KNDebug(@"FEED: dealloc");
    [source release];
    [title release];
	[userTitle release];
    [summary release];
    [link release];
    [type release];
	[image release];
    [icon release];
    [articles release];
	[uniqueKey release];
	[prefs release];
	
    [super dealloc];
}

-(id)initWithCoder:(NSCoder *)coder{
    self = [super init];
    if( self ){
		// These items haven't changed, so don't need special treatment
		title = [[coder decodeObjectForKey: FeedTitle] retain];
		link = [[coder decodeObjectForKey: FeedLink] retain];
        type = [[coder decodeObjectForKey: FeedType] retain];
		articles = [[coder decodeObjectForKey: FeedArticles] retain];
		
		source = [coder decodeObjectForKey: FeedSource];
		if( !source ){ source = [coder decodeObjectForKey: FeedSourceURLArchiveKey]; }
		if( !source ){ source = [NSString string]; }
		[source retain];
		
		summary = [coder decodeObjectForKey: FeedSummary];
		if( ! summary ){ summary = [coder decodeObjectForKey: FeedDescriptionArchiveKey]; }
		if( ! summary ){ summary = [NSString string]; }
		[summary retain];
		
		image = [[coder decodeObjectForKey: FeedImage] retain];
		if( [image class] == [NSImage class] ){
			icon = (NSImage *) image;
			image = [[NSString string] retain];
		}
		
		if( ! icon ){
			icon = [[coder decodeObjectForKey: FeedIcon] retain];
		}
		
		userTitle = [coder decodeObjectForKey: FeedUserTitle];
		if( ! userTitle ){
			userTitle = [NSString stringWithString: @""];
		}
		[userTitle retain];
		
		uniqueKey = [coder decodeObjectForKey: FeedUniqueKey];
		if( ! uniqueKey ){
			uniqueKey = KNUniqueKeyWithLength(UNIQUEKEYLENGTH);
		}
		[uniqueKey retain];
		
		prefs = [coder decodeObjectForKey: FeedPrefsKey];
		if( ! prefs ){
			prefs = [NSMutableDictionary dictionary];
		}
		[prefs retain];
		
		error = nil;
	}
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder{
    [coder encodeObject: source forKey: FeedSource];
    [coder encodeObject: title forKey: FeedTitle];
	[coder encodeObject: userTitle forKey: FeedUserTitle];
    [coder encodeObject: summary forKey: FeedSummary];
    [coder encodeObject: link forKey: FeedLink];
    [coder encodeObject: type forKey: FeedType];
	[coder encodeObject: image forKey: FeedImage];
	[coder encodeObject: icon forKey: FeedIcon];
    [coder encodeObject: articles forKey: FeedArticles];
	[coder encodeObject: uniqueKey forKey: FeedUniqueKey];
	[coder encodeObject: prefs forKey: FeedPrefsKey];
}

-(NSString *)description{
	return( [NSString stringWithFormat:@"%@{%@: %@ - %d Articles}", [super description], [self type], [self title], [articles count]] );
}

#pragma mark -
#pragma mark Accessors

-(NSString *)source{
    return source;
}

-(NSString *)title{
    return title;
}

-(NSString *)userTitle{
	return userTitle;
}

-(NSString *)summary{
    return summary;
}

-(NSString *)link{
    return link;
}

-(NSString *)type{
    return type;
}

-(NSString *)image{
	return image;
}

-(NSImage *)icon{
	return icon;
}

-(NSArray *)articles{
	return articles;
}

-(NSString *)error{
	return error;
}

-(id)valueForKeyPath:(NSString *)keyPath{
	id				value = [super valueForKeyPath: keyPath];
	
	if( ! value ){
		if( [keyPath isEqualToString: @"prefs.updateLength"] ){
			value = [NSNumber numberWithDouble: [PREFS updateLength]];
		}else if( [keyPath isEqualToString:@"prefs.updateUnits"] ){
			value = [NSNumber numberWithDouble: [PREFS updateUnits]];
		}else if( [keyPath isEqualToString:@"prefs.expireInterval"] ){
			value = [NSNumber numberWithDouble: [PREFS articleExpireInterval]];
		}else if( [keyPath isEqualToString:@"prefs.wantsUpdate"] ){
			NSTimeInterval			delay = [[self valueForKeyPath:@"prefs.updateLength"] doubleValue] * [[self valueForKeyPath:@"prefs.updateUnits"] doubleValue];
			value = [NSNumber numberWithBool: ((delay + [[self valueForKeyPath:@"prefs.lastUpdate"] timeIntervalSinceNow]) <= 0)];
		}
	}
	return value;
}

@end
