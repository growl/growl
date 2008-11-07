//
//  GrowlGNTPOutgoingPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlNotificationGNTPPacket.h"
#import "GrowlRegisterGNTPPacket.h"
#import "GrowlGNTPBinaryChunk.h"

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

@interface GrowlGNTPEndHeaderItem : NSObject <GNTPOutgoingItem> {};
+ (GrowlGNTPEndHeaderItem *)endHeaderItem;
@end

@implementation GrowlGNTPEndHeaderItem
+ (GrowlGNTPEndHeaderItem *)endHeaderItem
{
	return [[[self alloc] init] autorelease];
}
- (NSData *)GNTPRepresentation
{
#define CRLF "\x0D\x0A"	
	return [[NSString stringWithFormat:@"GNTP/1.0 END" CRLF CRLF] dataUsingEncoding:NSUTF8StringEncoding];	
}
@end

@interface GrowlGNTPOutgoingPacket (PRIVATE)
- (void)setPacketID:(NSString *)string;
@end

@implementation GrowlGNTPOutgoingPacket
+ (GrowlGNTPOutgoingPacket *)outgoingPacket
{
	return [[[self alloc] init] autorelease];
}

+ (GrowlGNTPOutgoingPacket *)outgoingPacketOfType:(GrowlGNTPOutgoingPacketType)type forDict:(NSDictionary *)dict
{
	GrowlGNTPOutgoingPacket *outgoingPacket = [self outgoingPacket];
	
	NSArray *headersArray = nil;
	NSArray *binaryArray = nil;
		
	switch (type) {
		case GrowlGNTPOutgoingPacket_OtherType:
			NSLog(@"This shouldn't happen; outgoingPacketOfType called with GrowlGNTPOutgoingPacket_OtherType");
			break;
		case GrowlGNTPOutgoingPacket_NotifyType:
		{
			NSString *notificationID = nil;
			[outgoingPacket setAction:@"NOTIFY"];	
			[GrowlNotificationGNTPPacket getHeaders:&headersArray
									   binaryChunks:&binaryArray
									 notificationID:&notificationID
								forNotificationDict:dict];
			[outgoingPacket setPacketID:notificationID];
			NSLog(@"I set %@'s packet ID to %@ (%@)", outgoingPacket, notificationID, [dict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]);
			break;
		}
		case GrowlGNTPOutgoingPacket_RegisterType:
		{
			[outgoingPacket setAction:@"REGISTER"];				
			[GrowlRegisterGNTPPacket getHeaders:&headersArray andBinaryChunks:&binaryArray forRegistrationDict:dict];
			break;
		}		
	}

	[outgoingPacket addHeaderItems:headersArray];
	[outgoingPacket addBinaryChunks:binaryArray];
	
	return outgoingPacket;
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
	[packetID release];

	[super dealloc];
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
- (void)addBinaryChunk:(GrowlGNTPBinaryChunk *)inChunk
{
	[binaryChunks addObject:inChunk];	
}
- (void)addBinaryChunks:(NSArray *)inItems
{
	[binaryChunks addObjectsFromArray:inItems];
}

- (NSString *)packetID
{
	if (!packetID) {
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
		packetID = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		CFRelease(uuidRef);
	}
	return packetID;	
}

- (void)setPacketID:(NSString *)string
{
	if (string != packetID) {
		[packetID release];
		packetID = [string retain];
	}
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
	[allOutgoingItems addObject:[GrowlGNTPHeaderItem separatorHeaderItem]];
	[allOutgoingItems addObject:[GrowlGNTPEndHeaderItem endHeaderItem]];

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

- (BOOL)needsPersistentConnectionForCallback
{
	return ([GrowlNotificationGNTPPacket callbackResultSendBehaviorForHeaders:headerItems] == GrowlGNTP_TCPCallback);
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
