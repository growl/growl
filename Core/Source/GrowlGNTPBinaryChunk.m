//
//  GrowlGNTPBinaryChunk.m
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlGNTPBinaryChunk.h"
#import "AsyncSocket.h"

@interface  GrowlGNTPBinaryChunk (PRIVATE)
- (id)initWithData:(NSData *)inData identifier:(NSString *)inIdentifier;
@end

@implementation GrowlGNTPBinaryChunk
+ (GrowlGNTPBinaryChunk *)chunkForData:(NSData *)inData withIdentifier:(NSString *)inIdentifier
{
	return [[[self alloc] initWithData:inData identifier:inIdentifier] autorelease];
}

- (id)initWithData:(NSData *)inData identifier:(NSString *)inIdentifier
{
	if ((self = [self init])) {
		data = [inData retain];
		identifier = [inIdentifier retain];
	}
	
	return self;
}

- (void)dealloc
{
	[data release];
	[identifier release];

	[super dealloc];
}

- (NSString *)identifier
{
	return identifier;
}

- (unsigned int)length
{
	return [data length];
}

#define CRLF "\x0D\x0A"

- (NSData *)GNTPRepresentation
{
	NSMutableData *gntpData = [NSMutableData data];
	NSMutableString *rep = [NSMutableString string];
	[rep appendFormat:@"Identifier: %@" CRLF, identifier];
	[rep appendFormat:@"Length: %d" CRLF, [data length]];
	[rep appendString:@CRLF];
	
	[gntpData appendData:[rep dataUsingEncoding:NSUTF8StringEncoding]];
	[gntpData appendData:data];
	[gntpData appendData:[AsyncSocket CRLFData]]; /* End the data */
	[gntpData appendData:[AsyncSocket CRLFData]]; /* Blank line after the chunk */
	
	return gntpData;
}

+ (NSString *)identifierForBinaryData:(NSData *)data
{
	unsigned char *digest = MD5([data bytes], [data length], NULL);	
	NSString *identifier = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
							digest[0], digest[1], 
							digest[2], digest[3],
							digest[4], digest[5],
							digest[6], digest[7],
							digest[8], digest[9],
							digest[10], digest[11],
							digest[12], digest[13],
							digest[14], digest[15]];
	return identifier;	
}

@end
