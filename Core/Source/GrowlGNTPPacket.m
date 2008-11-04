//
//  GrowlGNTPPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 9/6/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlGNTPPacket.h"
#import "GrowlNotificationGNTPPacket.h"
#import "GrowlRegisterGNTPPacket.h"
#import "GrowlCallbackGNTPPacket.h"
#import "NSStringAdditions.h"
#import "GrowlGNTPHeaderItem.h"
#import "NSCalendarDate+ISO8601Unparsing.h"

@interface GrowlGNTPPacket ()
- (id)initForSocket:(AsyncSocket *)inSocket;
- (void)setAction:(NSString *)inAction;
- (void)setEncryptionAlgorithm:(NSString *)inEncryptionAlgorithm;
- (void)readNextHeader;
- (void)setUUID:(NSString *)inUUID;
- (void)beginProcessingProtocolIdentifier;
@end

@implementation GrowlGNTPPacket

+ (GrowlGNTPPacket *)networkPacketForSocket:(AsyncSocket *)inSocket
{
	return [[[self alloc] initForSocket:inSocket] autorelease];
}

/*!
 * @brief Used by GrowlGNTPPacket to get a GrowlGNTPPacket subclass for further processing
 */
+ (GrowlGNTPPacket *)specificNetworkPacketForPacket:(GrowlGNTPPacket *)packet
{
	/* Note that specificPacket takes ownership of the socket, setting the socket's delegate to itself */
	GrowlGNTPPacket *specificPacket = [[[self alloc] initForSocket:[packet socket]] autorelease];
	[specificPacket setDelegate:packet];
	[specificPacket setAction:[packet action]];
	[specificPacket setEncryptionAlgorithm:[packet encryptionAlgorithm]];
	[specificPacket setUUID:[packet uuid]];

	return specificPacket;
}

- (id)initForSocket:(AsyncSocket *)inSocket
{
	if ((self = [self init])) {
		socket = [inSocket retain];
		[socket setDelegate:self];
		
		binaryDataByIdentifier = [[NSMutableDictionary alloc] init];
		pendingBinaryIdentifiers = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	if ([socket delegate] == self)
		[socket setDelegate:nil];

	[socket release];
	[specificPacket release];
	[action release];
	[encryptionAlgorithm release];
	[binaryDataByIdentifier release];
	[uuid release];
	[customHeaders release];

	[super dealloc];
}

- (AsyncSocket *)socket
{
	return socket;
}

- (NSString *)uuid
{
	if (!uuid) {
		CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
		uuid = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
		CFRelease(uuidRef);
	}		
	return uuid;
}
- (void)setUUID:(NSString *)inUUID
{
	[uuid autorelease];
	uuid = [inUUID retain];
}

- (void)setDelegate:(id <GrowlGNTPPacketDelegate>)inDelegate;
{
	delegate = inDelegate;
}
- (id <GrowlGNTPPacketDelegate>)delegate
{
	return delegate;
}

- (GrowlPacketType)packetType
{
	if ([action caseInsensitiveCompare:@"NOTIFY"] == NSOrderedSame)
		return GrowlNotifyPacketType;
	else if ([action caseInsensitiveCompare:@"REGISTER"] == NSOrderedSame)
		return GrowlRegisterPacketType;
	else if ([action caseInsensitiveCompare:@"-CALLBACK"] == NSOrderedSame)
		return GrowlCallbackPacketType;
	else
		return GrowlUnknownPacketType;
}

- (NSString *)action
{
	return action;
}
- (void)setAction:(NSString *)inAction
{
	if (action != inAction) {
		[action release];
		action = [inAction retain];
	}
}
- (NSString *)encryptionAlgorithm
{
	return encryptionAlgorithm;
}
- (void)setEncryptionAlgorithm:(NSString *)inEncryptionAlgorithm
{
	if (encryptionAlgorithm != inEncryptionAlgorithm) {
		[encryptionAlgorithm release];
		encryptionAlgorithm = [inEncryptionAlgorithm retain];
	}
}


- (void)setError:(NSError *)inError
{
	if (inError != error) {
		[error autorelease];
		error = [inError retain];
	}
}

- (NSError *)error
{
	return error;
}

#pragma mark Protocol identifier

- (void)beginProcessingProtocolIdentifier
{
	[socket readDataToLength:4
			   withTimeout:-1
					   tag:GrowlInitialBytesIdentifierRead];
}

- (void)startProcessing
{
	[self beginProcessingProtocolIdentifier];
}

- (void)finishProcessingProtocolIdentifier
{
	[socket readDataToData:[AsyncSocket CRLFData]
			   withTimeout:-1
					   tag:GrowlProtocolIdentifierRead];	
}

- (GrowlInitialReadResult)parseInitialBytes:(NSData *)data
{
	NSString *firstFourOfIdentifierLine = [[[NSString alloc] initWithData:data
																  encoding:NSUTF8StringEncoding] autorelease];
	if ([firstFourOfIdentifierLine caseInsensitiveCompare:@"GNTP"] == NSOrderedSame) {
		return GrowlInitialReadResult_GNTPPacket;
	} else if ([firstFourOfIdentifierLine caseInsensitiveCompare:@"<pol"] == NSOrderedSame) {
		return GrowlInitialReadResult_FlashPolicyPacket;
	} else {
		NSLog(@"Didn't know what to do with %@", firstFourOfIdentifierLine);
		return GrowlInitialReadResult_UnknownPacket;
	}
}

- (void)finishReadingFlashPolicyRequest
{
	[socket readDataToData:[@"\0" dataUsingEncoding:NSUTF8StringEncoding]
			   withTimeout:-1
					   tag:GrowlFlashPolicyRequestRead];
}

- (void)respondToFlashPolicyRequest
{
	NSData *responseData = [@"<?xml version=\"1.0\"?>"
							"<!DOCTYPE cross-domain-policy SYSTEM \"/xml/dtds/cross-domain-policy.dtd\">"
							"<cross-domain-policy> "
							"<site-control permitted-cross-domain-policies=\"master-only\"/>"
							"<allow-access-from domain=\"*\" to-ports=\"*\" />"
							"</cross-domain-policy>\0" dataUsingEncoding:NSUTF8StringEncoding];
	[socket writeData:responseData
		  withTimeout:-1
				  tag:0];
	[socket disconnectAfterWriting];
}

/* 	<policy-file-request/> */

/*!
 * @brief Parse protocol identifier data
 *
 * First line of the datagram should include the protocol identifier, version, action, encryption algorithm id, and optionally, the password hash algorithm id and password hash:
  * 
 * GNTP/<version> <action> <encryptionAlgorithmID>[ <passwordHashAlgorithmID>:<passwordHash>]
 *  
 * where GNTP is the name of the protocol and:
 * 
 * <version> is the version number. currently, the only supported version is '1.0'.
 * <action> identifies the type of message; supported values are NOTIFY and REGISTER
 * <encryptionAlgorithmID> identifies the type of encryption used on the message. see below for supported values
 * <passwordHashAlgorithmID> identifies the type of hashing algorithm used. see below for supported values
 * <passwordHash> is hex-encoded hash of the password
 * 
 * NOTE: <passswordHashAlgorithm> and <passwordHash> are not required for requests that originate on the local machine
 */
- (BOOL)parseProtocolIdentifier:(NSData *)data
{
	NSString *identifierLine = [[[NSString alloc] initWithData:data
													  encoding:NSUTF8StringEncoding] autorelease];
	NSArray *items = [identifierLine componentsSeparatedByString:@" "];
	if ([items count] < 3) {
		/* We need at least version, action, encryption ID, so this identiifer line is invalid */
		NSLog(@"%@ doesn't have enough information...", identifierLine);
		return NO;
	}

	/* GNTP was eaten by our first-four byte read, so we start at the version number, /1.0 */
	if ([[items objectAtIndex:0] isEqualToString:@"/1.0"]) {
		/* We only support version 1.0 at this time */
		action = [[items objectAtIndex:1] retain];
		encryptionAlgorithm = [[items objectAtIndex:2] retain];

		if ([items count] > 3) {
			NSString *passwordInfo = [items objectAtIndex:3];
			NSLog(@"Unusued password info...");
		}
		
		return YES;
	}

	return NO;
}

- (void)configureToParsePacket
{
	if ([action caseInsensitiveCompare:@"REGISTER"] == NSOrderedSame) {
		specificPacket = [[GrowlRegisterGNTPPacket specificNetworkPacketForPacket:self] retain];
		
	} else if ([action caseInsensitiveCompare:@"NOTIFY"] == NSOrderedSame) {
		specificPacket = [[GrowlNotificationGNTPPacket specificNetworkPacketForPacket:self] retain];

	} else if ([action caseInsensitiveCompare:@"-CALLBACK"] == NSOrderedSame) {
		specificPacket = [[GrowlCallbackGNTPPacket specificNetworkPacketForPacket:self] retain];

	} else if ([action caseInsensitiveCompare:@"-OK"] == NSOrderedSame) {
		/* An OK response can be silently dropped */

	} else if ([action caseInsensitiveCompare:@"-ERROR"] == NSOrderedSame) {
		NSLog(@"%@: Error :(", self);
		//XXX
/*		specificPacket = [[GrowlErrorGNTPPacket specificNetworkPacketForPacket:self] retain]; */
	}

	//Get the specific packet started; it'll take it from there
	[specificPacket readNextHeader];	
}

#pragma mark Headers
- (void)readNextHeader
{
	[socket readDataToData:[AsyncSocket CRLFData]
			   withTimeout:-1
					   tag:GrowlHeaderRead];
}

/*!
 * @brief Act on a received header item
 *
 * Called by parseHeader, this is abstract in GrowlGNTPPacket and should be implemented in its subclasses
 * to perform the actual work of handling the passed headerItem
 */
- (GrowlReadDirective)receivedHeaderItem:(GrowlGNTPHeaderItem *)headerItem
{
	[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
									   code:GrowlGNTPHeaderError
								   userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Received %@ in abstract superclass. Implementation failure.", 
																				headerItem]
																		forKey:NSLocalizedFailureReasonErrorKey]]];	
	return GrowlReadDirective_Error;
}

/*!
 * @brief Parse a textual header which forms the body of the packet
 *
 * @result The GrowlReadDirective indicating what should be done next
 */
- (GrowlReadDirective)parseHeader:(NSData *)inData
{
	NSError *anError;
	GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:inData error:&anError];
	if (headerItem) {
		return [self receivedHeaderItem:headerItem];
	
	} else {
		[self setError:anError];
		return GrowlReadDirective_Error;
	}
}

- (NSArray *)customHeaders
{
	return customHeaders;
}
- (void)addCustomHeader:(GrowlGNTPHeaderItem *)inItem
{
	if (!customHeaders) customHeaders = [[NSMutableArray alloc] init];
	[customHeaders addObject:inItem];
}

/*!
 * @brief Headers to be returned via the -OK success result
 *
 * In the superclass, we just send any custom headers included in the packet originally
 */
- (NSArray *)headersForResult
{
	return customHeaders;
}

+ (void)addSentAndReceivedHeadersFromDict:(NSDictionary *)dict toArray:(NSMutableArray *)headersArray
{
	NSString *hostName = [[NSProcessInfo processInfo] hostName];
	if ([hostName hasSuffix:@".local"]) {
		hostName = [hostName substringToIndex:([hostName length] - [@".local" length])];
	}

	/* Previous received headers */
	NSEnumerator *enumerator = [[dict valueForKey:GROWL_NOTIFICATION_GNTP_RECEIVED] objectEnumerator];
	NSString *received;
	while ((received = [enumerator nextObject])) {
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Received" value:received]];
	}
	/* New received header */
	if ([dict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY]) {
		/* Received: From <hostname> by <hostname> [with Growl] [id <identifier>]; <ISO 8601 date> */
		received = [NSString stringWithFormat:@"From %@ by %@ with Growl%@; %@",
					[dict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY], hostName, 
					([dict valueForKey:GROWL_NOTIFICATION_GNTP_ID] ? [NSString stringWithFormat:@" id %@", [dict valueForKey:GROWL_NOTIFICATION_GNTP_ID]] : @""),
					[[NSCalendarDate date] ISO8601DateString]];
		
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Received" value:received]];
	}
	
	/* New Sent-By header: Sent-By: <hostname> */
	[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Sent-By" value:hostName]];	
}

/*!
 * @brief Return YES if this packet has previously been received by this host
 *
 * This is used to prevent infinite sending loops
 */
- (BOOL)hasBeenReceivedPreviously
{
	NSArray *receivedHeaders = [[self growlDictionary] objectForKey:GROWL_NOTIFICATION_GNTP_RECEIVED];
	NSEnumerator *enumerator;
	NSString *receivedString;
	NSString *myHostString;

	NSString *hostName = [[NSProcessInfo processInfo] hostName];
	if ([hostName hasSuffix:@".local"]) {
		hostName = [hostName substringToIndex:([hostName length] - [@".local" length])];
	}
	
	/* Check if this host received it previously */
	myHostString = [NSString stringWithFormat:@"by %@", hostName];
	enumerator = [receivedHeaders objectEnumerator];
	while ((receivedString = [enumerator nextObject])) {
		if ([receivedString rangeOfString:myHostString].location != NSNotFound)
			return YES;
	}

	/* Check if this host sent it previously */
	myHostString = [NSString stringWithFormat:@"From %@", hostName];
	enumerator = [receivedHeaders objectEnumerator];
	while ((receivedString = [enumerator nextObject])) {
		if ([receivedString rangeOfString:myHostString].location != NSNotFound)
			return YES;
	}

	return NO;
}

#pragma mark Callbacks
- (GrowlGNTPCallbackBehavior)callbackResultSendBehavior
{
	if (specificPacket)
		return [specificPacket callbackResultSendBehavior];
	else
		return GrowlGNTP_NoCallback; /* This abstract superclass has no idea how to send a callback */
}
+ (GrowlGNTPCallbackBehavior)callbackResultSendBehaviorForHeaders:(NSArray *)headers
{
#pragma unused(headers)
	return GrowlGNTP_NoCallback; /* This abstract superclass has no idea how to send a callback */	
}

- (NSArray *)headersForCallbackResult_wasClicked:(BOOL)wasClicked
{
	if (specificPacket)
		return [specificPacket headersForCallbackResult_wasClicked:wasClicked];
	else
		return nil; /* This abstract superclass has no idea how to send a callback */
}

- (NSURLRequest *)urlRequestForCallbackResult_wasClicked:(BOOL)wasClicked
{
	if (specificPacket)
		return [specificPacket urlRequestForCallbackResult_wasClicked:(BOOL)wasClicked];
	else
		return nil; /* This abstract superclass has no idea how to send a callback */
}

#pragma mark Binary Headers
- (void)readNextHeaderOfBinaryChunk
{
	[socket readDataToData:[AsyncSocket CRLFData]
			   withTimeout:-1
					   tag:GrowlBinaryHeaderRead];	
}

- (void)setCurrentBinaryIdentifier:(NSString *)string
{
	[currentBinaryIdentifier autorelease];
	currentBinaryIdentifier = [string retain];
}

- (void)setCurrentBinaryLength:(unsigned long)inLength
{
	currentBinaryLength = inLength;
}

- (GrowlReadDirective)receivedBinaryHeaderItem:(GrowlGNTPHeaderItem *)headerItem
{
	NSString *name = [headerItem headerName];
	NSString *value = [headerItem headerValue];
	
	if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
		if (currentBinaryIdentifier && currentBinaryLength) {
			return GrowlReadDirective_SectionComplete;
		} else {
			[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
											   code:GrowlGNTPHeaderError
										   userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Need both identifier (%@) and length (%d)",
																						currentBinaryIdentifier, currentBinaryLength]
																				forKey:NSLocalizedFailureReasonErrorKey]]];			
			return GrowlReadDirective_Error;
		}

	} 

	if ([name caseInsensitiveCompare:@"Identifier"] == NSOrderedSame) {
		[self setCurrentBinaryIdentifier:value];
		return GrowlReadDirective_Continue;
		
	} else if ([name caseInsensitiveCompare:@"Length"] == NSOrderedSame) {
		[self setCurrentBinaryLength:[value unsignedLongValue]];
		return GrowlReadDirective_Continue;
		
	} else {
		[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
										   code:GrowlGNTPHeaderError
									   userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unknown binary header %@; value %@",
																					name, value]
																			forKey:NSLocalizedFailureReasonErrorKey]]];			
		return GrowlReadDirective_Error;
	}
}

/*!
 * @brief Parse a binary chunk's header, which will give identifier and length information
 *
 * @result The GrowlReadDirective indicating what should be done next
 */
- (GrowlReadDirective)parseBinaryHeader:(NSData *)inData
{
	NSError *anError;
	GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:inData error:&anError];
	if (headerItem) {
		return [self receivedBinaryHeaderItem:headerItem];
		
	} else {
		[self setError:anError];
		return GrowlReadDirective_Error;
	}
}

#pragma mark Binary data

- (void)readBinaryChunk
{
	[socket readDataToLength:currentBinaryLength
				 withTimeout:-1
						 tag:GrowlBinaryDataRead];	
}

/*!
 * @brief We received complete binary data
 *
 * Note that it was enforced before we began receiving this data that currentBinaryIdentifier is non-nil
 *
 * @result GrowlReadDirective_SectionComplete if we have more binary data chunks to read; GrowlReadDirective_PacketComplete if this was the last one and we are done.
 */
- (GrowlReadDirective)parseBinaryData:(NSData *)inData
{
	[binaryDataByIdentifier setObject:inData
							   forKey:currentBinaryIdentifier];
	[pendingBinaryIdentifiers removeObject:currentBinaryIdentifier];

	return ([pendingBinaryIdentifiers count] ? GrowlReadDirective_SectionComplete : GrowlReadDirective_PacketComplete);
}
	
#pragma mark Complete
/*!
 * @brief A packet was received in its entirety
 *
 * It needs to be validated.
 *
 * The connected socket, if still connected, will wait for the GNTP/1.0 END sequence before treating incoming data
 * as a new packet.
 */
- (void)networkPacketReadComplete
{
	/* XXX We should validate the received packet in its entirey NOW */
	
	/* If we're going to ever read anything else on this socket, it must first be preceeded by the GNTP/1.0 END tag */
#define CRLF "\x0D\x0A"	
	NSData *endData = [[NSString stringWithFormat:@"GNTP/1.0 END" CRLF CRLF] dataUsingEncoding:NSUTF8StringEncoding];	

	[socket readDataToData:endData
			   withTimeout:-1
					   tag:GrowlExhaustingRemainingDataRead];		

	[[self delegate] packetDidFinishReading:self];
}

#pragma mark Error
/*!
 * @brief An error occurred
 *
 * 1. Tell the delegate. This is the delegate's last chance to queue reads on our socket!
 * 2. Disconnect after all queued writing is complete.
 */
- (void)errorOccurred
{
	NSLog (@"Error occurred: Error domain %@, code %d (%@).",
		   [[self error] domain], [[self error] code], [[self error] localizedDescription]);
	[[self delegate] packet:self failedReadingWithError:[self error]];

	[socket disconnectAfterWriting];
}

#pragma mark Dictionary Representation
- (NSDictionary *)growlDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self uuid], GROWL_NETWORK_PACKET_UUID,
			nil];
}

#pragma mark Incoming network processing

- (BOOL)isLocalHost:(NSString *)inHost
{
	if ([inHost isEqualToString:@"127.0.0.1"])
		return YES;
	else {
		return NO;
	}
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)inHost port:(UInt16)inPort
{
#pragma unused(inPort)
	if ([self isLocalHost:inHost] ||
		[[GrowlPreferencesController sharedController] boolForKey:GrowlStartServerKey] ||
		([sock userData] == GrowlGNTPPacketSocketUserData_WasInitiatedLocally)) {
		[self startProcessing];
	} else {
		[sock disconnect];
	}
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
#ifdef DEBUG
	NSLog(@"Recv: \"%@\"", [[[NSString alloc] initWithData:data
												  encoding:NSUTF8StringEncoding] autorelease]);
#endif

#pragma unused(sock)
	switch (tag) {
		case GrowlInitialBytesIdentifierRead:
			switch ([self parseInitialBytes:data]) {
				case GrowlInitialReadResult_UnknownPacket:
					[self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
													   code:GrowlGNTPMalformedProtocolIdentificationError
												   userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:
																								@"Unknown incoming data %@ while expected a GNTP packet; dropping the connection.",
															 [[[NSString alloc] initWithData:data
																					encoding:NSUTF8StringEncoding] autorelease]]
																						forKey:NSLocalizedFailureReasonErrorKey]]];
					[self errorOccurred];
					break;
				case GrowlInitialReadResult_GNTPPacket:
					[self finishProcessingProtocolIdentifier];
					break;
				case GrowlInitialReadResult_FlashPolicyPacket:
					[self finishReadingFlashPolicyRequest];
					break;
			}
			break;
		case GrowlProtocolIdentifierRead:
			if ([self parseProtocolIdentifier:data]) {
				[self configureToParsePacket];
			}
			break;			
		case GrowlFlashPolicyRequestRead:
			[self respondToFlashPolicyRequest];
			break;
		case GrowlHeaderRead:
			switch ([self parseHeader:data]) {
				case GrowlReadDirective_SectionComplete:
					/* Done with all headers; time to read binary */
					[self readNextHeaderOfBinaryChunk];
					break;
				case GrowlReadDirective_Continue:
					[self readNextHeader];
					break;
				case GrowlReadDirective_PacketComplete:
					[self networkPacketReadComplete];
					break;
				case GrowlReadDirective_Error:
					[self errorOccurred];
					break;
			}
			break;
		case GrowlBinaryHeaderRead:
			switch ([self parseBinaryHeader:data]) {
				case GrowlReadDirective_SectionComplete:
					/* Done with all binary headers; time to read the binary data */
					[self readBinaryChunk];
					break;
				case GrowlReadDirective_Continue:
					[self readNextHeaderOfBinaryChunk];
					break;
				case GrowlReadDirective_PacketComplete:
					/* This is probably an error condition; we shouldn't have finished a packet with a binary header */
					[self networkPacketReadComplete];
					break;
				case GrowlReadDirective_Error:
					[self errorOccurred];
					break;
			}
			break;
		case GrowlBinaryDataRead:
			switch ([self parseBinaryData:data]) {
				case GrowlReadDirective_SectionComplete:
					/* Done with a binary block; we may have more binary blocks to read */
					[self readNextHeaderOfBinaryChunk];
				case GrowlReadDirective_Continue:
					/* Continue reading in the same binary block? This shouldn't happen */
					[self errorOccurred];
					break;					
				case GrowlReadDirective_PacketComplete:
					[self networkPacketReadComplete];
					break;
				case GrowlReadDirective_Error:
					[self errorOccurred];
					break;
			}					
			break;
		case GrowlExhaustingRemainingDataRead:
			/* No-op */
			break;
	}
}

/*
 This will be called whenever AsyncSocket is about to disconnect. Tthis is
 a good place to do disaster-recovery by getting partially-read data. This is
 not, however, a good place to do cleanup. The socket must still exist when this
 method returns.
 */
-(void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
#pragma unused(sock)
	if (err != nil) {
		[self setError:err];
		[self errorOccurred];
	} else {
		/* Treat the packet as complete if it is disconnected without an error. */
		[self networkPacketReadComplete];
	}
	
	[[self delegate] packetDidDisconnect:self];
}

#pragma mark GrowlGNTPPacketDelegate
/*!
 * @brief Called by our specific packet; we'll pas it on to our delegate
 *
 * Note that we pass on the specific packet, as it has all the needed data, not self.
 *
 * After we tell our delegate, we'll reset to be ready to read any response from the other side, including
 * a click or timeout notification
 */
- (void)packetDidFinishReading:(GrowlGNTPPacket *)packet
{
	[[self delegate] packetDidFinishReading:packet];
}

- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet
{
	[[self delegate] packetDidDisconnect:packet];	
}

- (void)packet:(GrowlGNTPPacket *)packet failedReadingWithError:(NSError *)inError
{
	[[self delegate] packet:packet failedReadingWithError:inError];	
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %x: %@>", NSStringFromClass([self class]), self, [self growlDictionary]];
}

@end
