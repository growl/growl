//
//  GrowlTCPPathway.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlTCPPathway.h"
#import "GrowlTCPServer.h"

#include <SystemConfiguration/SystemConfiguration.h>

#import "MD5Authenticator.h"

@implementation GrowlTCPPathway

- (BOOL) setEnabled:(BOOL)flag {
	if (enabled != flag) {
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
            if ([thisHostName hasSuffix:@".local"]) {
                thisHostName = [thisHostName substringToIndex:([thisHostName length] - 6)];
            }

			service = [[NSNetService alloc] initWithDomain:@"" type:@"_growl._tcp." name:thisHostName port:GROWL_TCP_DO_PORT];
			[service publish];

			tcpServer = [[GrowlTCPServer alloc] init];
			/* GrowlTCPServer will use our host name by default for publishing, which
			 * is what we want */
			[tcpServer setType:@"_growl_protocol._tcp."];
			[tcpServer setPort:GROWL_TCP_PORT];
			[tcpServer setName:thisHostName];
			[tcpServer setDelegate:self];
			
			NSError *error = nil;
			if (![tcpServer start:&error])
				NSLog(@"Error starting Growl TCP server: %@", error);
			[[tcpServer netService] setDelegate:self];

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

		return [super setEnabled:flag];
	}
	return YES;
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
/**
 * Called when a socket connects and is ready for reading and writing.
 * The host parameter will be an IP address, not a DNS name.
 **/
- (void)didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"We've connected to %@ on %i", host, port);
}

/**
 * Called when a socket has completed reading the requested data into memory.
 * Not called if there is an error.
 **/
- (void)didReadData:(NSData *)data withTag:(long)tag
{
#pragma unused(data, tag)
}

@end
