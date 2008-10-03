//
//  GrowlNetworkPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 9/6/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlNetworkPacket.h"
#import "GrowlNotificationNetworkPacket.h"
#import "GrowlRegisterNetworkPacket.h"

typedef enum {
	GrowlProtocolIdentifierRead,
	GrowlHeaderRead,
	GrowlBinaryDataRead
} NetworkReadingType;

typedef enum {
	GrowlReadDirective_SectionComplete, /* This section (headers, binary chunks) is complete */
	GrowlReadDirective_Continue, /* This section (headers, binary chunks) should continue reading */
	GrowlReadDirective_PacketComplete, /* We now have everything we need for this packet; stop reading */
	GrowlReadDirective_Error /* An error occurred; stop reading */
} GrowlReadDirective;

@implementation GrowlNetworkPacket

+ (GrowlNetworkPacket *)networkPacketForSocket:(AsyncSocket *)inSocket
{
	return [[[self alloc] initForSocket:inSocket] autorelease];
}

/*!
 * @brief Used by GrowlNetworkPacket to get a GrowlNetworkPacket subclass for further processing
 */
+ (GrowlNetworkPacket *)specificNetworkPacketForPacket:(GrowlNetworkPacket *)packet
{
	/* Note that specificPacket takes ownership of the socket, setting the socket's delegate to itself */
	GrowlNetworkPacket *specificPacket = [[[self alloc] initForSocket:[packet socket]] autorelease];
	[specificPacket setDelegate:packet];
	[specificPacket setAction:action];
	[specificPacket setEncryptionAlgorithm:encryptionAlgorithm];

	return specificPacket;
}

- (id)initForSocket:(AsyncSocket *)inSocket
{
	if ((self = [super init])) {
		socket = [inSocket retain];
		[socket setDelegate:self];
	}
	
	retrun self;
}

- (void)dealloc
{
	[socket release];
	[specificPacket release];
	[action release];
	[encryptionAlgorithm release];

	[super dealloc];
}

- (void)setDelegate:(id)inDelegate
{
	delagate = inDelegate;
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
 * <action> identifies the type of message. see below for supported values
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
			NSString *passwordInfo = [items objecAtIndex:3];
			NSLog(@"Unusued password info %@", passwordInfo);
		}
		
		return YES;
	}
	
	return NO;
}

- (void)configureToParsePacket
{
	if ([action caseInsensitiveCompare:@"REGISTER"] == NSOrderedSame) {
		specificPacket = [[GrowlRegisterNetworkPacket specificNetworkPacketForPacket:self] retain];
		
	} else if ([action caseInsensitiveCompare:@"NOTIFY"] == NSOrderedSame) {
		specificPacket = [[GrowlNotificationNetworkPacket specificNetworkPacketForPacket:self] retain];
	}
	
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

- (GrowlReadDirective)receivedHeaderItem:(GrowlNetworkHeaderItem *)headerItem
{
	NSLog(@"Header %@; value %@", headerName, headerValue);
}

- (GrowlReadDirective)parseHeader:(NSData *)inData
{
	NSError *error;
	GrowlNetworkHeaderItem *headerItem = [GrowlNetworkHeaderItem headerItemFromData:inData error:&error];
	if (headerItem) {
		return [self receivedHeaderItem:headerItem];
	
	} else {
		NSLog(@"Error is %@", error);
	}
}

#pragma mark Binary data
- (void)readHeaderOfNextBinaryChunk
{
	NSLog(@"Read next binary chunk");
	[socket readDataToData:[AsyncSocket CRLFData]
			   withTimeout:-1
					   tag:GrowlHeaderRead];
	
}

#pragma mark Complete
- (void)networkPacketReadComplete
{
	NSLog(@"Read complete");
}

#pragma mark Error
- (void)errorOccurred
{
	NSLog(@"Error occurred");
}

#pragma mark Incoming network processing

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)inHost port:(UInt16)inPort
{
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
					[self readNextHeader];
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
		case GrowlBinaryDataRead:
			switch ([self parseBinaryData:data]) {
				case GrowlReadDirective_SectionComplete:
					[self readNextHeader];
				case GrowlReadDirective_Continue:
					[self readMoreOfBinaryChunk];
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
	NSLog(@"didReadPartialDataOfLength: %@ Read %i: tag %i", sock, partialLength, tag);
}

/*
 This will be called whenever AsyncSocket is about to disconnect. In Echo Server,
 it does not do anything other than report what went wrong (this delegate method
 is the only place to get that information), but in a more serious app, this is
 a good place to do disaster-recovery by getting partially-read data. This is
 not, however, a good place to do cleanup. The socket must still exist when this
 method returns.
 */
-(void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	if (err != nil)
		NSLog (@"Socket %@ will disconnect. Error domain %@, code %d (%@).",
			   sock,
			   [err domain], [err code], [err localizedDescription]);
	else
		NSLog (@"Socket will disconnect. No error. unread: %@", [sock unreadData]);
}
@end
