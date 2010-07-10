//
//  GTPNotification.m
//  GrowlTunes
//
//  Created by Rudy Richter on 9/27/09.
//  Copyright 2009 The Growl Project. All rights reserved.
//

#import "GTPNotification.h"
#import "NSWorkspaceAdditions.h"
#import "GTPController.h"

@interface GTPNotification (Star_Formatting)
- (NSString *) starsForRating:(NSNumber *)aRating withStarCharacter:(unichar)star;
- (NSString *) starsForRating:(NSNumber *)aRating withStarString:(NSString *)star;
- (NSString *) starsForRating:(NSNumber *)rating;
@end	

@interface NSString (GrowlTunesMultiplicationAdditions)
- (NSString *)stringByMultiplyingBy:(NSUInteger)multi;
@end

@implementation GTPNotification

@synthesize titleFormat = _titleFormat;
@synthesize descriptionFormat = _descriptionFormat;
@synthesize track = _track;
@synthesize title = _title;
@synthesize artist = _artist;
@synthesize album = _album;
@synthesize genre = _genre;
@synthesize disc = _disc;
@synthesize composer = _composer;
@synthesize year = _year;
@synthesize rating = _rating;
@synthesize length = _length;
@synthesize artwork = _artwork;
@synthesize state = _state;
@synthesize compilation = _compilation;

@synthesize streamTitle = _streamTitle;
@synthesize streamURL =	_streamURL;
@synthesize streamMessage = _streamMessage;

+ (id)notification
{
	return [[[GTPNotification alloc] init] autorelease];
}

- (void)setVisualPluginData:(VisualPluginData*)data
{
	if(data->trackInfo.validFields & kITTITrackNumberFieldsMask)
		[self setTrack:[NSString stringWithFormat:@"%ld", data->trackInfo.trackNumber]];
	else
		[self setTrack:@""];

	if(data->trackInfo.validFields & kITTINameFieldMask)
		[self setTitle:[NSString stringWithCharacters:&data->trackInfo.name[1] length:data->trackInfo.name[0]]];
	else
		[self setTitle:@""];
	
	if(data->trackInfo.validFields & kITTIArtistFieldMask)
		[self setArtist:[NSString stringWithCharacters:&data->trackInfo.artist[1] length:data->trackInfo.artist[0]]];
	else
		[self setArtist:@""];

	if(data->trackInfo.validFields & kITTIAlbumFieldMask)
		[self setAlbum:[NSString stringWithCharacters:&data->trackInfo.album[1] length:data->trackInfo.album[0]]];
	else
		[self setAlbum:@""];
	
	if(data->trackInfo.validFields &  kITTIGenreFieldMask)
		[self setGenre:[NSString stringWithCharacters:&data->trackInfo.genre[1] length:data->trackInfo.genre[0]]];
	else
		[self setGenre:@""];
	
	if(data->trackInfo.validFields &  kITTIDiscNumberFieldsMask)
		[self setDisc:[NSString stringWithFormat:@"%ld", data->trackInfo.discNumber]];
	else
		[self setDisc:@""];
	
	if(data->trackInfo.validFields &  kITTIComposerFieldMask)
		[self setComposer:[NSString stringWithCharacters:&data->trackInfo.composer[1] length:data->trackInfo.composer[0]]];
	else
		[self setComposer:@""];
	
	if(data->trackInfo.validFields &  kITTIYearFieldMask)
		[self setYear:[NSString stringWithFormat:@"%ld", data->trackInfo.year]];
	else
		[self setYear:@""];
	
	if(data->trackInfo.validFields &  kITTITotalTimeFieldMask)
		[self setRating:[self starsForRating:[NSNumber numberWithInteger:data->trackInfo.trackRating]]];
	else
		[self setRating:[self starsForRating:[NSNumber numberWithInteger:0]]];
	
	if(data->trackInfo.validFields & kITTICompilationFieldMask)
		[self setCompilation:data->trackInfo.isCompilationTrack];
	else
		[self setCompilation:NO];

	if(data->trackInfo.validFields &  kITTITotalTimeFieldMask)
	{
		NSInteger minutes = data->trackInfo.totalTimeInMS / 1000 / 60;
		NSInteger seconds = data->trackInfo.totalTimeInMS / 1000 - minutes * 60;
		[self setLength:[NSString stringWithFormat:@"%ld:%02ld", minutes, seconds]];
	}
	else
		[self setLength:@"0:00"];
		
	if(data->streamInfo.version)
	{
		if(data->streamInfo.streamTitle)
			[self setStreamTitle:[NSString stringWithCharacters:&data->streamInfo.streamTitle[1] length:data->streamInfo.streamTitle[0]]];
		else
			[self setStreamTitle:nil];
		
		if(data->streamInfo.streamURL)
			[self setStreamURL:[NSString stringWithCharacters:&data->streamInfo.streamURL[1] length:data->streamInfo.streamURL[0]]];
		else
			[self setStreamURL:nil];

		if(data->streamInfo.streamMessage)
			[self setStreamMessage:[NSString stringWithCharacters:&data->streamInfo.streamMessage[1] length:data->streamInfo.streamMessage[0]]];
		else
			[self setStreamMessage:nil];
		NSLog(@"%@ %@ %@", [self streamTitle], [self streamURL], [self streamMessage]);
	}
	else 
	{
		[self setStreamTitle:nil];
		[self setStreamURL:nil];
		[self setStreamMessage:nil];
	}

	//Get cover art
	Handle coverArt = NULL;
	OSType format;
	uint32_t err = noErr;
	
	err = PlayerGetCurrentTrackCoverArt(data->appCookie, data->appProc, &coverArt, &format);
	if((err == noErr) && coverArt)
		[self setArtwork:[NSData dataWithBytes:*coverArt length:GetHandleSize(coverArt)]];
	else
		[[GTPController sharedInstance] artworkForTitle:[self title] byArtist:[self artist] onAlbum:[self album] composedBy:[self composer] isCompilation:[self compilation]];
		 
		 if(![self artwork])
		 [self setArtwork:[[[NSWorkspace sharedWorkspace] iconForApplication:@"iTunes"] TIFFRepresentation]];
		 
		 if (coverArt)
		 DisposeHandle(coverArt);
		 
}

- (NSString*)replacements:(NSString*)string
{
	NSString *result = string;
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[0]] withString:[self track]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[1]] withString:[self title]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[2]] withString:[self artist]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[3]] withString:[self album]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[4]] withString:[self genre]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[5]] withString:[self disc]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[6]] withString:[self composer]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[7]] withString:[self year]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[8]] withString:[self rating]];
	result = [result stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<<%@>>",tokenTitles[9]] withString:[self length]];
	result = [result stringByReplacingOccurrencesOfString:@"<<streamTitle>>" withString:[self streamTitle]];
	result = [result stringByReplacingOccurrencesOfString:@"<<streamURL>>" withString:[self streamURL]];
	result = [result stringByReplacingOccurrencesOfString:@"<<streamMessage>>" withString:[self streamMessage]];
	return result;
}

- (NSString*)titleString
{
	NSString *result = nil;

	if([[self streamTitle] length] || [[self streamURL] length] || [[self streamMessage] length])
		result = [NSString stringWithFormat:@"<<%@>>", tokenTitles[1]];
	else
		result = [[[self titleFormat] copy] autorelease];
		
	result = [self replacements:result];
	
	return result;
}

- (NSString*)descriptionString
{
	NSString *result = nil;
	
	if([[self streamTitle] length] || [[self streamURL] length] || [[self streamMessage] length])
		result = [NSString stringWithFormat:@"<<%@>>\n<<%@>>\n<<%@>>", @"streamTitle", @"streamMessage", tokenTitles[4]];
	else
		result = [[[self descriptionFormat] copy] autorelease];
	
	result = [self replacements:result];
	return result;
}

- (NSDictionary*)dictionary
{
	NSMutableDictionary *result = [NSMutableDictionary dictionary];
	[result setValue:ITUNES_PLAYING forKey:GROWL_NOTIFICATION_NAME];
	[result setValue:APP_NAME forKey:GROWL_APP_NAME];
	[result setValue:[self titleString] forKey:GROWL_NOTIFICATION_TITLE];
	[result setValue:[self descriptionString] forKey:GROWL_NOTIFICATION_DESCRIPTION];
	[result setValue:APP_NAME forKey:GROWL_NOTIFICATION_IDENTIFIER];
	[result setValue:[self artwork] forKey:GROWL_NOTIFICATION_ICON_DATA];
	 
	return result;
}

@end

@implementation GTPNotification (Star_Formatting)

- (NSString *) starsForRating:(NSNumber *)aRating withStarCharacter:(unichar)star {
	int rating = aRating ? [aRating intValue] : 0;
	
	enum {
		BLACK_STAR  = 0x272F, SPACE          = 0x0020, MIDDLE_DOT   = 0x00B7,
		ONE_HALF    = 0x00BD,
		ONE_QUARTER = 0x00BC, THREE_QUARTERS = 0x00BE,
		ONE_THIRD   = 0x2153, TWO_THIRDS     = 0x2154,
		ONE_FIFTH   = 0x2155, TWO_FIFTHS     = 0x2156, THREE_FIFTHS = 0x2157, FOUR_FIFTHS   = 0x2158,
		ONE_SIXTH   = 0x2159, FIVE_SIXTHS    = 0x215a,
		ONE_EIGHTH  = 0x215b, THREE_EIGHTHS  = 0x215c, FIVE_EIGHTHS = 0x215d, SEVEN_EIGHTHS = 0x215e,
		
		//rating <= 0: dot, space, dot, space, dot, space, dot, space, dot (five dots).
		//higher ratings mean fewer characters. rating >= 100: five black stars.
		numChars = 9,
	};
	
	static unichar fractionChars[] = {
		/*0/20*/ 0,
		/*1/20*/ ONE_FIFTH, TWO_FIFTHS, THREE_FIFTHS,
		/*4/20 = 1/5*/ ONE_FIFTH,
		/*5/20 = 1/4*/ ONE_QUARTER,
		/*6/20*/ ONE_THIRD, FIVE_EIGHTHS,
		/*8/20 = 2/5*/ TWO_FIFTHS, TWO_FIFTHS,
		/*10/20 = 1/2*/ ONE_HALF, ONE_HALF,
		/*12/20 = 3/5*/ THREE_FIFTHS,
		/*13/20 = 0.65; 5/8 = 0.625*/ FIVE_EIGHTHS,
		/*14/20 = 7/10*/ FIVE_EIGHTHS, //highly approximate, of course, but it's as close as I could get :)
		/*15/20 = 3/4*/ THREE_QUARTERS,
		/*16/20 = 4/5*/ FOUR_FIFTHS, FOUR_FIFTHS,
		/*18/20 = 9/10*/ SEVEN_EIGHTHS, SEVEN_EIGHTHS, //another approximation
	};
	
	unichar starBuffer[numChars];
	int     wholeStarRequirement = 20;
	unsigned starsRemaining = 5U;
	unsigned i = 0U;
	for (; starsRemaining--; ++i) {
		if (rating >= wholeStarRequirement) {
			starBuffer[i] = star;
			rating -= 20;
		} else {
			/*examples:
			 *if the original rating is 95, then rating = 15, and we get 3/4.
			 *if the original rating is 80, then rating = 0,  and we get MIDDLE DOT.
			 */
			starBuffer[i] = fractionChars[rating];
			if (!starBuffer[i]) {
				//add a space if this isn't the first 'star'.
				if (i) starBuffer[i++] = SPACE;
				starBuffer[i] = MIDDLE_DOT;
			}
			rating = 0; //ensure that remaining characters are MIDDLE DOT.
		}
	}
	
	return [NSString stringWithCharacters:starBuffer length:i];
}

- (NSString *) starsForRating:(NSNumber *)aRating withStarString:(NSString *)star {
	if (!star)
		star = [[NSUserDefaults standardUserDefaults] stringForKey:@"Substitute for BLACK STAR"];
	
	enum {
		BLACK_STAR  = 0x2605, PINWHEEL_STAR  = 0x272F,
		SPACE       = 0x0020, MIDDLE_DOT	 = 0x00B7,
		ONE_HALF    = 0x00BD,
		ONE_QUARTER = 0x00BC, THREE_QUARTERS = 0x00BE,
		ONE_THIRD   = 0x2153, TWO_THIRDS     = 0x2154,
		ONE_FIFTH   = 0x2155, TWO_FIFTHS     = 0x2156, THREE_FIFTHS = 0x2157, FOUR_FIFTHS   = 0x2158,
		ONE_SIXTH   = 0x2159, FIVE_SIXTHS    = 0x215a,
		ONE_EIGHTH  = 0x215b, THREE_EIGHTHS  = 0x215c, FIVE_EIGHTHS = 0x215d, SEVEN_EIGHTHS = 0x215e,
	};
	
	unsigned starLength = [star length];
	if( (!star) || (starLength == 0U))
		return [self starsForRating:aRating withStarCharacter:(floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3_5) ? PINWHEEL_STAR : BLACK_STAR];
	else if (starLength == 1U)
		return [self starsForRating:aRating withStarCharacter:[star characterAtIndex:0U]];
	else {
		int rating = aRating ? [aRating intValue] : 0;
		//invert.
		int ratingInv = 100 - rating;
		
		int numStars = rating / 20;
		int numDots = ratingInv / 20;
		unsigned fractionIndex = ratingInv % 20;
		
		static unichar fractionChars[] = {
			/*0/20*/ 0,
			/*1/20*/ ONE_FIFTH, TWO_FIFTHS, THREE_FIFTHS,
			/*4/20 = 1/5*/ ONE_FIFTH,
			/*5/20 = 1/4*/ ONE_QUARTER,
			/*6/20*/ ONE_THIRD, FIVE_EIGHTHS,
			/*8/20 = 2/5*/ TWO_FIFTHS, TWO_FIFTHS,
			/*10/20 = 1/2*/ ONE_HALF, ONE_HALF,
			/*12/20 = 3/5*/ THREE_FIFTHS,
			/*13/20 = 0.65; 5/8 = 0.625*/ FIVE_EIGHTHS,
			/*14/20 = 7/10*/ FIVE_EIGHTHS, //highly approximate, of course, but it's as close as I could get :)
			/*15/20 = 3/4*/ THREE_QUARTERS,
			/*16/20 = 4/5*/ FOUR_FIFTHS, FOUR_FIFTHS,
			/*18/20 = 9/10*/ SEVEN_EIGHTHS, SEVEN_EIGHTHS, //another approximation
		};
		
		unichar *buf = alloca(sizeof(unichar) * ((numDots * 2) - (!rating) + (fractionIndex > 0)));
		unsigned i = 0U;
		if (fractionIndex > 0)
			buf[i++] = fractionChars[fractionIndex];
		
		//place first dot without a leading space.
		if ((!rating) && numDots) {
			buf[i++] = MIDDLE_DOT;
			--numDots;
		}
		
		while(numDots--) {
			buf[i++] = SPACE;
			buf[i++] = MIDDLE_DOT;
		}
		
		//place first star without a leading space.
		NSString *firstStar = nil;
		if ((starLength > 1U) && ([star characterAtIndex:0U] == SPACE)) {
			NSRange range = { 1U, starLength - 1U };
			firstStar = [star substringWithRange:range];
		}
		
		NSString *stars = (numStars && firstStar) ? [firstStar stringByAppendingString:[star stringByMultiplyingBy:numStars - 1]] : [star stringByMultiplyingBy:numStars];
		NSString *dots = [[NSString alloc] initWithCharacters:buf length:i];
		NSString *ratingString = [stars stringByAppendingString:dots];
		[dots release];
		
		return ratingString;
	}
}

- (NSString *) starsForRating:(NSNumber *)rating {
	return [self starsForRating:rating withStarString:nil];
}
@end

@implementation NSString (GrowlTunesMultiplicationAdditions)

- (NSString *)stringByMultiplyingBy:(NSUInteger)multi {
	NSUInteger length = [self length];
	NSUInteger length_multi = length * multi;
	
	unichar *buf = malloc(sizeof(unichar) * length_multi);
	if (!buf)
		return nil;
	
	for (NSUInteger i = 0UL; i < multi; ++i)
		[self getCharacters:&buf[length * i]];
	
	NSString *result = [NSString stringWithCharacters:buf length:length_multi];
	free(buf);
	return result;
}

@end
