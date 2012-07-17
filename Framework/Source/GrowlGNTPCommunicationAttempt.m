//
//  GrowlGNTPCommunicationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPCommunicationAttempt.h"

#import "GNTPPacket.h"
#import "GNTPUtilities.h"
#import "GNTPPacket.h"
#import "GrowlDefinesInternal.h"
#import "NSStringAdditions.h"

#import "GCDAsyncSocket.h"
#import "GNTPKey.h"

@interface GrowlGNTPCommunicationAttempt ()

@property(nonatomic, retain) NSString *responseParseErrorString;
@property(nonatomic, retain) NSString *bogusResponse;

@end

enum {
	GrowlGNTPCommAttemptReadPhaseFirstResponseLine,
	GrowlGNTPCommAttemptReadPhaseResponseHeaderLine,
	GrowlGNTPCommAttemptReadPhaseEncrypted,
	GrowlGNTPCommAttemptReadExtraPacketData,
};

enum {
	GrowlGNTPCommAttemptReadFeedback = 1,
	GrowlGNTPCommAttemptReadError,
	GrowlGNTPCommAttemptReadOk,
};

@implementation GrowlGNTPCommunicationAttempt

@synthesize responseParseErrorString;
@synthesize bogusResponse;
@synthesize host;
@synthesize password;
@synthesize callbackHeaderItems;

@synthesize connection;
@synthesize addressData = _addressData;

@synthesize key = _key;

-(id)initWithDictionary:(NSDictionary *)dict {
	if((self = [super initWithDictionary:dict])){
		attemptSucceeded = NO;
	}
	return self;
}

- (void) dealloc {
	self.callbackHeaderItems = nil;
	
	[socket synchronouslySetDelegate:nil];
	[socket release];
	socket = nil;
	
	[super dealloc];
}

-(NSData*)outgoingData {
	NSAssert1(NO, @"Subclass dropped the ball: Communication attempt %@  does not know how to create a GNTP packet", self);
	return nil;
}

- (BOOL) expectsCallback {
	return NO;
}

- (void) failed {
	//NSLog(@"%@ failed because %@", self, self.error);
	[super failed];
	[socket release];
	socket = nil;
}

- (void) couldNotParseResponseWithReason:(NSString *)reason responseString:(NSString *)responseString {
	self.responseParseErrorString = reason;
	self.bogusResponse = responseParseErrorString;
}

- (void) begin {
	NSAssert1(socket == nil, @"%@ appears to already be sending!", self);
	//GrowlGNTPOutgoingPacket *packet = [self packet];
	socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	
	responseReadType = -1;
	
	NSError *errorReturned = nil;
	BOOL result = NO;
	if(self.addressData){
		result = [socket connectToAddress:self.addressData
									 withTimeout:15.0
											 error:&errorReturned];
	}else{
		NSString *hostToUse = nil;
		if(!self.host || [host isLocalHost])
			hostToUse = @"localhost";
		else
			hostToUse = host;
		
		result = [socket connectToHost:hostToUse
										onPort:GROWL_TCP_PORT
								 withTimeout:15.0
										 error:&errorReturned];
	}
	if(!result){
		NSLog(@"Failed to connect: %@", errorReturned);
		self.error = errorReturned;
		[self failed];
	}
}

/* We read to a triple CRLF, one for the last line of the packet, 2 for finishing the packet */ 
- (void) readRestOfPacket:(GCDAsyncSocket*)sock
{
	static NSData *triple = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSMutableData *data = [NSMutableData dataWithData:[GCDAsyncSocket CRLFData]];
		[data appendData:[GCDAsyncSocket CRLFData]];
		[data appendData:[GCDAsyncSocket CRLFData]];
		triple = [data copy];
	});
	[sock readDataToData:triple withTimeout: -1 tag:GrowlGNTPCommAttemptReadExtraPacketData];
}

- (void) readOneLineFromSocket:(GCDAsyncSocket *)sock tag:(long)tag {
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:-1 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {	
	if(password){
		self.key = [[GNTPKey alloc] initWithPassword:password
												 hashAlgorithm:GNTPSHA512
										 encryptionAlgorithm:GNTPNone];
		[self.key generateSalt];
		[self.key generateKey];
	}else{
		self.key = [[GNTPKey alloc] initWithPassword:nil
												 hashAlgorithm:GNTPNoHash
										 encryptionAlgorithm:GNTPNone];
	}
	
	NSData *outData = [self outgoingData];
	if(outData){
		[socket writeData:outData withTimeout:5.0 tag:-1];
		[self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseFirstResponseLine];
	}else{
		self.error = [NSError errorWithDomain:@"GNTPErrorDomain" code:GrowlGNTPInternalServerErrorErrorCode userInfo:nil];
		[self failed];
	}
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSString *readString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
   //NSLog(@"read: %@", readString);
   
   if(tag == GrowlGNTPCommAttemptReadExtraPacketData){
      //No op, we possibly told it to read more after this
      //NSLog(@"Exhausting packet");
   }else if (tag == GrowlGNTPCommAttemptReadPhaseFirstResponseLine) {
      NSArray *components = [readString componentsSeparatedByString:@" "];
      if([components count] < 3){
         NSLog(@"Not enough components in initial header");
         [self couldNotParseResponseWithReason:@"Not enough components in initial header" responseString:readString];
         [socket disconnect];
         return;
      }
      if (![[components objectAtIndex:0] caseInsensitiveCompare:@"GNTP/1.0"] == NSOrderedSame){
         NSLog(@"Response from Growl or other notification system was patent nonsense");
         [self couldNotParseResponseWithReason:@"Response from Growl or other notification system was patent nonsense" responseString:readString];
         [socket disconnect];
         return;
      }
		
		NSString *withoutGNTP = [readString substringFromIndex:[@"GNTP" length]];
		components = [withoutGNTP componentsSeparatedByString:@" "];
		GNTPKey *returnKey = [GNTPPacket keyForSecurityHeaders:components 
																	errorCode:nil 
																 description:nil];
		if(returnKey){
			NSString *responseType = [components objectAtIndex:1];
			if([GNTPPacket isAuthorizedPacketType:responseType
													withKey:returnKey
												 originKey:self.key
												 forSocket:socket
												 errorCode:nil
											  description:nil]){
				BOOL closeConnection = NO;
				BOOL decrypt = ([returnKey encryptionAlgorithm] != GNTPNone);
				if ([responseType caseInsensitiveCompare:GrowlGNTPOKResponseType] == NSOrderedSame) {
					//Need to read more data for subscription, result includes ttl for system
					attemptSucceeded = YES;
					if([self isKindOfClass:NSClassFromString(@"GrowlGNTPSubscriptionAttempt")]){
						//We need the ok packet's headers to make this work
						responseReadType = GrowlGNTPCommAttemptReadOk;
						if(decrypt){
							[socket readDataToData:[GNTPUtilities doubleCRLF] withTimeout:5.0 tag:GrowlGNTPCommAttemptReadPhaseEncrypted];
						}else{
							[self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
						}
					}else{
						[self succeeded];
						
						[self readRestOfPacket:socket];
						closeConnection = ![self expectsCallback];
						if(!closeConnection){
							[self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseFirstResponseLine];
					}
					}
				} else if ([responseType caseInsensitiveCompare:GrowlGNTPErrorResponseType] == NSOrderedSame) {            
					/* We need to know what we are getting for an error, which is in a seperate header */
					responseReadType = GrowlGNTPCommAttemptReadError;
					if(decrypt){
						[socket readDataToData:[GNTPUtilities doubleCRLF] withTimeout:5.0 tag:GrowlGNTPCommAttemptReadPhaseEncrypted];
					}else{
						[self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
					}
				} else if ([responseType caseInsensitiveCompare:GrowlGNTPCallbackTypeHeader] == NSOrderedSame) {         
					responseReadType = GrowlGNTPCommAttemptReadFeedback;
					if(decrypt){
						[socket readDataToData:[GNTPUtilities doubleCRLF] withTimeout:5.0 tag:GrowlGNTPCommAttemptReadPhaseEncrypted];
					}else{
						[self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
					}
				} else {
					[self couldNotParseResponseWithReason:[NSString stringWithFormat:@"Unrecognized response type: %@", responseType] responseString:readString];
					closeConnection = YES;
				}
				
				if (closeConnection){
					[socket disconnect];
					[self finished];
					return;
				}
			}else{
				[self couldNotParseResponseWithReason:@"Unable to validate key" responseString:readString];
				[socket disconnect];
				return;
			}
		}else{
			[self couldNotParseResponseWithReason:@"Unable to generate key from security header" responseString:readString];
			[socket disconnect];
			return;
		}
      
	} else if (tag == GrowlGNTPCommAttemptReadPhaseResponseHeaderLine) {
		NSData *trimmed = [NSData dataWithBytes:[data bytes] length:[data length] - [[GCDAsyncSocket CRLFData] length]];
		NSString *header = [trimmed length] > 0 ? [NSString stringWithUTF8String:[trimmed bytes]] : @"";
		if([self parseHeader:header]){
			[self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
		}
	} else if (tag == GrowlGNTPCommAttemptReadPhaseEncrypted){
		//Trim and decrypt
		NSData *decrypted = [self.key decrypt:[NSData dataWithBytes:[data bytes] length:[data length] - [[GNTPUtilities doubleCRLF] length]]];
		NSString *headersString = [NSString stringWithUTF8String:[decrypted bytes]];
		NSArray *headerArray = [headersString componentsSeparatedByString:@"\r\n"];
		[headerArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			//Components seperated by string creates strings without the \r\n, add them back on so it behaves the same as the above function;
			if(![self parseHeader:obj])
				*stop = YES;
		}];
	}
}

- (BOOL)parseHeader:(NSString*)string {
	//NSLog(@"%@", string);
	NSString *headerKey = [GNTPPacket headerKeyFromHeader:string];
	NSString *headerValue = [GNTPPacket headerValueFromHeader:string];
	if (headerKey && headerValue){
		if(!callbackHeaderItems)
			self.callbackHeaderItems = [NSMutableDictionary dictionary];
		[callbackHeaderItems setObject:headerValue forKey:headerKey];
		return YES;
	}else{
		//Empty line: End of headers.
		switch (responseReadType) {
			case GrowlGNTPCommAttemptReadError:
				[self parseError];
				break;
			case GrowlGNTPCommAttemptReadFeedback:
				[self parseFeedback];
				break;
			case GrowlGNTPCommAttemptReadOk:
				[self succeeded];
				break;
			default:
				//We shouldn't be here, only packets we should be reading responses for is feedback and error
				break;
		}
		[self finished];
		[socket disconnect];
		return NO;
	}
}

- (void)parseError
{
   //We need error code, and error description
   __block NSString *code = nil;
   __block NSString *description = nil;
   [callbackHeaderItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if([key caseInsensitiveCompare:@"Error-Code"] == NSOrderedSame)
			code = obj;
		if([key caseInsensitiveCompare:@"Error-Description"] == NSOrderedSame)
			description = obj;
		
		if(code != nil && description != nil)
			*stop = YES;
	}];
	
	if(code){
		GrowlGNTPErrorCode errCode = (GrowlGNTPErrorCode)[code integerValue];
		if(errCode == GrowlGNTPUserDisabledErrorCode)
			[self stopAttempts];
		if((errCode == GrowlGNTPUnknownApplicationErrorCode || 
			 errCode == GrowlGNTPUnknownNotificationErrorCode) &&
			[self isKindOfClass:NSClassFromString(@"GrowlGNTPNotificationAttempt")]){
			NSLog(@"Failed to notify due to missing registration, queue and reregister");
			[self queueAndReregister];
		}
	}else{
		NSLog(@"No error code, assuming failed");
		[self failed];
	}
}

- (void)parseFeedback
{
   __block NSString *result = nil;
   __block NSString *context = nil;
   __block NSString *contextType = nil;
   [callbackHeaderItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if([key caseInsensitiveCompare:GrowlGNTPNotificationCallbackResult] == NSOrderedSame)
			result = obj;
		if([key caseInsensitiveCompare:GrowlGNTPNotificationCallbackContext] == NSOrderedSame)
			context = obj;
		if([key caseInsensitiveCompare:GrowlGNTPNotificationCallbackContextType] == NSOrderedSame)
			contextType = obj;
		
		if(result != nil && context != nil && contextType != nil)
			*stop = YES;
   }];
   
	if(!result || !context || !contextType){
		self.responseParseErrorString = @"Unable to parse feedback response";
		return;
	}
	
   int resultValue = 0;
   if([result caseInsensitiveCompare:GrowlGNTPCallbackClicked] == NSOrderedSame || 
      [result caseInsensitiveCompare:GrowlGNTPCallbackClick] == NSOrderedSame)
      resultValue = 1;
   else if([result caseInsensitiveCompare:GrowlGNTPCallbackClosed] == NSOrderedSame || 
           [result caseInsensitiveCompare:GrowlGNTPCallbackClose] == NSOrderedSame)
      resultValue = 2;
   
   id clickContext = nil;
   
   if([contextType caseInsensitiveCompare:@"PList"] == NSOrderedSame)
      clickContext = [NSPropertyListSerialization propertyListWithData:[context dataUsingEncoding:NSUTF8StringEncoding] 
                                                               options:0
                                                                format:NULL
                                                                 error:NULL];
   else
      clickContext = context;
	
   switch (resultValue) {
      case 1:
         //it was clicked
         if ([delegate respondsToSelector:@selector(notificationClicked:context:)])
            [delegate notificationClicked:self context:clickContext];
         break;
      case 2:
         //it closed, same as timed out
      default:
         if ([delegate respondsToSelector:@selector(notificationTimedOut:context:)])
            [delegate notificationTimedOut:self context:clickContext];
         //it timed out
         break;
   }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)socketError {
	//if(socketError && [socketError code] != 7)
	//    NSLog(@"Got disconnected: %@", socketError);
	
	if (!attemptSucceeded) {
		if (!socketError) {
			NSString *reason = self.responseParseErrorString ? self.responseParseErrorString : @"Unknown error, possibly unable to connect";
			NSDictionary *dict = [NSDictionary dictionaryWithObject:reason  forKey:NSLocalizedDescriptionKey];
			socketError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:dict];
		}
		
		self.error = socketError;
		if (socketError)
			[self failed];
		[self finished];
		
		return;
	}
	
	[self finished];
}

@end
