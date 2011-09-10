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
#import "GrowlErrorGNTPPacket.h"
#import "GrowlNotificationGNTPPacket.h"
#import "GrowlTicketController.h"
#import "NSStringAdditions.h"
#import "GrowlGNTPDefines.h"
#import "GrowlApplicationTicket.h"
#import "GrowlTicketController.h"

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
	[outgoingSocket setUserData:packet];
	//NSLog(@"outgoingsocket is %p; userData is %@", outgoingSocket, [outgoingSocket userData]);
	@try {
		NSError *connectionError = nil;
		[outgoingSocket connectToAddress:destAddress error:&connectionError];
		if (connectionError) {
			NSLog(@"Failed to connect: %@", connectionError);
			[(NSString *)[outgoingSocket userData] release];
			[outgoingSocket setUserData:nil];

		} else {
			[packet writeToSocket:outgoingSocket];
			
         /* We will close the socket when we receive a reply, or failure */
		}
		
	} @catch (NSException *e) {
		NSString *addressString = [NSString stringWithAddressData:destAddress];
		NSString *hostName = [NSString hostNameForAddressData:destAddress];
		NSLog(@"Warning: Exception %@ while forwarding Growl notification to %@ (%@). Is that system on and connected?",
			  e, addressString, hostName);
	} @finally {
		//Success!
	}
}	
	

-(void)sendErrorString:(NSString*)errDescrip 
              withCode:(GrowlGNTPErrorCode)code 
             forPacket:(GrowlGNTPPacket*)packet 
{
   GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
   [outgoingPacket setAction:GrowlGNTPErrorResponseType];
   [outgoingPacket addHeaderItems:[packet headersForResult]];
   [outgoingPacket addHeaderItem:[GrowlGNTPHeaderItem headerItemWithName:@"Error-Description"
                                                                   value:errDescrip]];
   if(code != 0)
      [outgoingPacket addHeaderItem:[GrowlGNTPHeaderItem headerItemWithName:@"Error-Code" 
                                                                      value:[NSString stringWithFormat:@"%d", code]]];
   [outgoingPacket writeToSocket:[packet socket]];
   
   /* We won't be sending anymore on this socket */
   [[packet socket] disconnectAfterWriting];
}

#pragma mark -
- (GrowlGNTPPacket *)setupPacketForSocket:(GCDAsyncSocket *)socket
{
	GrowlGNTPPacket *packet = [GrowlGNTPPacket networkPacketForSocket:socket];
	[packet setDelegate:self];
	if ([socket userData] && [[socket userData] isKindOfClass:[GrowlGNTPOutgoingPacket class]]) {
		//NSLog(@"Setting packet ID to %@", [[socket userData] packetID]);
		[packet setPacketID:[[socket userData] packetID]];
      [packet setOriginPacket:[socket userData]];
		
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

/* The only sockets which should have PacketParser as its delegate are outgoing packets, we don't care about disconnected or no error */
- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError *)err
{
   if(err && [err code] != 7)
      NSLog(@"Outgoing packet (ID: %@) disconnected from host %@ with error: %@", (NSString*)[sock userData], [sock connectedHost], err);
   
   NSString *packetID = [[sock userData] packetID];
   if(packetID){
      [currentNetworkPackets removeObjectForKey:packetID];
   }
   [sock setUserData:nil];
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
   BOOL shouldListenForCallback = NO;
   BOOL shouldSendCallback = NO;
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
               if([packet callbackResultSendBehavior] == GrowlGNTP_TCPCallback)
                  shouldSendCallback = YES;
					break;
				case GrowlNotificationResultNotRegistered:
				{
               [self sendErrorString:@"Application and notification must be registered before notifying"
                            withCode:GrowlGNTPUnknownNotificationErrorCode
                           forPacket:packet];
					shouldSendOKResponse = NO;
					break;
				}
				case GrowlNotificationResultDisabled:
				{
               /*There is no defined error code for user disabled, faking with 1001 for now*/
               [self sendErrorString:@"User has disabled display of this notification, or it is disabled by default and has not been enabled"
                            withCode:GrowlGNTPUserDisabledErrorCode
                           forPacket:packet];
					/* Don't send -OK since we're sending -ERROR */
					shouldSendOKResponse = NO;
					break;
				}
			}
			break;
		}
		case GrowlSubscribePacketType:
			//TODO: store the subscription request information and update our subscriber datastore			
         shouldSendOKResponse = NO;
         [self sendErrorString:@"Subscriptions are unsupported in Growl 1.3" 
                      withCode:GrowlGNTPInvalidRequestErrorCode
                     forPacket:packet];
			break;
		case GrowlRegisterPacketType:
			[[GrowlApplicationController sharedInstance] registerApplicationWithDictionary:[packet growlDictionary]];
			break;
		case GrowlCallbackPacketType:
			[[GrowlApplicationController sharedInstance] growlNotificationDict:[packet growlDictionary]
												  didCloseViaNotificationClick:([(GrowlCallbackGNTPPacket *)packet callbackType] == GrowlGNTPCallback_Clicked)
																onLocalMachine:NO];
         [self growlNotificationDict:[packet growlDictionary] didCloseViaNotificationClick:([(GrowlCallbackGNTPPacket*)packet callbackType] == GrowlGNTPCallback_Clicked)];
         [[packet socket] disconnect];
			break;
      case GrowlErrorPacketType:
      {
         GrowlGNTPErrorCode code = [(GrowlErrorGNTPPacket*)packet errorCode];
         NSString *description = [(GrowlErrorGNTPPacket*)packet errorDescription];
         switch (code) {
            case GrowlGNTPUnknownApplicationErrorCode:
            case GrowlGNTPUnknownNotificationErrorCode:
            {
               NSLog(@"The application or notification is not registered on the host");
               if([packet originPacket]){
                  NSString *appName = [[[packet originPacket] growlDictionary] objectForKey:GROWL_APP_NAME];
                  GrowlApplicationTicket *ticket = [[GrowlTicketController sharedController] ticketForApplicationName:appName hostName:nil];
                  if(ticket){
                     /* We would reregister here if we had a valid registration dict stored somewhere
                        We will reinvestigate this in the future.
                      */
                     /*GrowlGNTPOutgoingPacket *registerPacket = [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_RegisterType
                                                                                                     forDict:[ticket growlDictionary]];
                     [registerPacket setKey:[[packet originPacket] key]];
                     [self sendPacket:registerPacket toAddress:[[packet socket] connectedAddress]];
                     [self sendPacket:[packet originPacket] toAddress:[[packet socket] connectedAddress]];*/
                  }else{
                     NSLog(@"Could not find ticket locally for %@ to send for reregistration", appName);
                  }
               }
               
               break;
            }
            case GrowlGNTPUserDisabledErrorCode:
               //Do nothing, remote host has disabled display of this notification
               break;
            default:
               //We don't handle any other case specifically, log it out.
               NSLog(@"Error packet, Error-Code: %d, Error-Description: %@", code, description);
               break;
         }
         //Whatever error we had, dont send a -OK, and go ahead and disconnect
         shouldSendOKResponse = NO;
         [[packet socket] disconnect];
         break;
		}
      case GrowlOKPacketType:
      {
			/* Ourobourous is not hungry tonight */ 
			shouldSendOKResponse = NO;
         if([[(GrowlOkGNTPPacket*)packet responseAction] caseInsensitiveCompare:GrowlGNTPNotificationMessageType] == NSOrderedSame &&
            [GrowlNotificationGNTPPacket callbackResultSendBehaviorForHeaders:[[packet originPacket] headerItems]] == GrowlGNTP_TCPCallback){
               shouldListenForCallback = YES;
         }else
			[[packet socket] disconnect];
  			break;
      }
	}
	
	/* Send the -OK response */
	if (shouldSendOKResponse) {
		GrowlGNTPOutgoingPacket *outgoingPacket = [GrowlGNTPOutgoingPacket outgoingPacket];
		[outgoingPacket setAction:@"-OK"];
		[outgoingPacket addHeaderItems:[packet headersForResult]];		
      [outgoingPacket writeToSocket:[packet socket]];
		
      if(!shouldSendCallback){
         [[packet socket] disconnectAfterWriting];
      }
   }
	
	/* Set up to listen again on the same socket with a new packet if we expect a callback */
   if(shouldListenForCallback && [packet wasInitiatedLocally])
   {
      NSLog(@"Listening for callback");
      GrowlGNTPPacket *newPacket = [GrowlGNTPPacket networkPacketForSocket:[packet socket]];
      [newPacket setDelegate:self];	
      [newPacket setOriginPacket:[packet originPacket]];
      [newPacket setWasInitiatedLocally:[packet wasInitiatedLocally]];
      [currentNetworkPackets setObject:newPacket
                                forKey:[newPacket packetID]];
      [currentNetworkPackets removeObjectForKey:[packet packetID]];
      
      /* Now await incoming data using the new packet */
      [[newPacket socket] readDataToData:[GCDAsyncSocket CRLFData]
                             withTimeout:-1
                                     tag:GrowlExhaustingRemainingDataRead];		

      [newPacket startProcessing];
   }
}

/*!
 * @brief A packet's socket disconnected
 *
 * This is unrelated to success vs. error; all we do here is stop tracking the packet.
 * Removing it from the currentNetworkPackets dictionary will likely lead to the object being released, as well.
 *
 * If we're going to send a URL or TCP callback later, we'll keep it in our currentNetworkPackets until that is sent since we
 * want to have all its data at that time.
 */
- (void)packetDidDisconnect:(GrowlGNTPPacket *)packet
{
   [currentNetworkPackets removeObjectForKey:[packet packetID]];
}

/*!
 * @brief A packet failed to be read
 *
 * Send the appropriate -ERROR response
 */
- (void)packet:(GrowlGNTPPacket *)packet failedReadingWithError:(NSError *)inError
{
	NSLog(@"Failed reading with error: %@", inError);
   [self sendErrorString:[[inError userInfo] objectForKey:NSLocalizedDescriptionKey]
                withCode:(GrowlGNTPErrorCode)[inError code]
               forPacket:packet];
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
	//NSLog(@"didCloseViaNotificationClick --> %@ --> %@", notificationID, existingPacket);
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
