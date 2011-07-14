//
//  GrowlGNTPPacket.m
//  Growl
//
//  Created by Evan Schoenberg on 9/6/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import "GrowlGNTPPacket.h"
#import "GrowlSubscribeGNTPPacket.h"
#import "GrowlNotificationGNTPPacket.h"
#import "GrowlRegisterGNTPPacket.h"
#import "GrowlCallbackGNTPPacket.h"
#import "NSStringAdditions.h"
#import "GrowlGNTPHeaderItem.h"
#import "ISO8601DateFormatter.h"
#import "GrowlApplicationAdditions.h"
#import "GNTPKey.h"
#import "GrowlDefinesInternal.h"
#import <SystemConfiguration/SCDynamicStoreCopySpecific.h>

#if GROWLHELPERAPP

#define CRLF "\x0D\x0A"

@interface GrowlGNTPPacket ()
- (id)initForSocket:(GCDAsyncSocket *)inSocket;
- (void)readNextHeader;
- (void)beginProcessingProtocolIdentifier;
- (void)networkPacketReadComplete;
@end

#endif

@implementation GrowlGNTPPacket

#if GROWLHELPERAPP

@synthesize action = mAction;
@synthesize key = mKey;
@synthesize encryptionAlgorithm;
#endif
@synthesize delegate = mDelegate;
#if GROWLHELPERAPP

+ (GrowlGNTPPacket *)networkPacketForSocket:(GCDAsyncSocket *)inSocket
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
	[specificPacket setPacketID:[packet packetID]];
   [specificPacket setKey:[packet key]];

	return specificPacket;
}

- (id)initForSocket:(GCDAsyncSocket *)inSocket
{
	if ((self = [self init])) {
		socket = [inSocket retain];
		[socket synchronouslySetDelegate:self];
		
		binaryDataByIdentifier = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	if ([socket delegate] == self)
		[socket setDelegate:nil];

	[socket release];
	[specificPacket release];
	[mAction release];
	[binaryDataByIdentifier release];
	[pendingBinaryIdentifiers release];
	[packetID release];
	[customHeaders release];

	[super dealloc];
}

- (GCDAsyncSocket *)socket
{
	return socket;
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
- (void)setPacketID:(NSString *)inPacketID
{
	if (packetID)
		[[self delegate] packet:self willChangePacketIDFrom:packetID to:inPacketID];
	[packetID autorelease];
	packetID = [inPacketID retain];
}

- (GrowlPacketType)packetType
{
	if ([mAction caseInsensitiveCompare:GrowlGNTPSubscribeMessageType] == NSOrderedSame)
		return GrowlSubscribePacketType;
	else if ([mAction caseInsensitiveCompare:GrowlGNTPRegisterMessageType] == NSOrderedSame)
		return GrowlRegisterPacketType;
	else if ([mAction caseInsensitiveCompare:GrowlGNTPNotificationMessageType] == NSOrderedSame)
		return GrowlNotifyPacketType;
	else if ([mAction caseInsensitiveCompare:GrowlGNTPCallbackTypeHeader] == NSOrderedSame)
		return GrowlCallbackPacketType;
	else if ([mAction caseInsensitiveCompare:GrowlGNTPOKResponseType] == NSOrderedSame)
		return GrowlOKPacketType;
	else
		return GrowlUnknownPacketType;
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
	[socket readDataToData:[GCDAsyncSocket CRLFData]
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
	// This is stupid, yes.  But you cannot put a \0 into a string literal under LLVM without
	// generating warnings, so we have to do this trick to avoid -Wall -Werror failing.
	[socket readDataToData:[[NSString stringWithFormat:@"%c", 0] dataUsingEncoding:NSUTF8StringEncoding]
			   withTimeout:-1
					   tag:GrowlFlashPolicyRequestRead];
}

- (void)respondToFlashPolicyRequest
{
	// Same stupid compiler trick as above.
	NSData *responseData = [[NSString stringWithFormat:
						    @"<?xml version=\"1.0\"?>"
							 "<!DOCTYPE cross-domain-policy SYSTEM \"/xml/dtds/cross-domain-policy.dtd\">"
							 "<cross-domain-policy> "
							 "<site-control permitted-cross-domain-policies=\"master-only\"/>"
							 "<allow-access-from domain=\"*\" to-ports=\"*\" />"
							 "</cross-domain-policy>%c",0] dataUsingEncoding:NSUTF8StringEncoding];
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

   NSInteger errorCode = 0;
   NSString *errorDescription = nil;

	NSLog(@"items: %@", items);
	/* GNTP was eaten by our first-four byte read, so we start at the version number, /1.0 */
	if ([[items objectAtIndex:0] isEqualToString:@"/1.0"]) {
		/* We only support version 1.0 at this time */
		[self setAction:[items objectAtIndex:1]];
		
		GNTPKey *key = [[[GNTPKey alloc] init] autorelease];
		
		NSArray *encryptionSubstrings = [[items objectAtIndex:2] componentsSeparatedByString:@":"];
		NSString *packetEncryptionAlgorithm = [encryptionSubstrings objectAtIndex:0];
      
      if(![packetEncryptionAlgorithm isEqual:GNTPNone] && [[[self socket] connectedHost] isLocalHost]){
         NSLog(@"LocalHost with encryption, for now ignoring");
      }
      
      if([GNTPKey isSupportedEncryptionAlgorithm:packetEncryptionAlgorithm])
      {
         [key setEncryptionAlgorithm:[GNTPKey encryptionAlgorithmFromString:packetEncryptionAlgorithm]]; //this should be None if there is only one item
         if([encryptionSubstrings count] == 2)
            [key setIV:HexUnencode([encryptionSubstrings objectAtIndex:1])];
         else {
            if ([key encryptionAlgorithm] != GNTPNone) {
               errorCode = GrowlGNTPUnauthorizedErrorCode;
               errorDescription = NSLocalizedString(@"Missing initialization vector for encryption", /*comment*/ @"GNTP packet parsing error");
            }
         }
      }
      
      BOOL hashStringError = NO;
      if([items count] == 4)
      {
         NSArray *keySubstrings = [[items objectAtIndex:3] componentsSeparatedByString:@":"];
         NSString *keyHashAlgorithm = [keySubstrings objectAtIndex:0];
         if([GNTPKey isSupportedHashAlgorithm:keyHashAlgorithm]) {
            [key setHashAlgorithm:[GNTPKey hashingAlgorithmFromString:keyHashAlgorithm]];
            if([keySubstrings count] == 2) {
               NSArray *keyHashStrings = [[keySubstrings objectAtIndex:1] componentsSeparatedByString:@"."];
               if([keyHashStrings count] == 2) {
                  //[key setKeyHash:HexUnencode([keyHashStrings objectAtIndex:0])];
                  [key setSalt:HexUnencode([[keyHashStrings objectAtIndex:1] substringWithRange:NSMakeRange(0, [[keyHashStrings objectAtIndex:1] length] - 2)])];
                  [key setPassword:[[GrowlPreferencesController sharedController] remotePassword]];
                  NSData *IV = [key IV];
                  [key generateKey];
                  if(IV)
                     [key setIV:IV];

				  if ([[keyHashStrings objectAtIndex:0] caseInsensitiveCompare:HexEncode([key keyHash])] != NSOrderedSame)
                     hashStringError = YES;
               }
               else 
                  hashStringError = YES;
            }
			else
				 hashStringError = YES;
         }
		 else
            hashStringError = YES;
      }
      
      if (([items count] < 4 && ([key encryptionAlgorithm] != GNTPNone || ![[[self socket] connectedHost] isLocalHost])) ||
          hashStringError) 
      {
         NSLog(@"There was a missing <hashalgorithm>:<keyHash>.<keySalt> with encryption or remote, set error and return appropriately");
         errorCode = GrowlGNTPUnauthorizedErrorCode;
         errorDescription = NSLocalizedString(@"Missing, malformed, or invalid key hash string", /*comment*/ @"GNTP packet parsing error");
      }
      
      if(!errorDescription && errorCode == 0)
      {
         [self setKey:key];
         return YES;
      }
	}else {
      NSLog(@"Invalid protocol version");
      errorCode = GrowlGNTPUnknownProtocolVersionErrorCode;
      errorDescription = NSLocalizedString(@"Invalid protocol version.  Only version 1.0 is supported", /*comment*/ @"GNTP packet parsing error");
   }

   if(errorCode == 0 && !errorDescription) {
      errorCode = GrowlGNTPInvalidRequestErrorCode;
      errorDescription = NSLocalizedString(@"Somehow we got here parsing the protocol identifier without an error, this should be impossible, either its valid or its not", /*comment*/ @"GNTP packet parsing error");
   }
   
   [self setError:[NSError errorWithDomain:GROWL_NETWORK_DOMAIN
                                      code:errorCode
                                  userInfo:[NSDictionary dictionaryWithObject:errorDescription forKey:NSLocalizedFailureReasonErrorKey]]];
	return NO;
}

- (void)configureToParsePacket
{
	if([mAction caseInsensitiveCompare:@"SUBSCRIBE"] == NSOrderedSame) {
		specificPacket = [[GrowlSubscribeGNTPPacket specificNetworkPacketForPacket:self] retain];
		
	} else if ([mAction caseInsensitiveCompare:@"REGISTER"] == NSOrderedSame) {
		specificPacket = [[GrowlRegisterGNTPPacket specificNetworkPacketForPacket:self] retain];
		
	} else if ([mAction caseInsensitiveCompare:@"NOTIFY"] == NSOrderedSame) {
		specificPacket = [[GrowlNotificationGNTPPacket specificNetworkPacketForPacket:self] retain];

	} else if ([mAction caseInsensitiveCompare:@"-CALLBACK"] == NSOrderedSame) {
		specificPacket = [[GrowlCallbackGNTPPacket specificNetworkPacketForPacket:self] retain];

	} else if ([mAction caseInsensitiveCompare:@"-OK"] == NSOrderedSame) {
		/* An OK response can be silently dropped */
		[self networkPacketReadComplete];

	} else if ([mAction caseInsensitiveCompare:@"-ERROR"] == NSOrderedSame) {
		NSLog(@"%@: Error :(", self);
		//XXX
/*		specificPacket = [[GrowlErrorGNTPPacket specificNetworkPacketForPacket:self] retain]; */
	} else {
		NSLog(@"Unknown request type: %@", mAction);
	}


	//Get the specific packet started if we made one; it'll take it from there
	[specificPacket readNextHeader];	
}

#pragma mark Headers
- (void)readNextHeader
{
	[socket readDataToData:[GCDAsyncSocket CRLFData]
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
   GrowlReadDirective directive = GrowlReadDirective_Error;
	if([[self key] encryptionAlgorithm] != GNTPNone && ![inData isEqualToData:[GCDAsyncSocket CRLFData]])
   {
	   //not really thrilled with doing it this way, but there's a CRLF being included in the data that's getting passed to decrypt which is causing CCCrypt to throw
	   //a kCCParamError
	   NSRange truncationRange = NSMakeRange(0, [inData length]-2);
	   NSRange crlfRange = NSMakeRange([inData length]-2, 2);
	   NSData *crlf = [inData subdataWithRange:crlfRange];
	   NSData *truncatedData = inData;
	   if([crlf isEqualToData:[GCDAsyncSocket CRLFData]])
		   truncatedData = [inData subdataWithRange:truncationRange];
	   
	   NSData *decryptedData = [[self key] decrypt:truncatedData];
      NSString *allHeaders = [[[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding] autorelease];
      NSMutableArray *splitHeaders = [[[allHeaders componentsSeparatedByString:@CRLF] mutableCopy] autorelease];
      [splitHeaders removeLastObject];
      
      for(NSString *header in splitHeaders){
         NSData *headerData = nil;
         NSMutableData *mData = [[[header dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
         [mData appendData:[GCDAsyncSocket CRLFData]];
         headerData = mData;
         
         if(headerData)
         {
            GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:headerData error:&anError];
            if (headerItem) {
               directive = [self receivedHeaderItem:headerItem];
               
            } else {
               [self setError:anError];
               return GrowlReadDirective_Error;
            }            
         }
      }
   } else {
		
		GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:inData error:&anError];
		if (headerItem) {
			directive = [self receivedHeaderItem:headerItem];
			
		} else {
			[self setError:anError];
			return GrowlReadDirective_Error;
		}
	}
   return directive;
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
	NSMutableArray *array = [NSMutableArray array];
	[array addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Response-Action"
													   value:[self action]]];
	if (customHeaders)
		[array addObjectsFromArray:customHeaders];

	return array;
}

#endif

+ (void)addSentAndReceivedHeadersFromDict:(NSDictionary *)dict toArray:(NSMutableArray *)headersArray
{
	NSString *hostName = (NSString*)SCDynamicStoreCopyLocalHostName(NULL);
	if ([hostName hasSuffix:@".local"]) {
		hostName = [hostName substringToIndex:([hostName length] - [@".local" length])];
	}

	/* Previous received headers */
	for (NSString *received in [dict valueForKey:GROWL_NOTIFICATION_GNTP_RECEIVED]) {
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Received" value:received]];
	}
	/* New received header */
	if ([dict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY]) {
		ISO8601DateFormatter *formatter = [[[ISO8601DateFormatter alloc] init] autorelease];
		NSString *nowAsISO8601 = [formatter stringFromDate:[NSDate date]];

		/* Received: From <hostname> by <hostname> [with Growl] [id <identifier>]; <ISO 8601 date> */
		NSString *nextReceived = [NSString stringWithFormat:@"From %@ by %@ with Growl%@; %@",
					[dict valueForKey:GROWL_NOTIFICATION_GNTP_SENT_BY], hostName, 
					([dict valueForKey:GROWL_NOTIFICATION_INTERNAL_ID] ? [NSString stringWithFormat:@" id %@", [dict valueForKey:GROWL_NOTIFICATION_INTERNAL_ID]] : @""),
					nowAsISO8601];
		
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Received" value:nextReceived]];
	}
	
	/* New Sent-By header: Sent-By: <hostname> */
	[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Sent-By" value:hostName]];
	
	if (![dict objectForKey:GROWL_GNTP_ORIGIN_MACHINE]) {
		/* No origin machine --> We are the origin */
		static BOOL determinedMachineInfo = NO;
		static NSString *growlVersion = nil;
		static NSString *platformVersion = nil;
		
		if (!determinedMachineInfo) {
			unsigned major, minor, bugFix;
			[NSApp getSystemVersionMajor:&major minor:&minor bugFix:&bugFix];
		
			platformVersion = [[NSString stringWithFormat:@"%u.%u.%u", major, minor, bugFix] retain];
			growlVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey] retain];
			determinedMachineInfo = YES;
		}
		
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Origin-Machine-Name" value:hostName]];
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Origin-Software-Name" value:@"Growl"]];
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Origin-Software-Version" value:growlVersion]];
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Origin-Platform-Name" value:@"Mac OS X"]];
		[headersArray addObject:[GrowlGNTPHeaderItem headerItemWithName:@"Origin-Platform-Version" value:platformVersion]];
	}
}

#if GROWLHELPERAPP

/*!
 * @brief Return YES if this packet has previously been received by this host
 *
 * This is used to prevent infinite sending loops
 */
- (BOOL)hasBeenReceivedPreviously
{
	NSArray *receivedHeaders = [[self growlDictionary] objectForKey:GROWL_NOTIFICATION_GNTP_RECEIVED];
	NSString *myHostString;

	NSString *hostName = (NSString*)SCDynamicStoreCopyLocalHostName(NULL);
	if ([hostName hasSuffix:@".local"]) {
		hostName = [hostName substringToIndex:([hostName length] - [@".local" length])];
	}
	
	/* Check if this host received it previously */
	myHostString = [NSString stringWithFormat:@"by %@", hostName];
	for (NSString *receivedString in receivedHeaders) {
		if ([receivedString rangeOfString:myHostString].location != NSNotFound)
			return YES;
	}

	/* Check if this host sent it previously */
	myHostString = [NSString stringWithFormat:@"From %@", hostName];
	for (NSString *receivedString in receivedHeaders) {
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
	[socket readDataToData:[GCDAsyncSocket CRLFData]
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
   NSData *decryptedData = inData;
   if([[self key] encryptionAlgorithm] != GNTPNone && ![inData isEqualToData:[GCDAsyncSocket CRLFData]])
   {
      decryptedData = [[self key] decrypt:inData];
   }
	[binaryDataByIdentifier setObject:decryptedData
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
	
	NSData *endData = [[NSString stringWithFormat:@"" CRLF CRLF] dataUsingEncoding:NSUTF8StringEncoding];	

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
		   [[self error] domain], (int)[[self error] code], [[self error] localizedDescription]);
	[[self delegate] packet:self failedReadingWithError:[self error]];

	[socket disconnectAfterWriting];
}

#pragma mark Dictionary Representation
- (NSDictionary *)growlDictionary
{
	if (specificPacket)
		return [specificPacket growlDictionary];
	else
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[self packetID], GROWL_NOTIFICATION_INTERNAL_ID,
				nil];
}

#pragma mark Incoming network processing

- (void)setWasInitiatedLocally:(BOOL)inWasInitiatedLocally
{
	wasInitiatedLocally = inWasInitiatedLocally;
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
#ifdef DEBUG
	NSString *received = [[[NSString alloc] initWithData:data
												encoding:NSUTF8StringEncoding] autorelease];
	received = [received stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSLog(@"Recv: \"%@\"", received);
#endif

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
			}else{
            [self errorOccurred];
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
 This will be called whenever AsyncSocket is about to disconnect. This is
 a good place to do disaster-recovery by getting partially-read data. This is
 not, however, a good place to do cleanup. The socket must still exist when this
 method returns.
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
	if (err != nil) {
		[self setError:err];
		[self errorOccurred];
	} else {
		/* Treat the packet as complete if it is disconnected without an error. */
		[self networkPacketReadComplete];
	}
	
	[[self delegate] packetDidDisconnect:self];
}

#endif

#pragma mark GrowlGNTPPacketDelegate
/*!
 * @brief Called by our specific packet; we'll pass it on to our delegate
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

- (void)packet:(GrowlGNTPPacket *)packet willChangePacketIDFrom:(NSString *)oldPacketID to:(NSString *)newPacketID
{
	[[self delegate] packet:self willChangePacketIDFrom:oldPacketID to:newPacketID];
}

#pragma mark -

#if GROWLHELPERAPP

#import "GrowlDefines.h"
- (NSString *)description
{
	//we copy and remove the icon data because...well....looking at the data doesn't really help us
	NSMutableDictionary *growlDictionary = [[[self growlDictionary] mutableCopy] autorelease];
   [growlDictionary removeObjectForKey:GROWL_APP_ICON_DATA];
	[growlDictionary removeObjectForKey:GROWL_NOTIFICATION_ICON_DATA];
	if (specificPacket)
		return [NSString stringWithFormat:@"<%@ %x: %@ --> %@>", NSStringFromClass([self class]), self, growlDictionary, specificPacket];
	else
		return [NSString stringWithFormat:@"<%@ %x: %@>", NSStringFromClass([self class]), self, growlDictionary];
}

#endif

@end
