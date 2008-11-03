//
//  GrowlGNTPPacketParser.m
//  Growl
//
//  Created by Evan Schoenberg on 9/5/08.
//  Copyright 2008 Adium X / Saltatory Software. All rights reserved.
//

#import "GrowlGNTPPacketParser.h"
#import "GrowlApplicationController.h"
#import "GrowlApplicationNotification.h"
#import "GrowlGNTPOutgoingPacket.h"

@implementation GrowlGNTPPacketParser

- (id)init
{
	if ((self = [super init])) {
		currentNetworkPackets = [[NSMutableDictionary alloc] init];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(notificationClicked:)
													 name:GROWL_NOTIFICATION_CLICKED
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(notificationTimedOut:)
													 name:GROWL_NOTIFICATION_TIMED_OUT
												   object:nil];		
	}
	
	return self;
}

- (void)dealloc
{
	[currentNetworkPackets release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

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

/*!
 * @brief Packet finished reading
 *
 * We tell Growl to notify or register as appropriate, then we send a success packet to the incoming packet's source
 */
- (void)packetDidFinishReading:(GrowlGNTPPacket *)packet
{
	switch ([packet packetType]) {
		case GrowlUnknownPacketType:
			NSLog(@"This shouldn't happen; received %@ of an unknown type", packet);
			break;
		case GrowlNotifyPacketType:
			[[GrowlApplicationController sharedInstance] dispatchNotificationWithDictionary:[packet growlDictionary]];
			break;
		case GrowlRegisterPacketType:
			[[GrowlApplicationController sharedInstance] registerApplicationWithDictionary:[packet growlDictionary]];
			break;
	}
	
	/* Send the success response */
	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
	[outgoingPacket setAction:@"-OK"];
	[outgoingPacket addHeaderItems:[packet headersForSuccessResult]];
	[outgoingPacket writeToSocket:[packet socket]];
}

- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet
{
	[currentNetworkPackets removeObjectForKey:[packet uuid]];
}

- (void)packet:(GrowlGNTPPacket *)packet failedReadingWithError:(NSError *)inError
{
	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
	[outgoingPacket setAction:@"-ERROR"];
	[outgoingPacket addHeaderItem:[GrowlGNTPHeaderItem headerItemWithName:@"Error-Description"
																	value:[[inError userInfo] objectForKey:NSLocalizedFailureReasonErrorKey]]];
	[outgoingPacket writeToSocket:[packet socket]];
}

#pragma mark -

- (void)postGrowlNotificationClosed:(GrowlApplicationNotification *)growlNotification viaNotificationClick:(BOOL)viaClick
{
	NSLog(@"%@ --> %@", [[growlNotification dictionaryRepresentation] objectForKey:GROWL_NETWORK_PACKET_UUID],
		  [currentNetworkPackets objectForKey:[[growlNotification dictionaryRepresentation] objectForKey:GROWL_NETWORK_PACKET_UUID]]);
}

- (void)notificationClicked:(NSNotification *)notification
{
	GrowlApplicationNotification *growlNotification = [notification object];
	
	[self postGrowlNotificationClosed:growlNotification
				 viaNotificationClick:[[[growlNotification dictionaryRepresentation] objectForKey:GROWL_CLICK_HANDLER_ENABLED] boolValue]];	
}

- (void)notificationTimedOut:(NSNotification *)notification
{
	GrowlApplicationNotification *growlNotification = [notification object];
	
	[self postGrowlNotificationClosed:growlNotification
				 viaNotificationClick:NO];		
}


@end
