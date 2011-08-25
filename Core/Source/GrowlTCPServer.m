#import "GrowlTCPServer.h"
#import "GCDAsyncSocket.h"
#import "NSStringAdditions.h"
#import <SystemConfiguration/SCDynamicStoreCopySpecific.h>

/*!
 * @class GrowlTCPServer
 * @brief Class to manage establishing a listening socket and advertising it
 */
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

- (id <GrowlTCPServerDelegate>)delegate {
    return delegate;
}

- (void)setDelegate:(id <GrowlTCPServerDelegate>)value {
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

	asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	success = [asyncSocket acceptOnPort:port error:(error ? error : NULL)];
	NSLog(@"%@ now accepting (%@)", asyncSocket, (error ? *error : NULL));
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
            NSString * thisHostName = [(NSString*)SCDynamicStoreCopyLocalHostName(NULL) autorelease];
            if ([thisHostName hasSuffix:@".local"]) {
                publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
            }else
                publishingName = thisHostName;
        }

        netService = [[NSNetService alloc] initWithDomain:publishingDomain type:type name:publishingName port:port];
        [netService publish];
    }

    return success;
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

/*!
 * @brief Our listening socket accepted a new socket. Pass it to our delegate (GrowlTCPPathway) for handling
 *
 * This is the only place GrowlTCPServer interacts with the incoming socket; GrowlTCPPathway will take it from here.
 */
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
	NSLog (@"Socket %@ accepting connection %@.", sock, newSocket);
    if ([[newSocket connectedHost] isLocalHost] ||
        [[GrowlPreferencesController sharedController] isGrowlServerEnabled]) {
        [[self delegate] didAcceptNewSocket:newSocket];
	} else {
		[newSocket disconnect];
	}

}

@end

