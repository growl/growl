//
//  GrowlGNTPOutgoingPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GrowlGNTPHeaderItem.h"
#import "GrowlGNTPBinaryChunk.h"

typedef enum {
	GrowlGNTPOutgoingPacket_OtherType,
	GrowlGNTPOutgoingPacket_NotifyType,
	GrowlGNTPOutgoingPacket_RegisterType
} GrowlGNTPOutgoingPacketType;

@interface GrowlGNTPOutgoingPacket : NSObject {
	NSMutableArray *headerItems;
	NSMutableArray *binaryChunks;
	NSString *action;
	NSString *packetID;
}

+ (GrowlGNTPOutgoingPacket *)outgoingPacket;
+ (GrowlGNTPOutgoingPacket *)outgoingPacketOfType:(GrowlGNTPOutgoingPacketType)type forDict:(NSDictionary *)dict;

- (void)setAction:(NSString *)action;
- (NSString *)packetID;

- (void)addHeaderItem:(GrowlGNTPHeaderItem *)inItem;
- (void)addHeaderItems:(NSArray *)inItems;

- (void)addBinaryChunk:(GrowlGNTPBinaryChunk *)inChunk;
- (void)addBinaryChunks:(NSArray *)inItems;

- (void)writeToSocket:(AsyncSocket *)socket;

- (BOOL)needsPersistentConnectionForCallback;

@end
