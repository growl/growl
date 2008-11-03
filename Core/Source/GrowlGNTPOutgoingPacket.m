//
//  GrowlGNTPOutgoingPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlGNTPBinaryChunk.h"
#include <openssl/md5.h>

/* XXX For GNTPOutgoingItem which should probably move */
#import "GrowlTCPPathway.h"

@interface GrowlGNTPInitialHeaderItem : NSObject <GNTPOutgoingItem>
{
	NSString *action;
}
+ (GrowlGNTPInitialHeaderItem *)initialHeaderItemWithAction:(NSString *)action;
- (id)initWithAction:(NSString *)inAction;
@end


@implementation GrowlGNTPInitialHeaderItem
+ (GrowlGNTPInitialHeaderItem *)initialHeaderItemWithAction:(NSString *)action
{
	return [[[self alloc] initWithAction:action] autorelease];
}
- (id)initWithAction:(NSString *)inAction
{
	if ((self = [self init])) {
		action = [inAction retain];
	}
	
	return self;
}
- (void)dealloc
{
	[action release];
	[super dealloc];
}
- (NSData *)GNTPRepresentation
{
#define CRLF "\x0D\x0A"	
	return [[NSString stringWithFormat:@"GNTP/1.0 %@ NONE NONE" CRLF, action] dataUsingEncoding:NSUTF8StringEncoding];	
}
@end

@implementation GrowlGNTPOutgoingPacket
+ (GrowlGNTPOutgoingPacket *)outgoingPacket
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if ((self = [super init])) {
		headerItems = [[NSMutableArray alloc] init];
		binaryChunks = [[NSMutableArray alloc] init];

	}
	return self;
}

- (void)dealloc
{
	[headerItems release];
	[binaryChunks release];
	
	[super dealloc];
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

- (void)setAction:(NSString *)inAction
{
	[action autorelease];
	action = [inAction retain];
}
- (void)addHeaderItem:(GrowlGNTPHeaderItem *)inItem
{
	[headerItems addObject:inItem];
}
- (void)addHeaderItems:(NSArray *)inItems
{
	[headerItems addObjectsFromArray:inItems];
}
- (void)addBinaryData:(NSData *)inData withIdentifier:(NSString *)inIdentifier
{
	[binaryChunks addObject:[GrowlGNTPBinaryChunk chunkForData:inData withIdentifier:inIdentifier]];
}

- (NSArray *)outgoingItems
{
	NSMutableArray *allOutgoingItems = [NSMutableArray array];

	[allOutgoingItems addObject:[GrowlGNTPInitialHeaderItem initialHeaderItemWithAction:action]];
	[allOutgoingItems addObjectsFromArray:headerItems];

	if ([binaryChunks count]) {
		[allOutgoingItems addObject:[GrowlGNTPHeaderItem separatorHeaderItem]];
		[allOutgoingItems addObjectsFromArray:binaryChunks];
	}

	return allOutgoingItems;
}

- (void)writeToSocket:(AsyncSocket *)socket
{
	NSEnumerator *enumerator = [[self outgoingItems] objectEnumerator];
	id <GNTPOutgoingItem> item;
	while ((item = [enumerator nextObject])) {
		[socket writeData:[item GNTPRepresentation]
			  withTimeout:-1
					  tag:0];
	}
}

- (NSString *)description
{
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"<%@: %x: \"", NSStringFromClass([self class]), self];
	
	NSEnumerator *enumerator = [[self outgoingItems] objectEnumerator];
	NSObject<GNTPOutgoingItem> *item;

	while ((item = [enumerator nextObject])) {
		if ([item isKindOfClass:[GrowlGNTPBinaryChunk class]]) {
			[description appendFormat:@"Binary chunk %@, length %d\n",
			 [(GrowlGNTPBinaryChunk *)item identifier], [(GrowlGNTPBinaryChunk *)item length]];
		} else {
			[description appendString:[[[NSString alloc] initWithData:[item GNTPRepresentation]
															 encoding:NSUTF8StringEncoding] autorelease]];
		}
	}
	[description appendString:@"\">"];
		 
	return description;
}
@end
