//
//  GrowlGNTPPacketParser.m
//  Growl
//
//  Created by Evan Schoenberg on 9/5/08.
//  Copyright 2008-2009 The Growl Project. All rights reserved.
//

#import "GrowlGNTPPacketParser.h"
#import "GrowlApplicationController.h"
#import "GrowlNotification.h"
#import "GrowlGNTPOutgoingPacket.h"
#import "GrowlCallbackGNTPPacket.h"
#import "GrowlTicketController.h"
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
	/* Will deallocate once sending is complete if we don't care about the reply, or after we get a reply if
	 * desired.
	 */
	GCDAsyncSocket *outgoingSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
	[outgoingSocket setUserData:[[packet packetID] retain]];
	NSLog(@"outgoingsocket is %p; userData is %@", outgoingSocket, (NSString *)[outgoingSocket userData]);
	@try {
		NSError *connectionError = nil;
		[outgoingSocket connectToAddress:destAddress error:&connectionError];
		if (connectionError) {
			NSLog(@"Failed to connect: %@", connectionError);
			[(NSString *)[outgoingSocket userData] release];
			[outgoingSocket setUserData:nil];

		} else {
			[packet writeToSocket:outgoingSocket];
			
			/* While other implementations may keep the connection open for further use, Growl does not. */
			if (![packet needsPersistentConnectionForCallback]) {
				NSLog(@"will disconnect after writing");
				[outgoingSocket disconnectAfterWriting];
			}
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
- (GrowlGNTPPacket *)setupPacketForSocket:(GCDAsyncSocket *)socket
{
	GrowlGNTPPacket *packet = [GrowlGNTPPacket networkPacketForSocket:socket];
	[packet setDelegate:self];
	if ([socket userData] && [(NSObject *)[socket userData] isKindOfClass:[NSString class]]) {
		NSLog(@"Setting packet ID to %@", (NSString *)[socket userData]);
		[packet setPacketID:(NSString *)[socket userData]];
		
		/* Retained in sendPacket:toAddress: */
		[(NSString *)[socket userData] release];
		[socket setUserData:nil];
	}
	
	/* Note: We're tracking a GrowlGNTPPacket, but its specific packet (a GrowlNotificationGNTPPacket or 
	 * GrowlRegisterGNTPPacket) will be where the action hides.
	 */
	[currentNetworkPackets setObject:packet
							  forKey:[packet packetID]];	
	
	return packet;
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	GrowlGNTPPacket *packet = [self setupPacketForSocket:sock];
	[packet setWasInitiatedLocally:YES];
    [packet startProcessing];
}

- (void)didAcceptNewSocket:(GCDAsyncSocket *)socket
{
	GrowlGNTPPacket *packet = [self setupPacketForSocket:socket];
    [packet startProcessing];
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

	BOOL shouldSendOKResponse = YES;
	NSLog(@"incoming Packet: %@", packet);
	
	switch ([packet packetType]) {
		case GrowlUnknownPacketType:
			NSLog(@"This shouldn't happen; received %@ of an unknown type", packet);
			break;
		case GrowlNotifyPacketType:
		{
			GrowlNotificationResult result = [[GrowlApplicationController sharedInstance] dispatchNotificationWithDictionary:[packet growlDictionary]];
			switch (result) {
				case GrowlNotificationResultPosted:
					break;
				case GrowlNotificationResultNotRegistered:
				{
					GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
					shouldSendOKResponse = NO;
					/* Don't send -OK since we're sending -ERROR */
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
					/* Don't send -OK since we're sending -ERROR */
					shouldSendOKResponse = NO;
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
		case GrowlSubscribePacketType:
			//TODO: store the subscription request information and update our subscriber datastore			
			break;
		case GrowlRegisterPacketType:
			[[GrowlApplicationController sharedInstance] registerApplicationWithDictionary:[packet growlDictionary]];
			break;
		case GrowlCallbackPacketType:
			[[GrowlApplicationController sharedInstance] growlNotificationDict:[packet growlDictionary]
												  didCloseViaNotificationClick:([(GrowlCallbackGNTPPacket *)packet callbackType] == GrowlGNTPCallback_Clicked)
																onLocalMachine:NO];
			break;
		case GrowlOKPacketType:
			/* Ourobourous is not hungry tonight */ 
			shouldSendOKResponse = NO;
			break;
	}
	
	/* Send the -OK response */
	if (shouldSendOKResponse) {
		GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
		[outgoingPacket setAction:@"-OK"];
		[outgoingPacket addHeaderItems:[packet headersForResult]];		
		
		NSLog(@"outgoingPacket: %@", [outgoingPacket description]);
		[outgoingPacket writeToSocket:[packet socket]];
	}
	
	/* Set up to listen again on the same socket with a new packet */
	GrowlGNTPPacket *newPacket = [GrowlGNTPPacket networkPacketForSocket:[packet socket]];
	[newPacket setDelegate:self];	
	[currentNetworkPackets setObject:newPacket
							  forKey:[newPacket packetID]];

	/* And stop caring about the old packet if we just received a callback */
	if ([packet packetType] == GrowlCallbackPacketType) {
		[currentNetworkPackets removeObjectForKey:[packet packetID]];
	}

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
		[currentNetworkPackets removeObjectForKey:[packet packetID]];
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
	[outgoingPacket addHeaderItems:[packet headersForResult]];
	[outgoingPacket addHeaderItem:[GrowlGNTPHeaderItem headerItemWithName:@"Error-Description"
																	value:[[inError userInfo] objectForKey:NSLocalizedDescriptionKey]]];
	[outgoingPacket writeToSocket:[packet socket]];
}

- (void)packet:(GrowlGNTPPacket *)packet willChangePacketIDFrom:(NSString *)oldPacketID to:(NSString *)newPacketID
{
	/* Note that it is possible that ([currentNetworkPackets objectForKey:oldPacketID] != packet).
	 * packet may be [[currentNetworkPackets objectForKey:oldPacketID] specificPacket]. We don't want to release the 
	 * parent too early! We therefore do the lookup-and-set rather than a more 'direct' setObject:packet.
	 */
	[currentNetworkPackets setObject:[currentNetworkPackets objectForKey:oldPacketID] forKey:newPacketID];
	[currentNetworkPackets removeObjectForKey:oldPacketID];
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
- (void)growlNotificationDict:(NSDictionary *)growlNotificationDict didCloseViaNotificationClick:(BOOL)viaClick
{
	if (viaClick) {
		NSString *appName = [growlNotificationDict objectForKey:GROWL_APP_NAME];
      NSString *hostName = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_GNTP_SENT_BY];
		GrowlApplicationTicket *ticket = [[GrowlTicketController sharedController] ticketForApplicationName:appName hostName:hostName];
		
		/* Don't advertise that the notification closed via a click if click handlers are disabled */
		if (ticket && ![ticket clickHandlersEnabled])
			viaClick = NO;
	}

	NSString *notificationID = [growlNotificationDict objectForKey:GROWL_NOTIFICATION_INTERNAL_ID];
	GrowlGNTPPacket *existingPacket = (notificationID ? [currentNetworkPackets objectForKey:notificationID] : nil);
	NSLog(@"didCloseViaNotificationClick --> %@ --> %@", notificationID, existingPacket);
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
				[currentNetworkPackets removeObjectForKey:[existingPacket packetID]];
			}
		}
	}
}

- (void) notificationClicked:(NSNotification *)notification {
	GrowlNotification *growlNotification = [notification object];
	
	[self growlNotificationDict:[growlNotification dictionaryRepresentation] didCloseViaNotificationClick:YES];
}

- (void) notificationTimedOut:(NSNotification *)notification {
	GrowlNotification *growlNotification = [notification object];
	
	[self growlNotificationDict:[growlNotification dictionaryRepresentation] didCloseViaNotificationClick:NO];
}

@end
