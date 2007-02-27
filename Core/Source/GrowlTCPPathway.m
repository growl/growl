//
//  GrowlTCPPathway.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlTCPPathway.h"

#include <SystemConfiguration/SystemConfiguration.h>

#import "MD5Authenticator.h"

@implementation GrowlTCPPathway

- (BOOL) setEnabled:(BOOL)flag {
	if (enabled != flag) {
		if (flag) {
			authenticator = [[MD5Authenticator alloc] init];

			socketPort = [[NSSocketPort alloc] initWithTCPPort:GROWL_TCP_PORT];
			serverConnection = [[NSConnection alloc] initWithReceivePort:socketPort sendPort:nil];
			[serverConnection setRootObject:self];
			[serverConnection setDelegate:self];

			// register with the default NSPortNameServer on the local host
			if (![serverConnection registerName:@"GrowlServer"])
				NSLog(@"WARNING: could not register Growl server.");

			// configure and publish the Bonjour service
			CFStringRef serviceName = SCDynamicStoreCopyComputerName(/*store*/ NULL,
																	 /*nameEncoding*/ NULL);
			service = [[NSNetService alloc] initWithDomain:@""	// use local registration domain
													  type:@"_growl._tcp."
													  name:(NSString *)serviceName
													  port:GROWL_TCP_PORT];
			if (serviceName)
				CFRelease(serviceName);
			[service setDelegate:self];
			[service publish];
		} else {
			[serverConnection registerName:nil];	// unregister
			[serverConnection invalidate];
			[serverConnection release];
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

@end
