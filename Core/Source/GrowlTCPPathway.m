//
//  GrowlTCPPathway.m
//  Growl
//
//  Created by Peter Hosey on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlTCPPathway.h"
#import "GrowlTCPServer.h"
#import "GrowlGNTPPacketParser.h"

#import "GNTPServer.h"
#import "GrowlNotification.h"
@interface GrowlTCPPathway ()
@property (nonatomic, retain) GNTPServer *server;
@end

@implementation GrowlTCPPathway
@synthesize networkPacketParser;
@synthesize tcpServer;

@synthesize server = _server;

- (id)init
{
	if ((self = [super init])) {
//		self.networkPacketParser = [GrowlGNTPPacketParser sharedParser];
//		
//		/* We always want the TCP server to be running to allow localhost connections.
//		 * We'll ultimately ignore connections from outside localhost if networking is not enabled.
//		 */
//		self.tcpServer = [[[GrowlTCPServer alloc] init] autorelease];
//
//		/* GrowlTCPServer will use our host name by default for publishing, which is what we want. */
//		[self.tcpServer setType:@"_gntp._tcp."];
//		[self.tcpServer setPort:GROWL_TCP_PORT];
//		[self.tcpServer setDelegate:self];
//		
//		NSError *error = nil;
//		if (![self.tcpServer start:&error])
//			NSLog(@"Error starting Growl TCP server: %@", error);
//		[[self.tcpServer netService] setDelegate:self];
//      
//      [self.tcpServer preferencesChanged:nil];
		self.server = [[GNTPServer alloc] init];
		[self.server startServer];
		
		[[NSNotificationCenter defaultCenter] addObserverForName:GROWL_NOTIFICATION_CLICKED
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:^(NSNotification *note) {
																		 GrowlNotification *growlNote = [note object];
																		 [self.server notificationClicked:[growlNote dictionaryRepresentation]];
																	 }];
		[[NSNotificationCenter defaultCenter] addObserverForName:GROWL_NOTIFICATION_TIMED_OUT
																		  object:nil
																			queue:[NSOperationQueue mainQueue]
																	 usingBlock:^(NSNotification *note) {
																		 GrowlNotification *growlNote = [note object];
																		 [self.server notificationTimedOut:[growlNote dictionaryRepresentation]];
																	 }];
	}
		
	return self;
}

- (void)dealloc
{		
//	[tcpServer stop];
//	[tcpServer release];
//	
//	[networkPacketParser release];
//	
	[super dealloc];
}

#pragma mark -

/*- (void) netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	NSLog(@"WARNING: could not publish Growl service. Error: %@", errorDict);
}*/

#pragma mark -
/*
- (BOOL) connection:(NSConnection *)ancestor shouldMakeNewConnection:(NSConnection *)conn {
	[conn setDelegate:[ancestor delegate]];
	return YES;
}*/
 
#pragma mark -

/*!
 * @brief The TCP server accepted a new socket. Pass it to the network packet parser.
 */
- (void)didAcceptNewSocket:(GCDAsyncSocket *)sock
{
	//NSLog(@"%@: Telling %@ we accepted on socket %@ with FD %i", self, networkPacketParser, sock, [sock socket4FD]);
//	[networkPacketParser didAcceptNewSocket:sock];
}

@end
