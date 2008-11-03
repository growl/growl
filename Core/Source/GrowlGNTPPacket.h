//
//  GrowlGNTPPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 9/6/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AsyncSocket.h"
#import "GrowlGNTPDefines.h"

#define GROWL_NETWORK_PACKET_UUID	@"GrowlGNTPPacketUUID"

@class GrowlGNTPPacket;

typedef enum {
	GrowlInitialBytesIdentifierRead = 1,
	GrowlProtocolIdentifierRead,
	GrowlFlashPolicyRequestRead,
	GrowlHeaderRead,
	GrowlBinaryHeaderRead,
	GrowlBinaryDataRead
} NetworkReadingType;

typedef enum {
	GrowlReadDirective_SectionComplete, /* This section (headers, binary chunks) is complete */
	GrowlReadDirective_Continue, /* This section (headers, binary chunks) should continue reading */
	GrowlReadDirective_PacketComplete, /* We now have everything we need for this packet; stop reading */
	GrowlReadDirective_Error /* An error occurred; stop reading */
} GrowlReadDirective;

typedef enum {
	GrowlInitialReadResult_UnknownPacket,
	GrowlInitialReadResult_GNTPPacket,
	GrowlInitialReadResult_FlashPolicyPacket
} GrowlInitialReadResult;

typedef enum {
	GrowlUnknownPacketType,
	GrowlNotifyPacketType,
	GrowlRegisterPacketType
} GrowlPacketType;

@protocol GrowlGNTPPacketDelegate
- (void)packetDidFinishReading:(GrowlGNTPPacket *)packet;
- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet;
@end

@interface GrowlGNTPPacket : NSObject <GrowlGNTPPacketDelegate> {
	AsyncSocket *socket;
	NSString	*host;

	id<GrowlGNTPPacketDelegate> delegate;

	NSString *action;
	NSString *encryptionAlgorithm;

	NSMutableDictionary *customHeaders;
	
	NSMutableDictionary *binaryDataByIdentifier;
	NSMutableSet *pendingBinaryIdentifiers;
	NSString *uuid;
	
	NSString *currentBinaryIdentifier;
	unsigned long currentBinaryLength;
	
	GrowlGNTPPacket *specificPacket;
	
	NSError *error;
}

+ (GrowlGNTPPacket *)networkPacketForSocket:(AsyncSocket *)inSocket;

- (AsyncSocket *)socket;

- (GrowlPacketType)packetType;
- (NSString *)uuid;

- (void)setDelegate:(id <GrowlGNTPPacketDelegate>)inDelegate;
- (id <GrowlGNTPPacketDelegate>)delegate;

- (NSString *)action;

- (NSString *)encryptionAlgorithm;

- (void)setCustomHeaderWithName:(NSString *)name value:(NSString *)value;
- (NSDictionary *)customHeaders;

- (NSDictionary *)growlDictionary;

- (NSError *)error;
- (void)setError:(NSError *)error;

@end
