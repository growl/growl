//
//  GNTPServer.m
//  GNTPTestServer
//
//  Created by Daniel Siemer on 6/20/12.
//  Copyright (c) 2012 The Growl Project, LLC. All rights reserved.
//

#import "GNTPServer.h"

@interface GNTPServer ()

@property (nonatomic, retain) GCDAsyncSocket *localSocket;
@property (nonatomic, retain) NSMutableDictionary *socketsByGUID;
@property (nonatomic, retain) NSMutableDictionary *packetsByGUID;

@end

@implementation GNTPServer

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
	NSUInteger readToLength = 0;
	long readToTag = -1;
	if(tag == 0){
		//Parse our first 4 bytes
		NSString *initialString = [NSString stringWithUTF8String:[data bytes]];
		if([initialString caseInsensitiveCompare:@"GNTP"] == NSOrderedSame){
			//Read the security header for testing it
			readToData = [GCDAsyncSocket CRLFData];
			readToTag = 1;
		}
		//Other first 4 bytes might be Flash policy, '<Pol' or WebSocket's 'webs'
	}else if(tag == 1){
		//Use the security parser to test the header and see if this is allowed
	}else if(tag == 2){
		//Pass the data to the packet and get our next read data/tag/length
	}else{
		
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
	}
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
	//Not sure if we need this
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
}

@end
