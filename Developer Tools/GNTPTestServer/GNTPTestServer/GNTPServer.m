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

@interface GNTPServer ()

@property (nonatomic, retain) GCDAsyncSocket *localSocket;
@property (nonatomic, retain) NSMutableDictionary *socketsByGUID;
@property (nonatomic, retain) NSMutableDictionary *packetsByGUID;

@end

@implementation GNTPServer

@synthesize delegate = _delegate;
@synthesize localSocket = _localSocket;
@synthesize socketsByGUID = _socketsByGUID;
@synthesize packetsByGUID = _packetsByGUID;

-(id)init {
	if((self = [super init])){
		self.socketsByGUID = [NSMutableDictionary dictionary];
		self.packetsByGUID = [NSMutableDictionary dictionary];
	}
	return self;
}

-(void)startServer {
	self.localSocket = [[[GCDAsyncSocket alloc] initWithDelegate:self 
																  delegateQueue:dispatch_get_main_queue()] autorelease];
	[self.localSocket acceptOnInterface:@"localhost" 
									  port:23053 
									 error:nil];
}

-(void)stopServer {
	[self.localSocket disconnect];
	self.localSocket = nil;
	[self.packetsByGUID removeAllObjects];
	[self.socketsByGUID enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
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

- (void)dumpSocket:(GCDAsyncSocket*)sock
{
	NSString *guid = [[sock userData] retain];
	[sock disconnect];
	[self.socketsByGUID removeObjectForKey:guid];
	[self.packetsByGUID removeObjectForKey:guid];
	NSLog(@"count: %lu", [self.socketsByGUID count]);
}

- (void)dumpSocket:(GCDAsyncSocket*)sock
	  withErrorCode:(GrowlGNTPErrorCode)code
  errorDescription:(NSString*)description
{
	NSString *errorString = [NSString stringWithFormat:@"GNTP/1.0 -ERROR NONE\r\nError-Code: %ld\r\nError-Description: %@", code, description];
	NSData *errorData = [NSData dataWithBytes:[errorString UTF8String] length:[errorString length]];
	[sock writeData:errorData withTimeout:5.0 tag:-2];
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
						withErrorCode:GrowlGNTPInvalidRequestErrorCode
					errorDescription:[NSString stringWithFormat:@"Growl server does not understand action type: %@", action]];
				}
				
				//Setup the initial packet here
				if(packet){
					[packet setAction:action];
					[packet setKey:key];
					[packet setConnectedHost:[sock connectedHost]];
					[self.packetsByGUID setObject:packet forKey:[sock userData]];
					
					//Get our next read to value/tag
					readToData = [GNTPServer doubleCLRF];
					readToTag = 2;
				}
			}
		}else{
			/* Unsupported version of the spec */
			[self dumpSocket:sock
			 withErrorCode:GrowlGNTPUnknownProtocolVersionErrorCode
			errorDescription:[NSString stringWithFormat:@"Growl does not support version string: %@", [items objectAtIndex:0]]];
			return;
		}
	}else if(tag == 2){
		//Pass the data to the packet and get our next read data/tag/length
		NSString *guid = [sock userData];
		GNTPPacket *packet = [self.packetsByGUID objectForKey:guid];
		NSInteger result = [packet parseDataBlock:data];
		if(result > 0){
			//Segments in GNTP are all seperated by a double CLRF
			//Packet maintains its state, with sub classes providing specifics for the type of packet (ie, notes in a registration packet)
			readToTag = 2;
			readToData = [GNTPServer doubleCLRF];
		}else if(result < 0){
			//Dump socket/packet with appropriate error
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
				NSTimeInterval keepAliveFor = [packet requestedTimeAlive];
				if(keepAliveFor > 0.0)
					readToTag = -1;
				else
					readToTag = -2;
				
				if([packet keepAlive])
					NSLog(@"We should read to the end of GNTP/1.0");
				
				NSDictionary *growlDict = [packet convertedGrowlDict];
				if([packet isKindOfClass:[GNTPRegisterPacket class]]){
					[self.delegate registerWithDictionary:growlDict];
				}else if([packet isKindOfClass:[GNTPNotifyPacket class]]){
					[self.delegate notifyWithDictionary:growlDict];
				}
			}else{
				//Send error
				NSLog(@"Could not validate packet!");
				[self dumpSocket:sock 
					withErrorCode:GrowlGNTPInvalidRequestErrorCode
				errorDescription:@"Unable to validate packet"];
			}
		}
	}else if(tag == 101){
		//read in the rest of a websocket, and reply, and then setup a read of the first bit of the socket
	}else{
		//We shouldn't have an unknown read tag, dump the socket
	}
	
	//If we know what we are reading to next, read
	if(readToData && readToTag >= 0){
		[sock readDataToData:readToData
					withTimeout:5.0
							  tag:readToTag];
	}else if(readToTag >= 0 && readToLength >= 1){
		[sock readDataToLength:readToLength
					  withTimeout:5.0
								 tag:readToTag];
	}else {
		//The only question in here is if we have something to write out? eh...
		if(responseData && readToTag <= -1){
			[sock writeData:responseData withTimeout:5 tag:readToTag];
		}else{
			//If we dont have anything to write, dump socket
			[self dumpSocket:sock];
		}
	}
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	//Not sure if we need this
	if(tag == -2)
		[self dumpSocket:sock];
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
