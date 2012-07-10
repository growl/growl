//
//  GNTPServer.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPServer.h"
#import "GNTPKey.h"
#import "NSStringAdditions.h"
#import "GNTPPacket.h"
#import "GNTPRegisterPacket.h"
#import "GNTPNotifyPacket.h"
#import "GrowlGNTPDefines.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"

#import "GrowlDispatchMutableDictionary.h"

@interface GNTPServer ()

@property (nonatomic, retain) GCDAsyncSocket *localSocket;
@property (nonatomic, retain) GrowlDispatchMutableDictionary *socketsByGUID;
@property (nonatomic, retain) GrowlDispatchMutableDictionary *packetsByGUID;

@end

@implementation GNTPServer

@synthesize delegate = _delegate;
@synthesize localSocket = _localSocket;
@synthesize socketsByGUID = _socketsByGUID;
@synthesize packetsByGUID = _packetsByGUID;

-(id)init {
	if((self = [super init])){
		dispatch_queue_t dispatchQueue = dispatch_queue_create("com.growl.GNTPServer.dictionaryQueue", DISPATCH_QUEUE_CONCURRENT);
		self.socketsByGUID = [GrowlDispatchMutableDictionary dictionaryWithQueue:dispatchQueue];
		self.packetsByGUID = [GrowlDispatchMutableDictionary dictionaryWithQueue:dispatchQueue];
		//retained in the dictionaries
		dispatch_release(dispatchQueue);
	}
	return self;
}

-(void)startServer {
	self.localSocket = [[[GCDAsyncSocket alloc] initWithDelegate:self 
																  delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)] autorelease];
	[self.localSocket acceptOnInterface:@"localhost" 
									  port:23053 
									 error:nil];
}

-(void)stopServer {
	[self.localSocket disconnect];
	self.localSocket = nil;
	[self.packetsByGUID removeAllObjects];
	[[self.socketsByGUID allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[obj disconnect];
	}];
	[self.socketsByGUID removeAllObjects];
}

+ (NSData*)doubleCLRF {
	static NSData *_doubleCLRF = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_doubleCLRF = [[NSData alloc] initWithBytes:"\x0D\x0A\x0D\x0A" length:4];
	});
	return _doubleCLRF;
}

+ (NSData*)gntpEndData {
	static NSData *_gntpEndData = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *endString = @"GNTP/1.0 END\r\n\r\n";
		_gntpEndData = [[NSData dataWithBytes:[endString UTF8String] length:[endString length]] retain];
	});
	return _gntpEndData;
}

- (void)dumpSocket:(GCDAsyncSocket*)sock
{
	NSString *guid = [[sock userData] retain];
	[sock disconnect];
	[self.socketsByGUID removeObjectForKey:guid];
	[self.packetsByGUID removeObjectForKey:guid];
	[guid release];
}

- (void)dumpSocket:(GCDAsyncSocket*)sock
		  actionType:(NSString*)action
	  withErrorCode:(GrowlGNTPErrorCode)code
  errorDescription:(NSString*)description
{
	NSMutableString *errorString = [NSMutableString stringWithFormat:@"GNTP/1.0 -ERROR NONE\r\nError-Code: %ld\r\nError-Description: %@\r\n", code, description];
	if(action)
		[errorString appendFormat:@"Response-Action: %@\r\n", action];
	[errorString appendString:@"\r\n"];
	NSData *errorData = [NSData dataWithBytes:[errorString UTF8String] length:[errorString length]];
	[sock writeData:errorData withTimeout:5.0 tag:-2];
}

-(void)sendFeedback:(BOOL)clicked forDictionary:(NSDictionary*)dictionary {
	NSString *guid = [dictionary valueForKey:@"GNTPGUID"];
	//Get our socket for sending the response
	GCDAsyncSocket *socket = [self.socketsByGUID objectForKey:guid];
	NSData *feedbackData = [GNTPNotifyPacket feedbackData:clicked forGrowlDictionary:dictionary];
	if(socket && feedbackData){
		long writeTag = 0;
		if(![[dictionary objectForKey:@"GNTP-Keep-Alive"] boolValue])
			writeTag = -2;
		[socket writeData:feedbackData withTimeout:5.0 tag:writeTag];
	}else{
		/*If we have a socket, and we want to keep it alive
		 * not being able to send feedback isn't the end of the world
		 * Otherwise, just dump the socket
		 */
		if(socket && ![[dictionary objectForKey:@"GNTP-Keep-Alive"] boolValue])
			[self dumpSocket:socket];
	}
}
-(void)notificationClicked:(NSDictionary*)dictionary {
	[self sendFeedback:YES forDictionary:dictionary];
}
-(void)notificationTimedOut:(NSDictionary*)dictionary {
	[self sendFeedback:NO forDictionary:dictionary];
}

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
	[newSocket setUserData:guid];
	[newSocket setAutoDisconnectOnClosedReadStream:NO];
	[self.socketsByGUID setObject:newSocket forKey:guid];
	[newSocket readDataToLength:4
						 withTimeout:5.0f
									tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSData *readToData = nil;
	NSData *responseData = nil;
	NSUInteger readToLength = 0;
	NSTimeInterval keepAliveFor = 5.0;
	long readToTag = -1;
	if(tag == 0){
		//Parse our first 4 bytes
		NSString *initialString = [NSString stringWithUTF8String:[data bytes]];
		if([initialString caseInsensitiveCompare:@"GNTP"] == NSOrderedSame){
			//Read the security header for testing it
			readToData = [GCDAsyncSocket CRLFData];
			readToTag = 1;
		}else if([initialString caseInsensitiveCompare:@"<Pol"] == NSOrderedSame){
			static NSData *_flashResponse = nil;
			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				NSMutableData *mutableResponse = [[[@"<?xml version=\"1.0\"?>"
																"<!DOCTYPE cross-domain-policy SYSTEM \"/xml/dtds/cross-domain-policy.dtd\">"
																"<cross-domain-policy> "
																"<site-control permitted-cross-domain-policies=\"master-only\"/>"
																"<allow-access-from domain=\"*\" to-ports=\"*\" />"
																"</cross-domain-policy>" dataUsingEncoding:NSUTF8StringEncoding] mutableCopy] autorelease];
				[mutableResponse appendData:[GCDAsyncSocket ZeroData]];
				_flashResponse = [mutableResponse copy];
			});
			responseData = _flashResponse;
			readToTag = -2;

		}/*else if([initialString caseInsensitiveCompare:@"GET "] == NSOrderedSame){
			//This needs us to read more data before we can finish the websocket
		   readToTag = 101;
		}*/else{
			[self dumpSocket:sock
					actionType:nil
				withErrorCode:GrowlGNTPUnknownProtocolErrorCode
			errorDescription:[NSString stringWithFormat:@"Growl does not recognize the protocol beginning with %@", initialString]];
			return;
		}
	}else if(tag == 1){
		NSData *trimmedData = [NSData dataWithBytes:[data bytes] length:[data length] - 2];
		NSString *identifierLine = [[[NSString alloc] initWithCString:[trimmedData bytes] encoding:NSUTF8StringEncoding] autorelease];
		NSArray *items = [identifierLine componentsSeparatedByString:@" "];
		NSString *action = nil;
		if ([items count] < 3) {
			/* We need at least version, action, encryption ID, so this identiifer line is invalid */
			NSLog(@"%@ doesn't have enough information...", identifierLine);
			
			[self dumpSocket:sock
					actionType:nil
				withErrorCode:GrowlGNTPRequiredHeaderMissingErrorCdoe
			errorDescription:[NSString stringWithFormat:@"Growl does not have enough information in %@ to parse", identifierLine]];
			return;
		}
		
		//NSLog(@"items: %@", items);
		/* GNTP was eaten by our first-four byte read, so we start at the version number, /1.0 */
		if ([[items objectAtIndex:0] isEqualToString:@"/1.0"]) {
			/* We only support version 1.0 at this time */
			action = [items objectAtIndex:1];
			BOOL authorized = YES;
			GrowlGNTPErrorCode errorCode = 0;
			NSString *errorDescription = nil;
			GNTPKey *key = [GNTPPacket keyForSecurityHeaders:items 
																errorCode:&errorCode 
															 description:&errorDescription];
			if(!key){
				//Even for a packet with no encryption or password, we should get back a GNTPKey if there was success
				authorized = NO;
				[self dumpSocket:sock
						actionType:action
					withErrorCode:errorCode 
				errorDescription:errorDescription];
			}else{
				if(![GNTPPacket isAuthorizedPacketType:action
														 withKey:key
													  forSocket:sock
													  errorCode:&errorCode 
													description:&errorDescription]){
					authorized = NO;
					[self dumpSocket:sock
							actionType:action
						withErrorCode:errorCode 
					errorDescription:errorDescription];
				}
			}
			
			if(authorized){
				GNTPPacket *packet = nil;
				//Build a packet for each specific type
				//Replace each of these with GNTPNotificationPacket, GNTPRegistrationPacket GNTPSubscriptionPacket
				if([action caseInsensitiveCompare:GrowlGNTPNotificationMessageType] == NSOrderedSame){
					packet = [[[GNTPNotifyPacket alloc] init] autorelease];
				}else if([action caseInsensitiveCompare:GrowlGNTPRegisterMessageType] == NSOrderedSame){
					packet = [[[GNTPRegisterPacket alloc] init] autorelease];					
				}else if([action caseInsensitiveCompare:GrowlGNTPSubscribeMessageType] == NSOrderedSame){
					packet = [[[GNTPPacket alloc] init] autorelease];
				}else{
					[self dumpSocket:sock
							actionType:action
						withErrorCode:GrowlGNTPInvalidRequestErrorCode
					errorDescription:[NSString stringWithFormat:@"Growl server does not understand action type: %@", action]];
				}
				
				//Setup the initial packet here
				if(packet){
					[packet setAction:action];
					[packet setKey:key];
					[packet setConnectedHost:[sock connectedHost]];
					[packet setGuid:[sock userData]];
					[self.packetsByGUID setObject:packet forKey:[sock userData]];
					
					//Get our next read to value/tag
					readToData = [GNTPServer doubleCLRF];
					readToTag = 2;
				}
			}
		}else{
			/* Unsupported version of the spec */
			[self dumpSocket:sock
					actionType:nil
				withErrorCode:GrowlGNTPUnknownProtocolVersionErrorCode
			errorDescription:[NSString stringWithFormat:@"Growl does not support version string: %@", [items objectAtIndex:0]]];
			return;
		}
	}else if(tag == 2){
		//Pass the data to the packet and get our next read data/tag/length
		NSString *guid = [sock userData];
		GNTPPacket *packet = [[self.packetsByGUID objectForKey:guid] retain];
		//All our data in here is a double clrf trailed
		NSData *trimmedData = [NSData dataWithBytes:[data bytes] length:[data length] - [[GNTPServer doubleCLRF] length]];
		NSInteger result = [packet parsePossiblyEncryptedDataBlock:trimmedData];
		if(result > 0){
			//Segments in GNTP are all seperated by a double CLRF
			//Packet maintains its state, with sub classes providing specifics for the type of packet (ie, notes in a registration packet)
			readToTag = 2;
			readToData = [GNTPServer doubleCLRF];
		}else if(result < 0){
			//Dump socket/packet with appropriate error
			NSLog(@"Could not validate packet!");
			[self dumpSocket:sock
					actionType:[packet action]
				withErrorCode:GrowlGNTPInvalidRequestErrorCode
			errorDescription:@"Unable to validate packet"];
		}else{
			/* Done reading the packet
			 *	validate it
			 *	respond ok/error to it
			 * convert it
			 * pass it off to core growl
			 * Determine if we need to hold socket open after reply:
			 * * If we need to send feedback later
			 * * If we are going to reuse this socket for another packet
			 */
			if([packet validate]){
				//Send ok
				responseData = [packet responseData];
				keepAliveFor = [packet requestedTimeAlive];
				if(keepAliveFor > 0.0)
					readToTag = -1;
				else
					readToTag = -2;
				
				if([packet keepAlive]){
					readToTag = 99;
					readToData = [GNTPServer gntpEndData];
					NSLog(@"We should read to the end of GNTP/1.0");
				}
				
				NSDictionary *growlDict = [packet growlDict];
				if([packet isKindOfClass:[GNTPRegisterPacket class]]){
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate registerWithDictionary:growlDict];
					});
				}else if([packet isKindOfClass:[GNTPNotifyPacket class]]){
					if([self.delegate isNoteRegistered:[growlDict objectForKey:GROWL_NOTIFICATION_NAME]
														 forApp:[growlDict objectForKey:GROWL_APP_NAME]
														 onHost:[growlDict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY]])
					{
						dispatch_async(dispatch_get_main_queue(), ^{
							[self.delegate notifyWithDictionary:growlDict];
						});
					}else{
						[self dumpSocket:sock
								actionType:[packet action]
							withErrorCode:GrowlGNTPUnknownNotificationErrorCode
						errorDescription:[NSString stringWithFormat:@"%@ is not registered for %@", [growlDict objectForKey:GROWL_NOTIFICATION_NAME], 
												[growlDict objectForKey:GROWL_APP_NAME]]];
					}
				}
				//Whatever happened, we are done with it, let the server move on
				[self.packetsByGUID removeObjectForKey:[packet guid]];
			}else{
				//Send error
				NSLog(@"Could not validate packet!");
				[self dumpSocket:sock
						actionType:[packet action]
					withErrorCode:GrowlGNTPInvalidRequestErrorCode
				errorDescription:@"Unable to validate packet"];
			}
		}
		[packet release];
	}else if(tag == 99){
		//We are reading in the end of a packet, and setting up to read the next
		//Dont care about the data read, just that we read it
		//Set up a new first 4 byte read so we can be on our way through the normal parse cycle
		//Yes, its redundant, at this point we should know its a gntp request, but dont want to force the machine to handle both ways
		readToLength = 4;
		readToTag = 0;
		
	}else if(tag == 101){
		//read in the rest of a websocket, and reply, and then setup a read of the first bit of the socket
		[self dumpSocket:sock];
	}else{
		//We shouldn't have an unknown read tag, dump the socket
		[self dumpSocket:sock];
	}
	
	//If we know what we are reading to next, read
	if(readToData && readToTag >= 0){
		[sock readDataToData:readToData
					withTimeout:keepAliveFor
							  tag:readToTag];
	}else if(readToTag >= 0 && readToLength >= 1){
		[sock readDataToLength:readToLength
					  withTimeout:keepAliveFor
								 tag:readToTag];
	}else {
		//The only question in here is if we have something to write out? eh...
		if(responseData && readToTag < -1){
			[sock writeData:responseData withTimeout:5 tag:readToTag];
		}else if(readToTag == -1){
			//We do nothing! Waiting to send feedback
		}else{
			//If we dont have anything to write, dump socket
			[self dumpSocket:sock];
		}
	}
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	//Not sure if we need this
	if(tag == -2){
		[self dumpSocket:sock];
	}
}

/* Both of these two methods ensure we aren't waiting too long on the next piece
 * We should always have setup a new read at the end of a previous read 
 * if the socket is going to be needed anymore
 */
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutReadWithTag:(long)tag
					  elapsed:(NSTimeInterval)elapsed
					bytesDone:(NSUInteger)length
{
	if(elapsed > 10.0f)
		return -1.0f;
	else
		return 1.0f;
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
					  elapsed:(NSTimeInterval)elapsed
					bytesDone:(NSUInteger)length
{
	if(elapsed > 10.0f)
		return -1.0f;
	else
		return 1.0f;
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
	//We might want to know about this
	//Check if the packet we have is finishable at its present point (ie, did we simply miss a binary block?)
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock 
						withError:(NSError *)err 
{
	//Clean up
	[self dumpSocket:sock];
}

@end
