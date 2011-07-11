//
//  GrowlGNTPOutgoingPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 10/30/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "GrowlGNTPHeaderItem.h"
#import "GrowlGNTPBinaryChunk.h"
#import "GNTPKey.h"

typedef enum {
	GrowlGNTPOutgoingPacket_OtherType,
	GrowlGNTPOutgoingPacket_NotifyType,
	GrowlGNTPOutgoingPacket_RegisterType,
	GrowlGNTPOutgoingPacket_SubscribeType
} GrowlGNTPOutgoingPacketType;

@class GrowlNotification;

@interface GrowlGNTPOutgoingPacket : NSObject {
	NSMutableArray *headerItems;
	NSMutableArray *binaryChunks;
	NSString *mAction;
	
	GNTPKey *mKey;
	
	NSString *packetID;
}

+ (GrowlGNTPOutgoingPacket *)outgoingPacket;
+ (GrowlGNTPOutgoingPacket *)outgoingPacketOfType:(GrowlGNTPOutgoingPacketType)type forDict:(NSDictionary *)dict;

+ (GrowlGNTPOutgoingPacket *)outgoingPacketForNotification:(GrowlNotification *)notification;
+ (GrowlGNTPOutgoingPacket *)outgoingPacketForRegistrationWithNotifications:(NSArray /*of GrowlNotifications*/ *)allNotifications;

- (NSString *)packetID;

- (void)addHeaderItem:(GrowlGNTPHeaderItem *)inItem;
- (void)addHeaderItems:(NSArray *)inItems;

- (void)addBinaryChunk:(GrowlGNTPBinaryChunk *)inChunk;
- (void)addBinaryChunks:(NSArray *)inItems;

- (void)writeToSocket:(GCDAsyncSocket *)socket;

- (BOOL)needsPersistentConnectionForCallback;

@property (retain) NSString *action;
@property (retain) GNTPKey *key;

@end
