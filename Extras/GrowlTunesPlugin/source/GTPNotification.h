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
	
	NSData *_artwork;
	
	BOOL _state;
}

+ (id)notification;
- (void)setVisualPluginData:(VisualPluginData*)data;

- (NSString*)replacements:(NSString*)string;

@property (assign) NSString *titleFormat;
@property (assign) NSString *descriptionFormat;

@property (assign) NSString *track;
@property (assign) NSString *title;

@property (assign) NSString *artist;
@property (assign) NSString *album;
@property (assign) NSString *genre;

@property (assign) NSString *disc;
@property (assign) NSString *composer;
@property (assign) NSString *year;

@property (assign) NSString *rating;
@property (assign) NSString *length;
@property (assign) NSData	*artwork;

@property (assign) BOOL state;
@end
