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
#import "GNTPSubscribePacket.h"
#import "GNTPUtilities.h"
#import "GrowlGNTPDefines.h"
#import "GrowlDefines.h"
#import "GrowlDefinesInternal.h"
#import "GrowlWebSocketProxy.h"

#import "GrowlDispatchMutableDictionary.h"

//#define MULTITHREADED_GNTP_SERVER
#define GNTP_SOCKET_COUNT_LIMIT 200

@interface GNTPServer ()

@property (nonatomic, retain) GCDAsyncSocket *server;
@property (nonatomic, retain) NSString *interfaceString;
@property (nonatomic, retain) GrowlDispatchMutableDictionary *socketsByGUID;
@property (nonatomic, retain) GrowlDispatchMutableDictionary *packetsByGUID;
@property (nonatomic, retain) GrowlDispatchMutableDictionary *timeoutsByGUID;
@property (nonatomic, assign) dispatch_source_t timeoutTimer;

@property (nonatomic, assign) dispatch_queue_t parsingQueue;

@end

@implementation GNTPServer

@synthesize delegate = _delegate;
@synthesize server = _server;
@synthesize interfaceString = _interfaceString;
@synthesize socketsByGUID = _socketsByGUID;
@synthesize packetsByGUID = _packetsByGUID;
@synthesize timeoutsByGUID = _timeoutsByGUID;
@synthesize timeoutTimer = _timeoutTimer;

-(id)initWithInterface:(NSString *)interface {
	if((self = [super init])){
		NSString *dispatchQueueID = [NSString stringWithFormat:@"com.growl.GNTPServer.%@.", interface != nil ? interface : @"remote"];
		dispatch_queue_t dispatchQueue = dispatch_queue_create([[dispatchQueueID stringByAppendingString:@"dictionaryQueue"] UTF8String], DISPATCH_QUEUE_CONCURRENT);
#ifdef MULTITHREADED_GNTP_SERVER
		self.parsingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
#else
		self.parsingQueue = dispatch_queue_create([[dispatchQueueID stringByAppendingString:@"dictionaryQueue"] UTF8String], DISPATCH_QUEUE_SERIAL);
#endif
		self.socketsByGUID = [GrowlDispatchMutableDictionary dictionaryWithQueue:dispatchQueue];
		self.packetsByGUID = [GrowlDispatchMutableDictionary dictionaryWithQueue:dispatchQueue];
		self.timeoutsByGUID = [GrowlDispatchMutableDictionary dictionaryWithQueue:dispatchQueue];
		//retained in the dictionaries
		dispatch_release(dispatchQueue);
		self.interfaceString = interface;
		[self startTimeoutTimer];
	}
	return self;
}

-(void)dealloc {
	[self stopServer];
	[_socketsByGUID release]; _socketsByGUID = nil;
	[_packetsByGUID release]; _socketsByGUID = nil;
	[_timeoutsByGUID release]; _socketsByGUID = nil;
	
#ifndef MULTITHREADED_GNTP_SERVER
	dispatch_release(_parsingQueue);
	_parsingQueue = NULL;
#endif
	dispatch_source_cancel(self.timeoutTimer);
	
	[super dealloc];
}

-(void)startTimeoutTimer {
	if(self.timeoutTimer == NULL){
		self.timeoutTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _parsingQueue);
		
		dispatch_source_set_event_handler(self.timeoutTimer, ^{ @autoreleasepool {
			[self doTimeoutCheck];
		}});
		
		dispatch_source_t theTimeoutTimer = self.timeoutTimer;
		dispatch_source_set_cancel_handler(self.timeoutTimer, ^{
			dispatch_release(theTimeoutTimer);
			self.timeoutTimer = NULL;
		});
		
#define CHECK_TIME_NSEC (15l * NSEC_PER_SEC)
		dispatch_time_t tt = dispatch_time(DISPATCH_TIME_NOW, CHECK_TIME_NSEC);
		
		dispatch_source_set_timer(self.timeoutTimer, tt, CHECK_TIME_NSEC, 0);
		dispatch_resume(self.timeoutTimer);
	}
}

-(BOOL)startServer {
	if(self.server)
		return YES;
	
	self.server = [[[GCDAsyncSocket alloc] initWithDelegate:self 
															delegateQueue:_parsingQueue] autorelease];
	NSError *error = nil;
	if(![self.server acceptOnInterface:self.interfaceString
														port:GROWL_TCP_PORT 
													  error:&error])
	{
		NSLog(@"There was an error starting the server! %@", error);
		[self.server disconnect];
		self.server = nil;
		return NO;
	}
	return YES;
}

-(void)stopServer {
	if(!self.server)
		return;
	
	dispatch_async(_parsingQueue, ^{
		[self.server disconnect];
		self.server = nil;
		[self.packetsByGUID removeAllObjects];
		[[self.socketsByGUID allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			[obj disconnect];
		}];
		[self.socketsByGUID removeAllObjects];
	});
}

- (void)doTimeoutCheck {
	NSDictionary *timeoutDict = [self.timeoutsByGUID dictionaryCopy];
	NSMutableSet *guidsToDump = [NSMutableSet set];
	[timeoutDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if([obj isKindOfClass:[NSDate class]]){
			NSDate *timeout = obj;
			if([timeout compare:[NSDate date]] == NSOrderedAscending){
				[guidsToDump addObject:key];
			}
		}
	}];
	[guidsToDump enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
		//NSLog(@"Dumping socket with GUID %@ due to timeout", obj);
		[self dumpSocketByGUID:obj fromDisconnect:NO];
	}];
}

- (NSUInteger)socketCount {
	return [self.socketsByGUID objectCount];
}

- (void)dumpSocketByGUID:(NSString*)guid fromDisconnect:(BOOL)isDisconnected
{
	GCDAsyncSocket *sock = [self.socketsByGUID objectForKey:guid];
	if(!isDisconnected)
		[sock disconnect];
	[self.socketsByGUID removeObjectForKey:guid];
	[self.packetsByGUID removeObjectForKey:guid];
	[self.timeoutsByGUID removeObjectForKey:guid];
}

- (void)dumpSocket:(GCDAsyncSocket*)sock fromDisconnect:(BOOL)isDisconnected
{
	NSString *guid = [[sock userData] retain];
	[self dumpSocketByGUID:guid fromDisconnect:isDisconnected];
	[guid release];
}

- (void)dumpSocket:(GCDAsyncSocket*)sock
		  actionType:(NSString*)action
	  withErrorCode:(GrowlGNTPErrorCode)code
  errorDescription:(NSString*)description
{
	NSMutableString *errorString = [NSMutableString stringWithFormat:@"GNTP/1.0 -ERROR NONE\r\nError-Code: %ld\r\nError-Description: %@\r\n%@", code, description, [GNTPPacket originString]];
	if(action)
		[errorString appendFormat:@"Response-Action: %@\r\n", action];
	[errorString appendString:@"\r\n\r\n"];
	//NSLog(@"Write: %@", errorString);
	NSData *errorData = [NSData dataWithBytes:[errorString UTF8String] length:[errorString length]];
	[sock writeData:errorData withTimeout:5.0 tag:-2];
}

-(void)sendFeedback:(BOOL)clicked forDictionary:(NSDictionary*)dictionary {
	NSString *guid = [dictionary valueForKey:@"GNTPGUID"];
	//If there isn't a GUID, this wasn't a GNTPServer originated note
	//And we shouldn't worry about sending feedback
	if(guid){
		//Get our socket for sending the response
		GCDAsyncSocket *socket = [self.socketsByGUID objectForKey:guid];
		//If we dont have a socket, can't send feedback, so don't worry about it
		//The note might have been a different server instance
		if(socket){
			NSData *feedbackData = [GNTPNotifyPacket feedbackData:clicked forGrowlDictionary:dictionary];
			BOOL keepAlive = [dictionary objectForKey:@"GNTP-Keep-Alive"] ? [[dictionary objectForKey:@"GNTP-Keep-Alive"] boolValue] : NO;
			if(feedbackData){
				long writeTag = 0;
				if(!keepAlive)
					writeTag = -2;
				[socket writeData:feedbackData withTimeout:5.0 tag:writeTag];
			}else{
				/*If we have a socket, and we want to keep it alive
				 * not being able to send feedback isn't the end of the world
				 * Otherwise, just dump the socket
				 */
				if(!keepAlive)
					[self dumpSocket:socket fromDisconnect:NO];
			}
		}
	}
}
-(void)notificationClicked:(NSDictionary*)dictionary {
	dispatch_async(_parsingQueue, ^{
		[self sendFeedback:YES forDictionary:dictionary];
	});
}
-(void)notificationTimedOut:(NSDictionary*)dictionary {
	dispatch_async(_parsingQueue, ^{
		[self sendFeedback:NO forDictionary:dictionary];
	});
}

#pragma mark GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
	BOOL accept = NO;
	if([self.delegate respondsToSelector:@selector(totalSocketCount)]){
		if([self.delegate totalSocketCount] < GNTP_SOCKET_COUNT_LIMIT)
			accept = YES;
	}else if([self socketCount] < GNTP_SOCKET_COUNT_LIMIT){
		accept = YES;
	}
	if(accept)
	{
		NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString];
		[newSocket setUserData:guid];
		[newSocket setAutoDisconnectOnClosedReadStream:NO];
		[self.socketsByGUID setObject:newSocket forKey:guid];
		[newSocket readDataToLength:4
							 withTimeout:5.0f
										tag:0];
	}else{
		[newSocket disconnect];
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			NSLog(@"Too many sockets coming in, will dump any incoming sockets when we already have 200 open.  This message will only display once.");
		});
	}
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSData *readToData = nil;
	NSData *responseData = nil;
	NSUInteger readToLength = 0;
	NSTimeInterval keepAliveFor = 5.0;
	NSString *guid = [sock userData];
	long readToTag = -1;
	long writeToTag = 1;
	if(tag == 0){
		//Parse our first 4 bytes
		NSString *initialString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		
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

		}else if([initialString caseInsensitiveCompare:@"GET "] == NSOrderedSame){
			//The only good way to handle this is to proxy all our read/writes through a separate class
			//This is UGLY, but since GCDAsyncSocket isn't something I want to mess with subclassing, a proxy object is the only thing I can think of
#if GROWLHELPERAPP
			GrowlWebSocketProxy *proxySocket = [[[GrowlWebSocketProxy alloc] initWithSocket:sock] autorelease];
			[self.socketsByGUID setObject:proxySocket forKey:guid];
			sock = (GCDAsyncSocket*)proxySocket;

			//Now that that is all done, set our first read from the proxy socket, same as if we were on a fresh socket
			readToLength = 4;
			readToTag = 0;
#else
			[self dumpSocket:sock fromDisconnect:NO];
#endif
		}else{
			[self dumpSocket:sock
					actionType:nil
				withErrorCode:GrowlGNTPUnknownProtocolErrorCode
			errorDescription:[NSString stringWithFormat:@"Growl does not recognize the protocol beginning with %@", initialString]];
			return;
		}
	}else if(tag == 1){
		NSData *trimmedData = [NSData dataWithBytes:[data bytes] length:[data length] - 2];
		NSString *identifierLine = [[[NSString alloc] initWithCString:[trimmedData bytes] encoding:NSUTF8StringEncoding] autorelease];
		//NSLog(@"ID line: %@", identifierLine);
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
													  originKey:nil
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
					packet = [[[GNTPSubscribePacket alloc] init] autorelease];
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
					[packet setConnectedAddress:[sock connectedAddress]];
					[packet setGuid:guid];
					[self.packetsByGUID setObject:packet forKey:guid];
					
					//Get our next read to value/tag
					readToData = [GNTPUtilities doubleCRLF];
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
		GNTPPacket *packet = [[self.packetsByGUID objectForKey:guid] retain];
		//All our data in here is a double clrf trailed
		NSData *trimmedData = [NSData dataWithBytes:[data bytes] length:[data length] - [[GNTPUtilities doubleCRLF] length]];
		NSInteger result = [packet parsePossiblyEncryptedDataBlock:trimmedData];
		if(result > 0){
			//Segments in GNTP are all seperated by a double CLRF
			//Packet maintains its state, with sub classes providing specifics for the type of packet (ie, notes in a registration packet)
			readToTag = 2;
			readToData = [GNTPUtilities doubleCRLF];
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
					writeToTag = -1;
				else
					writeToTag = -2;
				
				if([packet keepAlive]){
					readToTag = 99;
					readToData = [GNTPUtilities gntpEndData];
					NSLog(@"We should read to the end of GNTP/1.0");
				}
				
				NSDictionary *growlDict = [packet growlDict];
				if([packet isKindOfClass:[GNTPRegisterPacket class]]){
					[self.delegate server:self registerWithDictionary:growlDict];
				}else if([packet isKindOfClass:[GNTPNotifyPacket class]]){
					GrowlNotificationResult notifyResult = [self.delegate server:self notifyWithDictionary:growlDict];
					switch (notifyResult) {
						case GrowlNotificationResultDisabled:
							[self dumpSocket:sock
									actionType:[packet action]
								withErrorCode:GrowlGNTPUserDisabledErrorCode
							errorDescription:[NSString stringWithFormat:@"Note %@ in %@ was disabled by the user", [growlDict objectForKey:GROWL_NOTIFICATION_NAME], 
													[growlDict objectForKey:GROWL_APP_NAME]]];
							responseData = nil;
							break;
						case GrowlNotificationResultNotRegistered:
							[self dumpSocket:sock
									actionType:[packet action]
								withErrorCode:GrowlGNTPUnknownNotificationErrorCode
							errorDescription:[NSString stringWithFormat:@"%@ is not registered for %@", [growlDict objectForKey:GROWL_NOTIFICATION_NAME], 
													[growlDict objectForKey:GROWL_APP_NAME]]];
							responseData = nil;
							break;
						case GrowlNotificationResultPosted:
						default:
							break;
					}
				}else if([packet isKindOfClass:[GNTPSubscribePacket class]]){
					dispatch_async(dispatch_get_main_queue(), ^{
						[self.delegate server:self subscribeWithDictionary:(GNTPSubscribePacket*)packet];
					});
				}
				//Whatever happened, we are done with it, let the server move on
				[self.packetsByGUID removeObjectForKey:guid];
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
		
	}else{
		//We shouldn't have an unknown read tag, dump the socket
		[self dumpSocket:sock fromDisconnect:NO];
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
	}
	if(responseData){
		[sock writeData:responseData withTimeout:keepAliveFor tag:writeToTag];
	}
	
	[self.timeoutsByGUID setObject:[NSDate dateWithTimeIntervalSinceNow:(keepAliveFor > 0.0) ? keepAliveFor : 5.0] forKey:guid];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	//Not sure if we need this
	if(tag == -2){
		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, _parsingQueue, ^(void){
			[self dumpSocket:sock fromDisconnect:NO];
		});
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
	[self dumpSocket:sock fromDisconnect:YES];
}

@end
