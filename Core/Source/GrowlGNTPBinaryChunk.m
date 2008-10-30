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

@end
