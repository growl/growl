//
//  FormattingToken.m
//  GrowlTunes
//
//  Created by Travis Tilley on 11/27/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "FormattingToken.h"
#import "macros.h"


@interface FormattingToken ()
@property(readwrite, nonatomic, assign) BOOL isDynamic;
@property(readwrite, nonatomic, copy) NSString* editingString;
@end


@implementation FormattingToken

@synthesize isDynamic = _isDynamic;

+(NSDictionary*)tokenMap
{
    static __strong NSDictionary* tokenMap;
    if (!tokenMap) {
        tokenMap = $dict(TokenAlbum,            TokenAlbumReadable, 
                         TokenAlbumArtist,      TokenAlbumArtistReadable, 
                         TokenArtist,           TokenArtistReadable, 
                         TokenBestArtist,       TokenBestArtistReadable, 
                         TokenBestDescription,  TokenBestDescriptionReadable, 
                         TokenComment,          TokenCommentReadable, 
                         TokenDescription,      TokenDescriptionReadable, 
                         TokenEpisodeID,        TokenEpisodeIDReadable, 
                         TokenEpisodeNumber,    TokenEpisodeNumberReadable, 
                         TokenLongDescription,  TokenLongDescriptionReadable, 
                         TokenName,             TokenNameReadable, 
                         TokenSeasonNumber,     TokenSeasonNumberReadable, 
                         TokenShow,             TokenShowReadable, 
                         TokenStreamTitle,      TokenStreamTitleReadable, 
                         TokenTrackCount,       TokenTrackCountReadable, 
                         TokenTrackNumber,      TokenTrackNumberReadable, 
                         TokenTime,             TokenTimeReadable, 
                         TokenVideoKindName,    TokenVideoKindNameReadable);
    }
    return tokenMap;
}

-(id)initWithEditingString:(NSString *)editingString
{
    self = [super init];
    self.editingString = editingString;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    if ([encoder allowsKeyedCoding]) {
        [encoder encodeObject:self.editingString forKey:@"editingString"];
    } else {
        [encoder encodeObject:self.editingString];
    }
}

-(id)initWithCoder:(NSCoder *)decoder
{
    NSString* editingString;
    
    if ([decoder allowsKeyedCoding]) {
        editingString = [decoder decodeObjectForKey:@"editingString"];
    } else {
        editingString = [decoder decodeObject];
    }
    
    return [self initWithEditingString:editingString];
}

-(void)setEditingString:(NSString *)editingString
{
    _editingString = [editingString copy];
    if ([_editingString hasPrefix:@"["] && [_editingString hasSuffix:@"]"]) {
        self.isDynamic = YES;
    } else {
        self.isDynamic = NO;
    }
}

-(NSString*)editingString
{
    return [_editingString copy];
}

-(NSString*)lookupKey
{
    if (self.isDynamic) {
        NSCharacterSet* removeSet = [NSCharacterSet characterSetWithCharactersInString:@"[]"];
        return [self.editingString stringByTrimmingCharactersInSet:removeSet];
    } else {
        return nil;
    }
}

-(NSTokenStyle)tokenStyle
{
    return _isDynamic ? NSRoundedTokenStyle : NSPlainTextTokenStyle;
}

-(NSString*)displayString
{
    NSString* displayString;
    
    if (self.isDynamic) {
        displayString = [[[self class] tokenMap] valueForKey:[self lookupKey]];
        if (!displayString || [displayString length] == 0) {
            displayString = [self.editingString copy];
        }
    } else {
        displayString = [self.editingString copy];
    }
    
    return displayString;
}

@end
