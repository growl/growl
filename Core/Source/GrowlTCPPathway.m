//
//  GrowlTCPPathway.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlTCPPathway.h"
#import "GrowlTCPServer.h"
#import "GrowlGNTPPacketParser.h"

#include <SystemConfiguration/SystemConfiguration.h>

#import "MD5Authenticator.h"

@implementation GrowlTCPPathway

- (id)init
{
	if ((self = [super init])) {
		networkPacketParser = [[GrowlGNTPPacketParser alloc] init];
		
		/* We always want the TCP server to be running to allow localhost connections.
		 * We'll ultimately ignore connections from outside localhost if networking is not enabled.
		 */
		tcpServer = [[GrowlTCPServer alloc] init];

		/* GrowlTCPServer will use our host name by default for publishing, which is what we want. */
		[tcpServer setType:@"_gntp._tcp."];
		[tcpServer setPort:/*9999*/GROWL_TCP_PORT];
		[tcpServer setDelegate:self];
		
		NSError *error = nil;
		if (![tcpServer start:&error])
			NSLog(@"Error starting Growl TCP server: %@", error);
		[[tcpServer netService] setDelegate:self];
	}
		
	return self;
}


- (BOOL) setEnabled:(BOOL)flag {
	if ([self isEnabled] != flag) {
		if (flag) {
			authenticator = [[MD5Authenticator alloc] init];

			/* Create an NSSocketPort on GROWL_TCP_DO_PORT and attach an NSConnection to it.
			 * This allows remote clients to connect to our IP on GROWL_TCP_DO_PORT and use NSConnection
			 * to message us.
			 */
			socketPort = [[NSSocketPort alloc] initWithTCPPort:GROWL_TCP_DO_PORT];
			remoteDistributedObjectConnection = [[NSConnection alloc] initWithReceivePort:socketPort sendPort:nil];
			[remoteDistributedObjectConnection setRootObject:self];
			[remoteDistributedObjectConnection setDelegate:self];

			/* Register with the default NSPortNameServer on the local host. This allows acccess by
			 * other processes via +[NSConnection connectionWithRegisteredName:host:] with a name of 
			 * @"GrowlServer"
			 */
			localDistributedObjectConnection = [[NSConnection alloc] initWithReceivePort:[NSPort port] sendPort:nil];
			[localDistributedObjectConnection setRootObject:self];
			[localDistributedObjectConnection setDelegate:self];
			if (![localDistributedObjectConnection registerName:@"GrowlServer"]) {
				NSLog(@"WARNING: could not register Growl server. Occupied by %@", 
					  [NSConnection connectionWithRegisteredName:@"GrowlServer" host:nil]);
			}

			NSString *thisHostName = [[NSProcessInfo processInfo] hostName];
            if ([thisHostName hasSuffix:@".local"])
                thisHostName = [thisHostName substringToIndex:([thisHostName length] - [@".local" length])];

			service = [[NSNetService alloc] initWithDomain:@"" type:@"_growl._tcp." name:thisHostName port:GROWL_TCP_DO_PORT];
			[service publish];

		} else {
			[remoteDistributedObjectConnection registerName:nil];	// unregister
			[remoteDistributedObjectConnection invalidate];
			[remoteDistributedObjectConnection release];

			[localDistributedObjectConnection registerName:nil];	// unregister
			[localDistributedObjectConnection invalidate];
			[localDistributedObjectConnection release];

			[socketPort       invalidate];
			[socketPort       release];

			[service          stop];
			[service          release];
			
			[authenticator release];
		}
	}

	return [super setEnabled:flag];
}

- (void)dealloc
{
	[remoteDistributedObjectConnection registerName:nil];	// unregister
	[remoteDistributedObjectConnection invalidate];
	[remoteDistributedObjectConnection release];
	
	[localDistributedObjectConnection registerName:nil];	// unregister
	[localDistributedObjectConnection invalidate];
	[localDistributedObjectConnection release];
	
	[socketPort invalidate];
	[socketPort release];
	
	[service stop];
	[service release];
	
	[authenticator release];
	
	[tcpServer stop];
	[tcpServer release];
	
	[networkPacketParser release];
	
	[super dealloc];
}

#pragma mark -

- (void) netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
#pragma unused(sender)
	NSLog(@"WARNING: could not publish Growl service. Error: %@", errorDict);
}

#pragma mark -

- (BOOL) connection:(NSConnection *)ancestor shouldMakeNewConnection:(NSConnection *)conn {
	[conn setDelegate:[ancestor delegate]];
	return YES;
}

- (NSData *) authenticationDataForComponents:(NSArray *)components {
	return [authenticator authenticationDataForComponents:components];
}

- (BOOL) authenticateComponents:(NSArray *)components withData:(NSData *)signature {
	return [authenticator authenticateComponents:components withData:signature];
}
 
#pragma mark -

/*!
 * @brief The TCP server accepted a new socket. Pass it to the network packet parser.
 */
- (void)didAcceptNewSocket:(AsyncSocket *)sock
{
	NSLog(@"%@: Telling %@ we accepted", self, networkPacketParser);
	[networkPacketParser didAcceptNewSocket:sock];
}

@end
