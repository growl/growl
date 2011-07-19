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

- (NSData *)GNTPRepresentation
{
	NSMutableData *gntpData = [NSMutableData data];
	NSMutableString *rep = [NSMutableString string];
	[rep appendFormat:@"Identifier: %@" CRLF, _identifier];
	[rep appendFormat:@"Length: %lu" CRLF, [_data length]];
	[rep appendString:@CRLF];
	
	[gntpData appendData:[rep dataUsingEncoding:NSUTF8StringEncoding]];
	[gntpData appendData:_data];
	[gntpData appendData:[GCDAsyncSocket CRLFData]]; /* End the data */
	[gntpData appendData:[GCDAsyncSocket CRLFData]]; /* Blank line after the chunk */
	
	return gntpData;
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
