//
//  GrowlGNTPCommunicationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPCommunicationAttempt.h"

#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlGNTPHeaderItem.h"
#import "GrowlDefinesInternal.h"
#import "GrowlGNTPNotificationAttempt.h"
#import "GrowlApplicationBridge.h"
#import "NSStringAdditions.h"

#import "GCDAsyncSocket.h"
#import "GNTPKey.h"

@interface GrowlGNTPCommunicationAttempt ()

@property(nonatomic, retain) NSString *responseParseErrorString, *bogusResponse;

@end

enum {
	GrowlGNTPCommAttemptReadPhaseFirstResponseLine,
	GrowlGNTPCommAttemptReadPhaseResponseHeaderLine,
   GrowlGNTPCommAttemptReadExtraPacketData,
};

enum {
   GrowlGNTPCommAttemptReadFeedback = 1,
   GrowlGNTPCommAttemptReadError,
};

@implementation GrowlGNTPCommunicationAttempt

@synthesize responseParseErrorString, bogusResponse;
@synthesize host;
@synthesize password;
@synthesize callbackHeaderItems;

@synthesize connection;

- (void) dealloc {
	[callbackHeaderItems release];
   
   [socket synchronouslySetDelegate:nil];
   [socket release];
   socket = nil;

	[super dealloc];
}

- (GrowlGNTPOutgoingPacket *) packet {
	NSAssert1(NO, @"Subclass dropped the ball: Communication attempt %@  does not know how to create a GNTP packet", self);
	return nil;
}

- (BOOL) expectsCallback {
	return NO;
}

- (void) failed {
	NSLog(@"%@ failed because %@", self, self.error);
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
   
   NSString *hostToUse = nil;
   if(!self.host || [host isLocalHost])
      hostToUse = @"localhost";
   else
      hostToUse = host;
   
	NSError *errorReturned = nil;
	if (![socket connectToHost:hostToUse
				   onPort:GROWL_TCP_PORT
			  withTimeout:15.0
					error:&errorReturned])
	{
		NSLog(@"Failed to connect: %@", errorReturned);
		self.error = errorReturned;
		[self failed];
	}
}

/* We read to a triple CRLF, one for the last line of the packet, 2 for finishing the packet */ 
- (void) readRestOfPacket:(GCDAsyncSocket*)sock
{
   static NSData *triple = nil;
   if(!triple){
      NSMutableData *data = [NSMutableData dataWithData:[GCDAsyncSocket CRLFData]];
      [data appendData:[GCDAsyncSocket CRLFData]];
      [data appendData:[GCDAsyncSocket CRLFData]];
      triple = [data copy];
   }
   [sock readDataToData:triple withTimeout:10.0 tag:GrowlGNTPCommAttemptReadExtraPacketData];
}

- (void) readOneLineFromSocket:(GCDAsyncSocket *)sock tag:(long)tag {
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:10.0 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
   GrowlGNTPOutgoingPacket *outPacket = [self packet];

   if(password){
      GNTPKey *key = [[GNTPKey alloc] initWithPassword:password
                                         hashAlgorithm:GNTPSHA512
                                   encryptionAlgorithm:GNTPNone];
      [outPacket setKey:key];
   }
   [outPacket writeToSocket:sock];
	//After we send in our request, the notifications system will send back a response consisting of at least one line.
	[self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseFirstResponseLine];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSString *readString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
   //NSLog(@"read: %@", readString);
   
   if(tag == GrowlGNTPCommAttemptReadExtraPacketData){
      //No op, we possibly told it to read more after this
      //NSLog(@"Exhausting packet");
   }else if (tag == GrowlGNTPCommAttemptReadPhaseFirstResponseLine) {      
      NSArray *components = [readString componentsSeparatedByString:@" "];
      if([components count] != 3){
         NSLog(@"Not enough, or too many components in initial header");
         [self couldNotParseResponseWithReason:@"Not enough, or too many components in initial header" responseString:readString];
         [socket disconnect];
         return;
      }
      if (![[components objectAtIndex:0] isEqualToString:@"GNTP/1.0"]){
         NSLog(@"Response from Growl or other notification system was patent nonsense");
         [self couldNotParseResponseWithReason:@"Response from Growl or other notification system was patent nonsense" responseString:readString];
         [socket disconnect];
         return;
      }
      if(![[[components objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:GrowlGNTPNone]){
         NSLog(@"We shouldn't have encryption on a response from localhost");
         [self couldNotParseResponseWithReason:@"We shouldn't have encryption on a response from localhost" responseString:readString];
         [socket disconnect];
         return;
      }
      
      NSString *responseType = [components objectAtIndex:1];
      
      BOOL closeConnection = NO;
      
      if ([responseType isEqualToString:GrowlGNTPOKResponseType]) {
         attemptSucceeded = YES;
         [self succeeded];
         
         [self readRestOfPacket:socket];
         closeConnection = ![self expectsCallback];
         if(!closeConnection)
            [self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseFirstResponseLine];

      } else if ([responseType isEqualToString:GrowlGNTPErrorResponseType]) {            
         /* We need to know what we are getting for an error, which is in a seperate header */
         [self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
         responseReadType = GrowlGNTPCommAttemptReadError;
         
      } else if ([responseType isEqualToString:GrowlGNTPCallbackTypeHeader]) {         
         [self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
         
         responseReadType = GrowlGNTPCommAttemptReadFeedback;
      } else {
         [self couldNotParseResponseWithReason:[NSString stringWithFormat:@"Unrecognized response type: %@", responseType] responseString:readString];
         closeConnection = YES;
      }
      
      if (closeConnection){
         [socket disconnect];
         [self finished];
      }
      
	} else if (tag == GrowlGNTPCommAttemptReadPhaseResponseHeaderLine) {
      NSError *headerItemError = nil;
      GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:data error:&headerItemError];
      if (headerItem != [GrowlGNTPHeaderItem separatorHeaderItem]){
         if(!callbackHeaderItems)
            callbackHeaderItems = [[NSMutableArray alloc] init];
         [callbackHeaderItems addObject:headerItem];
         [self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
      }else{
         //Empty line: End of headers.
         switch (responseReadType) {
            case GrowlGNTPCommAttemptReadError:
               [self parseError];
               break;
            case GrowlGNTPCommAttemptReadFeedback:
               [self parseFeedback];
               break;
            default:
               //We shouldn't be here, only packets we should be reading responses for is feedback and error
               break;
         }
         [callbackHeaderItems release]; callbackHeaderItems = nil;
         [self finished];
		}
	}
}

- (void)parseError
{
   //We need error code, and error description
   __block GrowlGNTPHeaderItem *code = nil;
   __block GrowlGNTPHeaderItem *description = nil;
   [callbackHeaderItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj isKindOfClass:[GrowlGNTPHeaderItem class]])
      {
         if([[obj headerName] isEqualToString:@"Error-Code"])
            code = obj;
         if([[obj headerName] isEqualToString:@"Error-Description"])
            description = obj;
            
         if(code != nil && description != nil)
            *stop = YES;
      }
   }];

   if(code){
      GrowlGNTPErrorCode errCode = (GrowlGNTPErrorCode)[[code headerValue] integerValue];
      if(errCode == GrowlGNTPUserDisabledErrorCode)
         [self stopAttempts];
      if((errCode == GrowlGNTPUnknownApplicationErrorCode || 
          errCode == GrowlGNTPUnknownNotificationErrorCode) &&
         [self isKindOfClass:[GrowlGNTPNotificationAttempt class]]){
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
   __block GrowlGNTPHeaderItem *result = nil;
   __block GrowlGNTPHeaderItem *context = nil;
   __block GrowlGNTPHeaderItem *contextType = nil;
   [callbackHeaderItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if([obj isKindOfClass:[GrowlGNTPHeaderItem class]])
      {
         if([[obj headerName] isEqualToString:GrowlGNTPNotificationCallbackResult])
            result = obj;
         if([[obj headerName] isEqualToString:GrowlGNTPNotificationCallbackContext])
            context = obj;
         if([[obj headerName] isEqualToString:GrowlGNTPNotificationCallbackContextType])
            contextType = obj;

         if(result != nil && context != nil && contextType != nil)
            *stop = YES;
      }
   }];
   
   NSString *resultString = [result headerValue];
   int resultValue = 0;
   if([resultString isEqualToString:GrowlGNTPCallbackClicked] || [resultString isEqualToString:GrowlGNTPCallbackClick])
      resultValue = 1;
   else if([resultString isEqualToString:GrowlGNTPCallbackClosed] || [resultString isEqualToString:GrowlGNTPCallbackClose])
      resultValue = 2;
   
   id clickContext = nil;
   
   if([[contextType headerValue] caseInsensitiveCompare:@"PList"] == NSOrderedSame)
      clickContext = [NSPropertyListSerialization propertyListWithData:[[context headerValue] dataUsingEncoding:NSUTF8StringEncoding] 
                                                               options:0
                                                                format:NULL
                                                                 error:NULL];
   else
      clickContext = [context headerValue];
         
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
   if(socketError && [socketError code] != 7)
      NSLog(@"Got disconnected: %@", socketError);
   
	if (!attemptSucceeded) {
		if (!socketError) {
			NSDictionary *dict = [NSDictionary dictionaryWithObject:self.responseParseErrorString forKey:NSLocalizedDescriptionKey];
			socketError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:dict];
		}

		self.error = socketError;
		if (socketError)
			[self failed];
      [self finished];

		return;
	}

	[self succeeded];
   [self finished];
}

@end
