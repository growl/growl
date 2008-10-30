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
#import "NSStringAdditions.h"
#import "GrowlGNTPHeaderItem.h"

@interface GrowlGNTPPacket ()
- (id)initForSocket:(AsyncSocket *)inSocket;
- (void)setAction:(NSString *)inAction;
- (void)setEncryptionAlgorithm:(NSString *)inEncryptionAlgorithm;
- (void)readNextHeader;
- (void)setUUID:(NSString *)inUUID;
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
	}
	
	return self;
}

- (void)dealloc
{
	[socket release];
	[specificPacket release];
	[action release];
	[encryptionAlgorithm release];
	[binaryDataByIdentifier release];
	[uuid release];

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

#pragma mark Protocol identifier

- (void)beginProcessing
{
	NSLog(@"Reading to %@", [AsyncSocket CRLFData]);
	[socket readDataToData:[AsyncSocket CRLFData]
			   withTimeout:-1
					   tag:GrowlProtocolIdentifierRead];
}

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

	if ([[items objectAtIndex:0] isEqualToString:@"GNTP/1.0"]) {
		/* We only support version 1.0 at this time */
		action = [[items objectAtIndex:1] retain];
		encryptionAlgorithm = [[items objectAtIndex:2] retain];

		if ([items count] > 3) {
			NSString *passwordInfo = [items objectAtIndex:3];
			NSLog(@"Unusued password info...");
		}
		
		return YES;
	}
	NSLog(@"Items were %@; action is %@", items, action);
	return NO;
}

- (void)configureToParsePacket
{
	if ([action caseInsensitiveCompare:@"REGISTER"] == NSOrderedSame) {
		specificPacket = [[GrowlRegisterGNTPPacket specificNetworkPacketForPacket:self] retain];
		
	} else if ([action caseInsensitiveCompare:@"NOTIFY"] == NSOrderedSame) {
		specificPacket = [[GrowlNotificationGNTPPacket specificNetworkPacketForPacket:self] retain];
	}
	NSLog(@"Reading next header using %@", specificPacket);
	//Get the specific packet started; it'll take it from there
	[specificPacket readNextHeader];	
}

#pragma mark Headers
- (void)readNextHeader
{
	NSLog(@"Read next header");
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
	NSLog(@"Received %@ in abstract superclass", headerItem);
	return GrowlReadDirective_Error;
}

/*!
 * @brief Parse a textual header which forms the body of the packet
 *
 * @result The GrowlReadDirective indicating what should be done next
 */
- (GrowlReadDirective)parseHeader:(NSData *)inData
{
	NSError *error;
	GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:inData error:&error];
	if (headerItem) {
		return [self receivedHeaderItem:headerItem];
	
	} else {
		NSLog(@"Error is %@", error);
		return GrowlReadDirective_Error;
	}
}

- (NSDictionary *)customHeaders
{
	return customHeaders;
}
- (void)setCustomHeaderWithName:(NSString *)name value:(NSString *)value
{
	[customHeaders setObject:value
					  forKey:name];
}

#pragma mark Binary Headers
- (void)readNextHeaderOfBinaryChunk
{
	NSLog(@"Read next binary chunk");
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
	NSLog(@"receivedBinaryHeaderItem %@", headerItem);
	NSString *name = [headerItem headerName];
	NSString *value = [headerItem headerValue];
	
	if (headerItem == [GrowlGNTPHeaderItem separatorHeaderItem]) {
		if (currentBinaryIdentifier && currentBinaryLength) {
			return GrowlReadDirective_SectionComplete;
		} else {
			NSLog(@"Error: Need both identifier (%@) and length (%d)", currentBinaryIdentifier, currentBinaryLength);
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
		NSLog(@"Unknown binary header %@; value %@", name, value);	
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
	NSError *error;
	GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:inData error:&error];
	if (headerItem) {
		return [self receivedBinaryHeaderItem:headerItem];
		
	} else {
		NSLog(@"Error is %@", error);
		return GrowlReadDirective_Error;
	}
}

#pragma mark Binary data

- (void)readBinaryChunk
{
	NSLog(@"start binary chunk");
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
- (void)networkPacketReadComplete
{
	NSLog(@"Read complete");
	[[self delegate] packetDidFinishReading:self];
}

#pragma mark Error
- (void)errorOccurred
{
	NSLog(@"Error occurred");
}

#pragma mark Dictionary Representation
- (NSDictionary *)growlDictionary
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[self uuid], GROWL_NETWORK_PACKET_UUID,
			nil];
}

#pragma mark Incoming network processing

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)inHost port:(UInt16)inPort
{
	NSLog(@"Did connect to %@", inHost);
	/* XXX Check (enabled || localhost) */
	/* XXX Note originating host? */
	[self beginProcessing];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{	
	switch (tag) {
		case GrowlProtocolIdentifierRead:
			if ([self parseProtocolIdentifier:data]) {
				[self configureToParsePacket];
			}
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
	}
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(CFIndex)partialLength tag:(long)tag
{
	NSLog(@"%@: didReadPartialDataOfLength: %@ Read %i: tag %i",self, sock, partialLength, tag);
}

/*
 This will be called whenever AsyncSocket is about to disconnect. Tthis is
 a good place to do disaster-recovery by getting partially-read data. This is
 not, however, a good place to do cleanup. The socket must still exist when this
 method returns.
 */
-(void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	if (err != nil) {
		NSLog (@"Socket %@ will disconnect. Error domain %@, code %d (%@).",
			   sock,
			   [err domain], [err code], [err localizedDescription]);
		[self errorOccurred];
	} else
		NSLog (@"Socket will disconnect. No error. unread: %@", [sock unreadData]);
	
	[[self delegate] packetDidDisconnect:self];
}

#pragma mark GrowlGNTPPacketDelegate
/*!
 * @brief Called by our specific packet; we'll pas it on to our delegate
 *
 * Note that we pass on the specific packet, as it has all the needed data, not self.
 */
- (void)packetDidFinishReading:(GrowlGNTPPacket *)packet
{
	[[self delegate] packetDidFinishReading:packet];
}

- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet
{
	[[self delegate] packetDidDisconnect:packet];	
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %x: %@>", NSStringFromClass([self class]), self, [self growlDictionary]];
}

@end
