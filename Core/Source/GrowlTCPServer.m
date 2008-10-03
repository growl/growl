#import "GrowlTCPServer.h"
#import "AsyncSocket.h"

@implementation GrowlTCPServer

- (id)init {
    return self;
}

- (void)dealloc {
    [self stop];
    [domain release];
    [name release];
    [type release];
    [super dealloc];
}

- (id)delegate {
    return delegate;
}

- (void)setDelegate:(id)value {
    delegate = value;
}

- (NSString *)domain {
    return domain;
}

- (void)setDomain:(NSString *)value {
    if (domain != value) {
        [domain release];
        domain = [value copy];
    }
}

- (NSString *)name {
    return name;
}

- (void)setName:(NSString *)value {
    if (name != value) {
        [name release];
        name = [value copy];
    }
}

- (NSString *)type {
    return type;
}

- (void)setType:(NSString *)value {
    if (type != value) {
        [type release];
        type = [value copy];
    }
}

- (uint16_t)port {
    return port;
}

- (void)setPort:(uint16_t)value {
    port = value;
}

- (NSNetService *)netService {
	return netService;
}

- (BOOL)start:(NSError **)error {
	BOOL success;

	asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
	success = [asyncSocket acceptOnPort:port error:(error ? error : NULL)];
	NSLog(@"%@ now accepting (%@)", asyncSocket, *error);
    if (port == 0) {
        /* Now that the binding was successful, we get the port number if we let
		 * the kernel determine it.
		 */
		port = [asyncSocket localPort];
	}

    // we can only publish the service if we have a type to publish with
    if (type) {
        NSString *publishingDomain = domain ? domain : @"";
        NSString *publishingName = nil;
        if (name) {
            publishingName = name;
        } else {
            NSString * thisHostName = [[NSProcessInfo processInfo] hostName];
            if ([thisHostName hasSuffix:@".local"]) {
                publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
            }
        }

        netService = [[NSNetService alloc] initWithDomain:publishingDomain type:type name:publishingName port:port];
        [netService publish];
    }

	/*
	[NSThread detachNewThreadSelector:@selector(tcpServerLoop)
							 toTarget:self withObject:nil];
	*/
    return success;
}

static NSRunLoop *serverLoop = nil;
- (void)tcpServerLoop
{
	serverLoop = [NSRunLoop currentRunLoop];
	NSLog(@"Run loop is %@", serverLoop);
	BOOL shouldKeepRunning = YES;        // global
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];
	while (shouldKeepRunning)
		[theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
	NSLog(@"Done running");
}

- (BOOL)stop {
    [netService stop];
    [netService release];
    netService = nil;
	NSLog(@"Stop %@", self);
	
	[asyncSocket disconnectAfterWriting];
	[asyncSocket release]; asyncSocket = nil;
    
	return YES;
}

#pragma mark -

- (void)readFromSocket:(AsyncSocket *)socket
{
	/*
	[socket readDataToData:[@"</plist>" dataUsingEncoding:NSUTF8StringEncoding]
			   withTimeout:-1
					   tag:0];
	 */
	[socket readDataWithTimeout:100 tag:0];
}

/*
- (NSRunLoop *)onSocket:(AsyncSocket *)sock wantsRunLoopForNewSocket:(AsyncSocket *)newSocket
{
	NSLog(@"Giving %@", serverLoop);
	return serverLoop;
}
 */
 - (void) onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	NSLog (@"Socket %@ accepting connection %@.", sock, newSocket);
	[[self delegate] didAcceptNewSocket:newSocket];
}

/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)inHost port:(UInt16)inPort
{
	NSLog(@"%@ connected to %@", sock, inHost);
	[[self delegate] didConnectToHost:inHost port:inPort];
	
	[self readFromSocket:sock];
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"%@ read %@", sock, string);
	[[self delegate] didReadData:data withTag:tag];
	[string release];
	
	[self readFromSocket:sock];
}

- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(CFIndex)partialLength tag:(long)tag
{
	NSLog(@"didReadPartialDataOfLength: %@ Read %i: tag %i", sock, partialLength, tag);
}

/*
 This will be called whenever AsyncSocket is about to disconnect. In Echo Server,
 it does not do anything other than report what went wrong (this delegate method
 is the only place to get that information), but in a more serious app, this is
 a good place to do disaster-recovery by getting partially-read data. This is
 not, however, a good place to do cleanup. The socket must still exist when this
 method returns.
 */
-(void) onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	if (err != nil)
		NSLog (@"Socket %@ will disconnect. Error domain %@, code %d (%@).",
			   sock,
			   [err domain], [err code], [err localizedDescription]);
	else
		NSLog (@"Socket will disconnect. No error. unread: %@", [sock unreadData]);
}

@end

