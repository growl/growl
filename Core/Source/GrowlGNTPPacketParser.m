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
#include "CFGrowlAdditions.h"

@implementation GrowlGNTPPacketParser

+ (GrowlGNTPPacketParser *)sharedParser
{
	static GrowlGNTPPacketParser *sharedParser = nil;
	if (!sharedParser) sharedParser= [[self alloc] init];
	return sharedParser;
}

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
#pragma mark -

/* We get here from GrowlApplicationController, which built the packet and destination address for us */
- (void)sendPacket:(GrowlGNTPOutgoingPacket *)packet toAddress:(NSData *)destAddress
{
	//			NSString *password = [entry objectForKey:@"password"];
	
	/* Will deallocate once sending is complete if we don't care about the reply, or after we get a reply if
	 * desired.
	 */
	AsyncSocket *outgoingSocket = [[AsyncSocket alloc] initWithDelegate:self];
	[outgoingSocket setUserData:GrowlGNTPPacketSocketUserData_WasInitiatedLocally];

	@try {
		NSError *connectionError = nil;
		[outgoingSocket connectToAddress:destAddress error:&connectionError];
		if (connectionError)
			NSLog(@"Failed to connect: %@", connectionError);
		else {
			[packet writeToSocket:outgoingSocket];
			
			if (![packet needsPersistentConnectionForCallback])
				[outgoingSocket disconnectAfterWriting];
		}
		
	} @catch (NSException *e) {
		NSString *addressString = createStringWithAddressData(destAddress);
		NSString *hostName = createHostNameForAddressData(destAddress);
		NSLog(@"Warning: Exception %@ while forwarding Growl notification to %@ (%@). Is that system on and connected?",
			  e, addressString, hostName);
		[addressString release];
		[hostName      release];
	} @finally {
		//Success!
	}
}	
	

#pragma mark -
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
	/* Prevent sending loops */
	if ([packet hasBeenReceivedPreviously]) {
		return;
	}

	BOOL success = YES;

	switch ([packet packetType]) {
		case GrowlUnknownPacketType:
			NSLog(@"This shouldn't happen; received %@ of an unknown type", packet);
			break;
		case GrowlNotifyPacketType:
		{
			GrowlNotificationResult result = [[GrowlApplicationController sharedInstance] dispatchNotificationWithDictionary:[packet growlDictionary]];
			switch (result) {
				case GrowlNotificationResultPosted:
					success = YES;
					break;
				case GrowlNotificationResultNotRegistered:
				{
					GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
					success = NO;
					[outgoingPacket setAction:@"-ERROR"];
					[outgoingPacket addHeaderItems:[packet headersForResult]];
					[outgoingPacket addHeaderItem:[GrowlGNTPHeaderItem headerItemWithName:@"Error-Description"
																					value:@"Application and notification must be registered before notifying"]];
					[outgoingPacket writeToSocket:[packet socket]];
					break;
				}
				case GrowlNotificationResultDisabled:
				{
					GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
					success = NO;
					[outgoingPacket setAction:@"-ERROR"];
					[outgoingPacket addHeaderItems:[packet headersForResult]];
					[outgoingPacket addHeaderItem:[GrowlGNTPHeaderItem headerItemWithName:@"Error-Description"
																					value:@"User has disabled display of this notification, or it is disabled by default and has not been enabled"]];
					[outgoingPacket writeToSocket:[packet socket]];
					break;
				}
			}
			break;
		}
		case GrowlRegisterPacketType:
			[[GrowlApplicationController sharedInstance] registerApplicationWithDictionary:[packet growlDictionary]];
			break;
		case GrowlCallbackPacketType:
		{
			
		}
	}
	
	/* Send the -OK response */
	if (success) {
		GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
		[outgoingPacket setAction:@"-OK"];
		[outgoingPacket addHeaderItems:[packet headersForResult]];
		[outgoingPacket writeToSocket:[packet socket]];
	}
	
	/* Set up to listen again on the same socket with a new packet */
	GrowlGNTPPacket *newPacket = [GrowlGNTPPacket networkPacketForSocket:[packet socket]];
	[newPacket setDelegate:self];	
	[currentNetworkPackets setObject:newPacket
							  forKey:[newPacket uuid]];		
	/* Now await incoming data using the new packet */
	[newPacket startProcessing];	
}

/*!
 * @brief A packet's socket disconnected
 *
 * This is unrelated to success vs. error; all we do here is stop tracking the packet.
 * Removing it from the currentNetworkPackets dictionary will likely lead to the object being released, as well.
 *
 * If we're going to send a URL callback later, we'll keep it in our currentNetworkPackets until that is sent since we
 * want to have all its data at that time.
 */
- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet
{
	if ([packet callbackResultSendBehavior] != GrowlGNTP_URLCallback)
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

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	/* Allocated in postGrowlNotificationClosed:viaNotificationClick: */
	[connection release];	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	/* Allocated in postGrowlNotificationClosed:viaNotificationClick: */
	NSLog(@"Callback via %@ failed with error %@", connection, error);
	[connection release];
}

/*!
 * @brief Pass click and closed/timed out notifications back to originating clients
 *
 * If the Growl notification is associated with an open socket to an originating client, and it has the appropriate 
 * Notification-Callback-Context headers, the originating client will be notified.
 */
- (void)postGrowlNotificationClosed:(GrowlApplicationNotification *)growlNotification viaNotificationClick:(BOOL)viaClick
{
	GrowlGNTPPacket *existingPacket = [currentNetworkPackets objectForKey:[[growlNotification dictionaryRepresentation] objectForKey:GROWL_NETWORK_PACKET_UUID]];

	if (existingPacket) {
		switch ([existingPacket callbackResultSendBehavior]) {
			case GrowlGNTP_NoCallback:
				/* No-op */
				break;
			case GrowlGNTP_TCPCallback:
			{
				GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
				[outgoingPacket setAction:@"-CALLBACK"];
				[outgoingPacket addHeaderItems:[existingPacket headersForCallbackResult_wasClicked:viaClick]];
				[outgoingPacket writeToSocket:[existingPacket socket]];
				break;
			}				
			case GrowlGNTP_URLCallback:
			{
				/* We'll release this NSURLConnection when the connection finishes sending or fails to do so. */
				[[NSURLConnection alloc] initWithRequest:[existingPacket urlRequestForCallbackResult_wasClicked:viaClick]
												delegate:self];

				 /* We can now stop tracking the packet in currentNetworkPackets. */
				[currentNetworkPackets removeObjectForKey:[existingPacket uuid]];
			}
		}
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
