//
//  GTPNotification.h
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>
#import "GTPCommon.h"

@interface GTPNotification : NSObject 
{
	NSString *_titleFormat;
	NSString *_descriptionFormat;
		
	NSString *_track;
	NSString *_title;
	NSString *_artist;
	NSString *_album;
	NSString *_genre;
	NSString *_disc;
	NSString *_composer;
	NSString *_year;
	NSString *_rating;
	NSString *_length;
	
	
	NSString *_streamTitle;
	NSString *_streamURL;
	NSString *_streamMessage;
	
	NSData *_artwork;
	
	BOOL _compilation;
	BOOL _state;
}

+ (id)notification;
- (void)setVisualPluginData:(VisualPluginData*)data;

- (NSString*)replacements:(NSString*)string;

- (NSDictionary*)dictionary;

@property (retain) NSString *titleFormat;
@property (retain) NSString *descriptionFormat;

@property (retain) NSString *track;
@property (retain) NSString *title;

@property (retain) NSString *artist;
@property (retain) NSString *album;
@property (retain) NSString *genre;

@property (retain) NSString *disc;
@property (retain) NSString *composer;
@property (retain) NSString *year;

@property (retain) NSString *rating;
@property (retain) NSString *length;
@property (retain) NSData	*artwork;

@property (retain) NSString *streamTitle;
@property (retain) NSString *streamURL;
@property (retain) NSString *streamMessage;

@property (assign) BOOL state;
@property (assign) BOOL compilation;
@end
