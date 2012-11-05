//
//  GrowlWebSocketProxy.m
//  Growl
//
//  Created by Daniel Siemer on 11/4/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlWebSocketProxy.h"
#import "GCDAsyncSocket.h"
#import "GNTPUtilities.h"
#import "GNTPPacket.h"

@implementation GrowlWebSocketProxy

- (id)initWithSocket:(GCDAsyncSocket*)socket {
	if((self = [super init])){
		self.socket = socket;
		self.delegate = [socket delegate];
		[self.socket synchronouslySetDelegate:self];
		
		//Go ahead and set up our next read now directly
		[self.socket readDataToData:[GNTPUtilities doubleCRLF]
							 withTimeout:5.0
										tag:100];
	}
	return self;
}

- (void)dealloc {
	[_socket release];
	_socket = nil;
	_delegate = nil;
	[super dealloc];
}

#pragma mark GCDAsyncSocket proxying methods

- (NSString *)connectedHost {
	return [_socket connectedHost];
}
- (NSData *)connectedAddress {
	return [_socket connectedAddress];
}

- (id)userData {
	return [_socket userData];
}
- (void)setUserData:(id)userData {
	[_socket setUserData:userData];
}

- (void)readDataToData:(NSData *)data
				withLength:(NSUInteger)length
			  withTimeout:(NSTimeInterval)timeout
						 tag:(long)tag
{
	//Check if we have the data already, if so, go ahead and pull it out and talk back to our delegate
	//Otherwise, schedule a read
}

- (void)readDataToLength:(NSUInteger)length withTimeout:(NSTimeInterval)timeout tag:(long)tag {
	[self readDataToData:nil withLength:length withTimeout:timeout tag:tag];
}
- (void)readDataToData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag {
	[self readDataToData:data withLength:0 withTimeout:timeout tag:tag];
}

- (void)writeData:(NSData *)data withTimeout:(NSTimeInterval)timeout tag:(long)tag {
	//Render the string back as UTF8, frame it up, send it out
}

#pragma mark GCDAsyncSocket Delegate Methods

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if(tag == 100){
		//Parse the HTTP headers, build our response, and send it, or disconnect the socket if we dont conform to what it sends
	}else{
		//Parse, demix, and buffer the frame's data if we are in frame reading mode
	}
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	[_delegate socket:sock didWriteDataWithTag:tag];
}
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock
shouldTimeoutReadWithTag:(long)tag
					  elapsed:(NSTimeInterval)elapsed
					bytesDone:(NSUInteger)length
{
	return [_delegate socket:sock shouldTimeoutReadWithTag:tag elapsed:elapsed bytesDone:length];
}
- (NSTimeInterval)socket:(GCDAsyncSocket *)sock
shouldTimeoutWriteWithTag:(long)tag
					  elapsed:(NSTimeInterval)elapsed
					bytesDone:(NSUInteger)length
{
	return [_delegate socket:sock shouldTimeoutWriteWithTag:tag elapsed:elapsed bytesDone:length];
}
- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
	//We might want to know about this
	//Check if the packet we have is finishable at its present point (ie, did we simply miss a binary block?)
}
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock
						withError:(NSError *)err
{
	[_delegate socketDidDisconnect:sock withError:err];
}

@end
