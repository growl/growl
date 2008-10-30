//
//  GrowlGNTPPacketParser.m
//  Growl
//
//  Created by Evan Schoenberg on 9/5/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlGNTPPacketParser.h"
#import "GrowlApplicationController.h"

@implementation GrowlGNTPPacketParser

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
	GrowlGNTPPacket *packet = [GrowlGNTPPacket networkPacketForSocket:socket];
	[packet setDelegate:self];
	NSLog(@"Created %@", packet);
	[currentNetworkPackets setObject:packet
							  forKey:[packet uuid]];
}

- (void)packetDidFinishReading:(GrowlGNTPPacket *)packet
{
	switch ([packet packetType]) {
		case GrowlUnknownPacketType:
			NSLog(@"This shouldn't happen; received %@ of an unknown type", packet);
			break;
		case GrowlNotifyPacketType:
			NSLog(@"Notifying %@", [packet growlDictionary]);
			[[GrowlApplicationController sharedInstance] dispatchNotificationWithDictionary:[packet growlDictionary]];
			break;
		case GrowlRegisterPacketType:
			NSLog(@"Registering %@", [packet growlDictionary]);
			[[GrowlApplicationController sharedInstance] registerApplicationWithDictionary:[packet growlDictionary]];
			break;
	}
}

- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet
{
	[currentNetworkPackets removeObjectForKey:[packet uuid]];
}

@end
