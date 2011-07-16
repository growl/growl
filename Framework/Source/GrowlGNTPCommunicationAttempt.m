//
//  GrowlGNTPCommunicationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPCommunicationAttempt.h"

#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlDefinesInternal.h"

#import "GCDAsyncSocket.h"

@implementation GrowlGNTPCommunicationAttempt

- (GrowlGNTPOutgoingPacket *) packet {
	NSAssert1(NO, @"Subclass dropped the ball: Communication attempt %@  does not know how to create a GNTP packet", self);
	return nil;
}

- (void) failed {
	[super failed];
	[socket release];
	socket = nil;
}

- (void) begin {
	NSAssert1(socket == nil, @"%@ appears to already be sending!", self);
	//GrowlGNTPOutgoingPacket *packet = [self packet];
	socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	NSError *error = nil;
	if (![socket connectToHost:@"localhost"
				   onPort:GROWL_TCP_PORT
			  withTimeout:15.0
					error:&error])
	{
		[self failed];
	}
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	[[self packet] writeToSocket:sock];
	[socket disconnectAfterWriting];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)error {
	[self failed];
}

@end
