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

	/* Note: We're tracking a GrowlGNTPPacket, but its specific packet (a GrowlNotificationGNTPPacket or 
	 * GrowlRegisterGNTPPacket) will be where the action hides.
	 */
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
	
	/* Send the -OK response */
	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
	[outgoingPacket setAction:@"-OK"];
	[outgoingPacket addHeaderItems:[packet headersForSuccessResult]];
	[outgoingPacket writeToSocket:[packet socket]];
}

/*!
 * @brief A packet's socket disconnected
 *
 * This is unrelated to success vs. error; all we do here is stop tracking the packet.
 * Removing it from the currentNetworkPackets dictionary will likely lead to the object being released, as well.
 */
- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet
{
	[currentNetworkPackets removeObjectForKey:[packet uuid]];
}

/*!
 * @brief A packet failed to be read
 *
 * Send the appropriate -ERROR response
 */
- (void)packet:(GrowlGNTPPacket *)packet failedReadingWithError:(NSError *)inError
{
	GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
	[outgoingPacket setAction:@"-ERROR"];
	[outgoingPacket addHeaderItem:[GrowlGNTPHeaderItem headerItemWithName:@"Error-Description"
																	value:[[inError userInfo] objectForKey:NSLocalizedFailureReasonErrorKey]]];
	[outgoingPacket writeToSocket:[packet socket]];
}

#pragma mark -

/*!
 * @brief Pass click and closed/timed out notifications back to originating clients
 *
 * If the Growl notification is associated with an open socket to an originating client, and it has the appropriate 
 * Notification-Callback-Context headers, the originating client will be notified.
 */
- (void)postGrowlNotificationClosed:(GrowlApplicationNotification *)growlNotification viaNotificationClick:(BOOL)viaClick
{
	GrowlGNTPPacket *existingPacket = [currentNetworkPackets objectForKey:[[growlNotification dictionaryRepresentation] objectForKey:GROWL_NETWORK_PACKET_UUID]];
	if (existingPacket && [existingPacket shouldSendCallbackResult]) {
		GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
		[outgoingPacket setAction:(viaClick ? @"-CLICKED" : @"-CLOSED")];
		[outgoingPacket addHeaderItems:[existingPacket headersForCallbackResult]];
		[outgoingPacket writeToSocket:[existingPacket socket]];
		[[existingPacket socket] disconnectAfterWriting];
	}
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
