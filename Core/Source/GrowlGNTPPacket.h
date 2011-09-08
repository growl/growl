//
//  GrowlGNTPPacket.h
//  Growl
//
//  Created by Evan Schoenberg on 9/6/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"
#import "GrowlGNTPDefines.h"
#import "GNTPKey.h"

@class GrowlGNTPPacket, GrowlGNTPHeaderItem;

typedef enum {
	GrowlInitialBytesIdentifierRead = 1,
	GrowlProtocolIdentifierRead,
	GrowlFlashPolicyRequestRead,
	GrowlHeaderRead,
	GrowlBinaryHeaderRead,
	GrowlBinaryDataRead,
	GrowlExhaustingRemainingDataRead
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
	GrowlRegisterPacketType,
	GrowlOKPacketType,
	GrowlCallbackPacketType,
	GrowlSubscribePacketType,
   GrowlErrorPacketType
} GrowlPacketType;

@protocol GrowlGNTPPacketDelegate
/*!
 * @brief A packet was successfully received and parsed
 *
 * The delegate should now make use of the packet's data
 */
- (void)packetDidFinishReading:(GrowlGNTPPacket *)packet;

/*!
 * @brief An error occurred while reading a packet
 *
 * The NSError's code and userinfo's NSLocalizedFailureReasonErrorKey string will give the type and cause of error.
 * After this delegate method is called, the socket underlying the packet will be disconnected once all queued
 * writes are complete, so the delegate should immediately queue any desired response (such as an error result).
 */
- (void)packet:(GrowlGNTPPacket *)packet failedReadingWithError:(NSError *)inError;

/*!
 * @brief The socket underlying the given packet disconnected
 *
 * This is called regardless of the cause of disconnection (voluntary or involuntary)
 */
- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet;

/*!
 * @brief A packet received information which changed its packet ID
 */
- (void)packet:(GrowlGNTPPacket *)packet willChangePacketIDFrom:(NSString *)oldPacketID to:(NSString *)newPacketID;
@end

@interface GrowlGNTPPacket : NSObject <GrowlGNTPPacketDelegate> {
	GCDAsyncSocket *socket;
	NSString	*host;

	id<GrowlGNTPPacketDelegate> mDelegate;

	NSString *mAction;
	GNTPKey *mKey;
	
	NSMutableArray *customHeaders;
	
	NSMutableDictionary *binaryDataByIdentifier;
	NSMutableSet *pendingBinaryIdentifiers;
	NSString *packetID;
	
	NSString *currentBinaryIdentifier;
	unsigned long currentBinaryLength;
	
	GrowlGNTPPacket *specificPacket;

	BOOL wasInitiatedLocally;
	NSError *error;
	
	NSString *encryptionAlgorithm;
}

#if GROWLHELPERAPP

+ (GrowlGNTPPacket *)networkPacketForSocket:(GCDAsyncSocket *)inSocket;

/*!
 * @brief Start listening for incoming data
 *
 * Only needs to be called if the socket was already connected; otherwise will be called automaticaly
 */
- (void)startProcessing;

- (GCDAsyncSocket *)socket;

- (GrowlPacketType)packetType;
- (NSString *)packetID;
- (void)setPacketID:(NSString *)inPacketID;

- (NSDictionary *)growlDictionary;
- (BOOL)hasBeenReceivedPreviously;

- (void)setWasInitiatedLocally:(BOOL)inWasInitiatedLocally;

- (NSError *)error;

@property (retain) NSString *action;
@property (retain) GNTPKey *key;
@property (retain) NSString *encryptionAlgorithm;

#endif

@property (assign) id <GrowlGNTPPacketDelegate> delegate;

@end

@interface GrowlGNTPPacket (ForSubclasses)
+ (void)addSentAndReceivedHeadersFromDict:(NSDictionary *)dict toArray:(NSMutableArray *)headersArray;
#if GROWLHELPERAPP
- (void)setError:(NSError *)error;
- (void)addCustomHeader:(GrowlGNTPHeaderItem *)inItem;
- (NSArray *)customHeaders;
#endif
@end

@interface GrowlGNTPPacket (GNTPInternal)
#if GROWLHELPERAPP
- (NSArray *)headersForResult;
+ (GrowlGNTPCallbackBehavior)callbackResultSendBehaviorForHeaders:(NSArray *)headers;
- (GrowlGNTPCallbackBehavior)callbackResultSendBehavior;
- (NSArray *)headersForCallbackResult_wasClicked:(BOOL)wasClicked;
- (NSURLRequest *)urlRequestForCallbackResult_wasClicked:(BOOL)wasClicked;
#endif
@end
