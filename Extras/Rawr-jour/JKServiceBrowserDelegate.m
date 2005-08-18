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

@implementation JKServiceBrowserDelegate
- (void)awakeFromNib {
	services = [NSMutableArray arrayWithCapacity:1];
	serviceTypes = [NSMutableDictionary dictionaryWithCapacity:1];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addService:) name:@"RawrEndezvousNewService" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeService:) name:@"RawrEndezvousRemoveService" object:nil];
	[serviceTypes retain];
	[services retain];
}

- (void)dealloc {
	[serviceTypes release];
	[services release];
	[super dealloc];
}

- (void)addService:(NSNotification *)note {
	//NSLog(@"Adding service to browser...");
	NSNetService *service = [note object];
	NSDictionary *entry;

	//if(![services containsObject:[service type]]) {
	if([serviceTypes objectForKey:[service type]] == nil) {
		//NSLog(@"Creating entry");
		entry = [NSDictionary dictionaryWithObjectsAndKeys:
			[service type],@"name",
			[NSMutableArray arrayWithCapacity:1],@"contents",
			nil];
		[services addObject:entry];
		[serviceTypes setObject:entry forKey:[entry objectForKey:@"name"]];
		[serviceBrowser reloadColumn:0];
	}
	// Add actual service to service type entry
	//NSLog(@"Adding service to type's array");
	[[[serviceTypes objectForKey:[service type]] objectForKey:@"contents"] addObject:service];
	
}

- (void)removeService:(NSNotification *)note {
	NSNetService *service = [note object];
	[[[serviceTypes objectForKey:[service type]] objectForKey:@"contents"] removeObject:service];
	if([[[serviceTypes objectForKey:[service type]] objectForKey:@"contents"] count] == 0) {
		//NSLog(@"No more services of this type: %@",[service type]);
		[services removeObject:[serviceTypes objectForKey:[service type]]];
		[serviceTypes removeObjectForKey:[service type]];
		[serviceBrowser reloadColumn:0];
	}
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
	//NSLog(@"Counting for browser");
	if(column == 0)
		return [services count];
	else if(column == 1)
		return [[[services objectAtIndex:[sender selectedRowInColumn:0]] objectForKey:@"contents"] count];
	else if(column == 2) {
		if([sender selectedRowInColumn:1] >= 0)
			return 3;
		else
			return 0;
	}
	else
		return 0;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
	//NSLog(@"Display for browser");
	NSNetService *serv;
	NSString *name = nil;
	if (column == 0)
		name = [[services objectAtIndex:row] objectForKey:@"name"];
	else if (column == 1) {
		if (row >= 0) {
			serv = [[[services objectAtIndex:[sender selectedRowInColumn:0]] objectForKey:@"contents"] objectAtIndex:row];
			name = [serv name];
		} else
			name = @"Error";
		//[cell setLeaf:YES];
	}
	else if(column == 2) {
		serv = [[[services objectAtIndex:[sender selectedRowInColumn:0]] objectForKey:@"contents"] objectAtIndex:[sender selectedRowInColumn:1]];
		[serv setDelegate:self];
		[serv resolve];
		switch(row) {
			case 0:
				//name = @"Name here";
				name = [serv name];
				break;
			case 1:
				if(resAddress && resPort)
					name = @"Unimplemented"; //name = [NSString stringWithFormat:@"%@:%@",resAddress,resPort];
				else
					name = @"No addresses yet";
				break;
			case 2:
				name = [serv protocolSpecificInformation];
				if (!name)
					name = @"";
				break;
			default:
				name = @"Invalid row";
		}
		[cell setLeaf:YES];
	}
	
	[cell setStringValue:name];
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
	//NSLog(@"Did resolve!");
	if ([[sender addresses] count]) {
		NSData * address;
		struct sockaddr * socketAddress = NULL;
		NSString * ipAddressString = nil;
		NSString * portString = nil;
		//int socketToRemoteServer;
		char buffer[256];
		
		// Iterate through addresses until we find an IPv4 address
		for (unsigned idx = 0U; idx < [[sender addresses] count]; ++idx) {
			address = [[sender addresses] objectAtIndex:idx];
			socketAddress = (struct sockaddr *)[address bytes];

			if (socketAddress->sa_len == sizeof(struct sockaddr_in))
				break;
		}
		
		if (socketAddress) {
			switch (socketAddress->sa_len) {
				case sizeof(struct sockaddr_in):
					if (inet_ntop(AF_INET, &((struct sockaddr_in *)socketAddress)->sin_addr, buffer, sizeof(buffer)))
						ipAddressString = [NSString stringWithCString:buffer];
					portString = [NSString stringWithFormat:@"%d", ntohs(((struct sockaddr_in *)socketAddress)->sin_port)];
					
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
			resAddress = ipAddressString;
			resPort = portString;
		}
	}
}
@end
