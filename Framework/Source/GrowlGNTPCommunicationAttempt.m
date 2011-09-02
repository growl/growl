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
#define CRLF "\x0D\0x0A"
	[sock readDataToData:[GCDAsyncSocket CRLFData] withTimeout:10.0 tag:GrowlGNTPCommAttemptReadPhaseFirstResponseLine];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	[[self packet] writeToSocket:sock];
	//After we send in our request, the notifications system will send back a response consisting of at least one line.
	[self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseFirstResponseLine];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	NSString *readString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"Response: %@", readString);

	NSScanner *scanner = readString ? [[[NSScanner alloc] initWithString:readString] autorelease] : nil;

	if (![scanner scanString:@"GNTP/1.0 " intoString:NULL]){
		[self couldNotParseResponseWithReason:@"Response from Growl or other notification system was patent nonsense" responseString:readString];
      [socket disconnect];
      return;
   }

	if (tag == GrowlGNTPCommAttemptReadPhaseFirstResponseLine) {
		NSMutableCharacterSet *responseTypeCharacters = [NSMutableCharacterSet uppercaseLetterCharacterSet];
		[responseTypeCharacters addCharactersInString:@"-"];

		NSString *responseType = nil;

		BOOL scannedResponseType = [scanner scanCharactersFromSet:responseTypeCharacters intoString:&responseType];
		if (!scannedResponseType)
			[self couldNotParseResponseWithReason:@"Garbage in place of response type" responseString:readString];

		else {
			BOOL closeConnection = NO;

			if ([responseType isEqualToString:GrowlGNTPOKResponseType]) {
				attemptSucceeded = YES;

				closeConnection = [self expectsCallback];
            [self succeeded];
			} else if ([responseType isEqualToString:GrowlGNTPErrorResponseType]) {
				NSString *errorString = nil;
				[scanner scanUpToString:@CRLF intoString:&errorString];

				[self couldNotParseResponseWithReason:[NSString stringWithFormat:@"Growl or other notification system returned error: %@", errorString] responseString:readString];

				closeConnection = YES;

			} else if ([responseType isEqualToString:GrowlGNTPCallbackTypeHeader]) {
				callbackHeaderItems = [[NSMutableArray alloc] init];
				[self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];

			} else {
				[self couldNotParseResponseWithReason:[NSString stringWithFormat:@"Unrecognized response type: %@", responseType] responseString:readString];
			}

			if (closeConnection)
				[socket disconnect];
		}

	} else if (tag == GrowlGNTPCommAttemptReadPhaseResponseHeaderLine) {
		if ([readString isEqualToString:@CRLF]) {
			//Empty line: End of headers.
			[sock disconnect];
		} else {
			NSError *headerItemError = nil;
			GrowlGNTPHeaderItem *headerItem = [GrowlGNTPHeaderItem headerItemFromData:data error:&headerItemError];

			if (headerItem)
				[callbackHeaderItems addObject:headerItem];
			else {
				self.error = headerItemError;
				attemptSucceeded = NO;
			}
			
			[self readOneLineFromSocket:sock tag:GrowlGNTPCommAttemptReadPhaseResponseHeaderLine];
		}
	}
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
