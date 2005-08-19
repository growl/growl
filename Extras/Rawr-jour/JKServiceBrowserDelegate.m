//
//  JKServiceBrowserDelegate.m
//  Rawr-endezvous
//
//  Created by Jeremy Knope on 9/25/04.
//  Copyright 2004 Jeremy Knope. All rights reserved.
//

#import "JKServiceBrowserDelegate.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

@interface NSNetService(PantherCompatibility)
+ (NSDictionary *)dictionaryFromTXTRecordData:(NSData *)txtData;
- (NSData *)TXTRecordData;
- (void) resolveWithTimeout:(NSTimeInterval)timeout;
@end

@implementation JKServiceBrowserDelegate
- (void) awakeFromNib {
	services = [[NSMutableArray alloc] initWithCapacity:1U];
	serviceTypes = [[NSMutableDictionary alloc] initWithCapacity:1U];
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(addService:) name:@"RawrEndezvousNewService" object:nil];
	[nc addObserver:self selector:@selector(removeService:) name:@"RawrEndezvousRemoveService" object:nil];
}

- (void) dealloc {
	[serviceTypes release];
	[services     release];
	[super dealloc];
}

- (void) addService:(NSNotification *)note {
	//NSLog(@"Adding service to browser...");
	NSNetService *service = [note object];
	NSString *type = [service type];
	NSDictionary *entry = [serviceTypes objectForKey:type];

	if (entry) {
		// Add actual service to service type entry
		//NSLog(@"Adding service to type's array");
		[[entry objectForKey:@"contents"] addObject:service];
	} else {
		//NSLog(@"Creating entry");
		NSMutableArray *contents = [[NSMutableArray alloc] initWithObjects:service, nil];
		entry = [[NSDictionary alloc] initWithObjectsAndKeys:
			type,     @"name",
			contents, @"contents",
			nil];
		[contents release];
		[services addObject:entry];
		[serviceTypes setObject:entry forKey:type];
		[serviceBrowser reloadColumn:0];
		[entry release];
	}

}

- (void) removeService:(NSNotification *)note {
	NSNetService *service = [note object];
	NSMutableArray *contents = [[serviceTypes objectForKey:[service type]] objectForKey:@"contents"];
	[contents removeObject:service];
	if (![contents count]) {
		//NSLog(@"No more services of this type: %@",[service type]);
		[services removeObject:[serviceTypes objectForKey:[service type]]];
		[serviceTypes removeObjectForKey:[service type]];
		[serviceBrowser reloadColumn:0];
	}
}

- (int) browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
	//NSLog(@"Counting for browser");
	switch (column) {
		case 0:
			return [services count];
		case 1:
			return [[[services objectAtIndex:[sender selectedRowInColumn:0]] objectForKey:@"contents"] count];
		case 2:
			return [sender selectedRowInColumn:1] >= 0 ? 3 : 0;
		default:
			return 0;
	}
}

- (void) browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
	//NSLog(@"Display for browser");
	NSNetService *serv;
	NSString *name = nil;
	switch (column) {
		case 0:
			name = [[services objectAtIndex:row] objectForKey:@"name"];
			break;
		case 1:
			if (row >= 0) {
				serv = [[[services objectAtIndex:[sender selectedRowInColumn:0]] objectForKey:@"contents"] objectAtIndex:row];
				name = [serv name];
			} else
				name = @"Error";
			//[cell setLeaf:YES];
			break;
		case 2:
			serv = [[[services objectAtIndex:[sender selectedRowInColumn:0]] objectForKey:@"contents"] objectAtIndex:[sender selectedRowInColumn:1]];
			[serv setDelegate:self];
			if ([serv respondsToSelector:@selector(resolveWithTimeout:)])
				[serv resolveWithTimeout:5.0];
			else
				[serv resolve];
			switch (row) {
				case 0:
					//name = @"Name here";
					name = [serv name];
					break;
				case 1:
					if (resAddress && resPort)
						name = @"Unimplemented"; //name = [NSString stringWithFormat:@"%@:%@",resAddress,resPort];
					else
						name = @"No addresses yet";
					break;
				case 2:
					if ([serv respondsToSelector:@selector(TXTRecordData)]) {
						NSData *txtData = [serv TXTRecordData];
						if (txtData)
							name = [[NSNetService dictionaryFromTXTRecordData:txtData] description];
						else
							name = @"";
					} else
						name = [serv protocolSpecificInformation];
					if (!name)
						name = @"";
						break;
				default:
					name = @"Invalid row";
			}
			[cell setLeaf:YES];
			break;
	}

	[cell setStringValue:name];
}

- (void) netServiceDidResolveAddress:(NSNetService *)sender {
	//NSLog(@"Did resolve!");
	if ([[sender addresses] count]) {
		NSData * address;
		struct sockaddr * socketAddress = NULL;
		NSString * ipAddressString = nil;
		NSString * portString = nil;
		//int socketToRemoteServer;
		char buffer[256];

		// Iterate through addresses until we find an IPv4 address
		NSEnumerator *addrEnum = [[sender addresses] objectEnumerator];
		while ((address = [addrEnum nextObject])) {
			socketAddress = (struct sockaddr *)[address bytes];

			if (socketAddress->sa_len == sizeof(struct sockaddr_in))
				break;
		}

		if (socketAddress) {
			switch (socketAddress->sa_len) {
				case sizeof(struct sockaddr_in):
					if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer)))
						ipAddressString = [[NSString alloc] initWithCString:buffer];
					portString = [[NSString alloc] initWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];

					// Cancel the resolve now that we have an IPv4 address.
					[sender stop];
					[sender release];
					serviceBeingResolved = nil;

					break;
				case sizeof(struct sockaddr_in6):
					// PictureSharing server doesn't support IPv6
					return;
			}
		}

		if (ipAddressString && portString) {
			//NSString *urlString;
			//urlString = [NSString stringWithFormat:@"%@://%@:%@",[[[serviceManager getProtocolNames] objectForKey:[sender type]] objectForKey:@"protocol"],ipAddressString,portString];
			//NSLog(@"Opening: %@",urlString);
			//NSURL *myURL = [NSURL URLWithString:urlString];
			//[[NSWorkspace sharedWorkspace] openURL:myURL];
			[resAddress release];
			[resPort    release];
			resAddress = ipAddressString;
			resPort = portString;
		} else {
			[ipAddressString release];
			[portString      release];
		}
	}
}
@end
