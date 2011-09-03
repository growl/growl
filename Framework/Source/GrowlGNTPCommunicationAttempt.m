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

#import "GCDAsyncSocket.h"

@interface GrowlGNTPCommunicationAttempt ()

@property(nonatomic, retain) NSString *responseParseErrorString, *bogusResponse;

@end

enum {
	GrowlGNTPCommAttemptReadPhaseFirstResponseLine,
	GrowlGNTPCommAttemptReadPhaseResponseHeaderLine,
};

enum {
   GrowlGNTPCommAttemptReadFeedback = 1,
   GrowlGNTPCommAttemptReadError,
};

@implementation GrowlGNTPCommunicationAttempt

@synthesize responseParseErrorString, bogusResponse;

- (void) dealloc {
	[callbackHeaderItems release];

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
   
	NSError *errorReturned = nil;
	if (![socket connectToHost:@"localhost"
				   onPort:GROWL_TCP_PORT
			  withTimeout:15.0
					error:&errorReturned])
	{
		NSLog(@"Failed to connect: %@", errorReturned);
		self.error = errorReturned;
		[self failed];
	}
}

- (void) readOneLineFromSocket:(GCDAsyncSocket *)sock tag:(long)tag {
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:10.0 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	[[self packet] writeToSocket:sock];
	//After we send in our request, the notifications system will send back a response consisting of at least one line.
	[self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseFirstResponseLine];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSString *readString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
   
	if (tag == GrowlGNTPCommAttemptReadPhaseFirstResponseLine) {
      NSArray *components = [readString componentsSeparatedByString:@" "];
      if([components count] != 3){
         [self couldNotParseResponseWithReason:@"Not enough, or too many components in initial header" responseString:readString];
         [socket disconnect];
         return;
      }
      if (![[components objectAtIndex:0] isEqualToString:@"GNTP/1.0"]){
         [self couldNotParseResponseWithReason:@"Response from Growl or other notification system was patent nonsense" responseString:readString];
         [socket disconnect];
         return;
      }
      if(![[[components objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:GrowlGNTPNone]){
         [self couldNotParseResponseWithReason:@"We shouldn't have encryption on a response to localhost" responseString:readString];
         [socket disconnect];
         return;
      }
      
      NSString *responseType = [components objectAtIndex:1];
      
      BOOL closeConnection = NO;
      
      if ([responseType isEqualToString:GrowlGNTPOKResponseType]) {
         attemptSucceeded = YES;
         
         closeConnection = [self expectsCallback];
         [self succeeded];
      } else if ([responseType isEqualToString:GrowlGNTPErrorResponseType]) {            
         /* We need to know what we are getting for an error, which is in a seperate header */
         [self readOneLineFromSocket:socket tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
         responseReadType = GrowlGNTPCommAttemptReadError;
         
      } else if ([responseType isEqualToString:GrowlGNTPCallbackTypeHeader]) {
         callbackHeaderItems = [[NSMutableArray alloc] init];
         
         [self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
         
         responseReadType = GrowlGNTPCommAttemptReadFeedback;
      } else {
         [self couldNotParseResponseWithReason:[NSString stringWithFormat:@"Unrecognized response type: %@", responseType] responseString:readString];
      }
      
      if (closeConnection)
         [socket disconnect];
      
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
   
   if(code)
      NSLog(@"%@", [code GNTPRepresentationAsString]);
   if(description)
      NSLog(@"%@",[description GNTPRepresentationAsString]);
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
   
   if(result)
      NSLog(@"%@", [result GNTPRepresentationAsString]);
   if(context)
      NSLog(@"%@", [context GNTPRepresentationAsString]);
   if(contextType)
      NSLog(@"%@", [contextType GNTPRepresentationAsString]);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)socketError {
	NSLog(@"Got disconnected: %@", socketError);
	if (!attemptSucceeded) {
		if (!socketError) {
			NSDictionary *dict = [NSDictionary dictionaryWithObject:self.responseParseErrorString forKey:NSLocalizedDescriptionKey];
			socketError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:dict];
		}

		self.error = socketError;
		if (socketError)
			[self failed];

		return;
	}

	[self succeeded];
}

@end
