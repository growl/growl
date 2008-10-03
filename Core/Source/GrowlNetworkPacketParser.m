//
//  GrowlNetworkPacketParser.m
//  Growl
//
//  Created by Evan Schoenberg on 9/5/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlNetworkPacketParser.h"
#import "GrowlNetworkPacket.h"

@implementation GrowlNetworkPacketParser

- (id)init
{
	if ((self = [super init])) {
		currentNetworkPackets = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc
{
	[currentNetworkPackets release];
	[super dealloc];
}

- (void)didAcceptNewSocket:(AsyncSocket *)socket
{
	GrowlNetworkPacket *packet = [GrowlNetworkPacket networkPacketForSocket:socket];
	[packet setDelegate:self];
	[currentNetworkPackets setObject:packet
							  forKey:[packet identifier]];
}

- (void)socket:(AsyncSocket *)socket didConnectToHost:(NSString *)host port:(UInt16)port
{
	[currentNetworkPackets setObject:packet
							  forKey:[NSValue valueWithNonretainedObject:socket]];
	[packet didConnectToHost:host port:port];
}

- (void)socket:(AsyncSocket *)socket didReadData:(NSData *)data withTag:(long)tag
{
	GrowlNetworkPacket *packet = [currentNetworkPackets objectForKey:[NSValue valueWithNonretainedObject:socket]];
	[packet didReadData:data withTag:tag];
}

@end
