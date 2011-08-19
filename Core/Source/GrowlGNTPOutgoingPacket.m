//
//  GrowlGNTPOutgoingPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlNotificationGNTPPacket.h"
#import "GrowlRegisterGNTPPacket.h"
#import "GrowlGNTPBinaryChunk.h"
#import "GrowlGNTPEncryptedHeaders.h"

/* XXX For GNTPOutgoingItem which should probably move */
#import "GrowlTCPPathway.h"

#import "GrowlDefines.h"
#import "GrowlNotification.h"

@interface GrowlGNTPInitialHeaderItem : NSObject <GNTPOutgoingItem>
{
	NSString *mAction;
	NSString *mEncryption;
	NSString *mKey;
}
+ (GrowlGNTPInitialHeaderItem *)initialHeaderItemWithAction:(NSString *)action;
- (id)initWithAction:(NSString *)inAction;

@property (retain) NSString *action;
@property (retain) NSString *encryption;
@property (retain) NSString *key;

@end

@implementation GrowlGNTPInitialHeaderItem
@synthesize action = mAction;
@synthesize encryption = mEncryption;
@synthesize key = mKey;

+ (GrowlGNTPInitialHeaderItem *)initialHeaderItemWithAction:(NSString *)action
{
	return [[[self alloc] initWithAction:action] autorelease];
}

- (id)initWithAction:(NSString *)inAction
{
	if ((self = [self init])) {
		mAction = [inAction retain];
		mEncryption = GrowlGNTPNone;
		mKey = GrowlGNTPNone;
	}
	
	return self;
}
- (void)dealloc
{
	[mAction release];
	[super dealloc];
}
- (NSString *)GNTPRepresentationAsString
{
#define CRLF "\x0D\x0A"	
	NSString *result = nil;
	result = [NSString stringWithFormat:@"GNTP/1.0 %@ %@", [self action], [self encryption]];
	if([[self key] caseInsensitiveCompare:GrowlGNTPNone] != NSOrderedSame)
		result = [result stringByAppendingFormat:@" %@", [self key]];
	result = [result stringByAppendingFormat:@"" CRLF];
	return result;
}
- (NSData *)GNTPRepresentation
{
	return [[self GNTPRepresentationAsString] dataUsingEncoding:NSUTF8StringEncoding];	
}
@end

@interface GrowlGNTPEndHeaderItem : NSObject <GNTPOutgoingItem> 
{
	NSInteger _connectionType;
}

+ (GrowlGNTPEndHeaderItem *)endHeaderItem;
@property (assign) NSInteger connectionType;
@end

@implementation GrowlGNTPEndHeaderItem
@synthesize connectionType = _connectionType;

+ (GrowlGNTPEndHeaderItem *)endHeaderItem
{
	return [[[self alloc] init] autorelease];
}

- (id)init
{
	if((self = [super init]))
	{
		_connectionType = GrowlGNTP_Close;
	}
	return self;
}
- (NSString *)GNTPRepresentationAsString
{
#define CRLF "\x0D\x0A"
	NSString *result = nil;
	switch ([self connectionType]) {
		case GrowlGNTP_KeepAlive:
			result = [NSString stringWithFormat:@"GNTP/1.0 END" CRLF CRLF];
			break;
		case GrowlGNTP_Close:
		default:
			result = [NSString stringWithFormat:@"%s%s", CRLF, CRLF];
			break;
	}
	return result;
}
- (NSData *)GNTPRepresentation
{
	return [[self GNTPRepresentationAsString] dataUsingEncoding:NSUTF8StringEncoding]; 	
}
@end

@interface GrowlGNTPOutgoingPacket (PRIVATE)
- (void)setPacketID:(NSString *)string;
@end

@implementation GrowlGNTPOutgoingPacket
@synthesize action = mAction;
@synthesize key = mKey;

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
			NSMutableDictionary *dictionary = [[dict mutableCopy] autorelease];
			[dictionary removeObjectForKey:@"ApplicationIcon"];
			[dictionary removeObjectForKey:@"NotificationIcon"];
			[outgoingPacket setAction:GrowlGNTPNotificationMessageType];	
			[GrowlNotificationGNTPPacket getHeaders:&headersArray
									   binaryChunks:&binaryArray
									 notificationID:&notificationID
								forNotificationDict:dict];
			[outgoingPacket setPacketID:notificationID];
			//NSLog(@"I set %@'s packet ID to %@ (%@)", outgoingPacket, notificationID, [dict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID]);
			break;
		}
		case GrowlGNTPOutgoingPacket_RegisterType:
		{
			[outgoingPacket setAction:GrowlGNTPRegisterMessageType];				
			NSMutableDictionary *dictionary = [[dict mutableCopy] autorelease];
			[dictionary removeObjectForKey:@"ApplicationIcon"];
			[dictionary removeObjectForKey:@"NotificationIcon"];
			[GrowlRegisterGNTPPacket getHeaders:&headersArray andBinaryChunks:&binaryArray forRegistrationDict:dict];
			break;
		}
		case GrowlGNTPOutgoingPacket_SubscribeType:
		{
			[outgoingPacket setAction:GrowlGNTPSubscribeMessageType];
			 break;
		}
	}

	[outgoingPacket addHeaderItems:headersArray];
	[outgoingPacket addBinaryChunks:binaryArray];
	
	return outgoingPacket;
}

+ (GrowlGNTPOutgoingPacket *)outgoingPacketForNotification:(GrowlNotification *)notification {
	return [self outgoingPacketOfType:GrowlGNTPOutgoingPacket_NotifyType forDict:[notification dictionaryRepresentation]];
}
+ (GrowlGNTPOutgoingPacket *)outgoingPacketForRegistrationWithNotifications:(NSArray /*of GrowlNotifications*/ *)allNotifications {
	NSDictionary *regDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey], GROWL_APP_NAME,
		[[NSBundle mainBundle] bundleIdentifier], GROWL_APP_ID,
		[allNotifications valueForKey:@"name"], GROWL_NOTIFICATIONS_ALL,
		nil];
	return [self outgoingPacketOfType:GrowlGNTPOutgoingPacket_RegisterType forDict:regDict];
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

- (void)setKey:(GNTPKey *)key
{
	if (![[self key] isEqual:key]) 
	{
		[mKey autorelease];
		mKey = [key retain];
	}
	[[self key] generateSalt];
	[[self key] generateKey];
}

- (GNTPKey *)key
{
	return mKey;
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

	GrowlGNTPInitialHeaderItem *header = [GrowlGNTPInitialHeaderItem initialHeaderItemWithAction:[self action]];
	GNTPKey *keyToUse = [self key];
	if (keyToUse) {
		[header setKey:[keyToUse key]];
		[header setEncryption:[keyToUse encryption]];
	}
    [allOutgoingItems addObject:header];
	
	if([keyToUse encryptionAlgorithm] != GNTPNone)
	{
		NSMutableData *headers = [NSMutableData data];
		
		for(GrowlGNTPHeaderItem *headerItem in headerItems)
		{
			[headers appendData:[headerItem GNTPRepresentation]];
		}
		NSData *data = [keyToUse encrypt:headers];
		GrowlGNTPEncryptedHeaders *encryptedHeaders = [GrowlGNTPEncryptedHeaders headerItemFromData:data error:NULL];
		[allOutgoingItems addObject:encryptedHeaders];
		[allOutgoingItems addObject:[GrowlGNTPHeaderItem separatorHeaderItem]];
	}
	else
		[allOutgoingItems addObjectsFromArray:headerItems];

	if ([binaryChunks count]) {
		[allOutgoingItems addObject:[GrowlGNTPHeaderItem separatorHeaderItem]];
		
		NSMutableArray *encryptedChunks = [NSMutableArray array];
		if([keyToUse encryptionAlgorithm] != GNTPNone)
		{
			for(GrowlGNTPBinaryChunk *chunk in binaryChunks)
			{
				GrowlGNTPBinaryChunk *encryptedChunk = [GrowlGNTPBinaryChunk chunkForData:[keyToUse encrypt:[chunk data]] withIdentifier:[chunk identifier]];
				[encryptedChunks addObject:encryptedChunk];
			}
		}
		else 
		{
			[encryptedChunks addObjectsFromArray:binaryChunks];
		}

		
		[allOutgoingItems addObjectsFromArray:encryptedChunks];
	}
	[allOutgoingItems addObject:[GrowlGNTPEndHeaderItem endHeaderItem]];

	return allOutgoingItems;
}

- (void)writeToSocket:(GCDAsyncSocket*)socket
{	
	for(id <GNTPOutgoingItem> item in [self outgoingItems]) {
		//NSLog(@"Writing to socket: %@", [item GNTPRepresentationAsString]);
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
	
	for(NSObject<GNTPOutgoingItem> *item in [self outgoingItems]) {
		if ([item isKindOfClass:[GrowlGNTPBinaryChunk class]]) {
			[description appendFormat:@"Binary chunk %@, length %d\n",
			 [(GrowlGNTPBinaryChunk *)item identifier], [(GrowlGNTPBinaryChunk *)item length]];
		} else {
			NSString *string = [[[NSString alloc] initWithData:[item GNTPRepresentation]
											 encoding:NSUTF8StringEncoding] autorelease];
			if(string)
				[description appendString:string];
		}
	}
	[description appendString:@"\">"];
		 
	return description;
}
@end
