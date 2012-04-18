//
//  GrowlGNTPBinaryChunk.m
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import "GrowlGNTPBinaryChunk.h"
#import "GCDAsyncSocket.h"
#import <CommonCrypto/CommonHMAC.h>

@interface  GrowlGNTPBinaryChunk (PRIVATE)
- (id)initWithData:(NSData *)inData identifier:(NSString *)inIdentifier;
@end

@implementation GrowlGNTPBinaryChunk
@synthesize data = _data;
@synthesize identifier = _identifier;

+ (GrowlGNTPBinaryChunk *)chunkForData:(NSData *)inData withIdentifier:(NSString *)inIdentifier
{
	return [[[self alloc] initWithData:inData identifier:inIdentifier] autorelease];
}

- (id)initWithData:(NSData *)inData identifier:(NSString *)inIdentifier
{
	if ((self = [self init])) {
		[self setData:inData];
		[self setIdentifier:inIdentifier];
	}
	
	return self;
}

- (void)dealloc
{
	[_data release];
	[_identifier release];

	[super dealloc];
}

- (NSUInteger)length
{
	return [_data length];
}

#define CRLF "\x0D\x0A"

- (NSString *) stringThatPrecedesTheData {
	NSMutableString *prologue = [NSMutableString string];
	[prologue appendFormat:@"Identifier: %@" CRLF, _identifier];
	[prologue appendFormat:@"Length: %lu" CRLF, [_data length]];
	[prologue appendString:@CRLF];
	return prologue;
}
- (NSString *) stringThatFollowsTheData {
	NSMutableString *postlogue = [NSMutableString string];
	[postlogue appendString:@CRLF]; /* End the data */
	[postlogue appendString:@CRLF]; /* Blank line after the chunk */
	return postlogue;
}

- (NSData *)GNTPRepresentation
{
	NSMutableData *gntpData = [NSMutableData data];
	[gntpData appendData:[[self stringThatPrecedesTheData] dataUsingEncoding:NSUTF8StringEncoding]];
	[gntpData appendData:_data];
	[gntpData appendData:[[self stringThatFollowsTheData] dataUsingEncoding:NSUTF8StringEncoding]];
	
	return gntpData;
}

- (NSString *) GNTPRepresentationAsString {
	NSMutableString *gntpString = [NSMutableString string];
	[gntpString appendString:[self stringThatPrecedesTheData]];
	[gntpString appendString:[_data description]];
	[gntpString appendString:[self stringThatFollowsTheData]];
	return gntpString;
}

+ (NSString *)identifierForBinaryData:(NSData *)data
{
	unsigned char *digest = malloc(sizeof(unsigned char)*CC_MD5_DIGEST_LENGTH);
    CC_MD5([data bytes], (unsigned int)[data length], digest);
	NSString *identifier = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
							digest[0], digest[1], 
							digest[2], digest[3],
							digest[4], digest[5],
							digest[6], digest[7],
							digest[8], digest[9],
							digest[10], digest[11],
							digest[12], digest[13],
							digest[14], digest[15]];
	free(digest);
	return identifier;	
}

@end
