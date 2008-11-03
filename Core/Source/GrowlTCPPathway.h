//
//  GrowlTCPPathway.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"
#import "GrowlGNTPPacketParser.h"
#import "GrowlTCPServer.h"

@class MD5Authenticator;

@protocol GNTPOutgoingItem
/*!
 * @brief Get the GNTP representation of an item
 *
 * The returned NSData is CRLF terminated and UTF8 encoded.
 */
- (NSData *)GNTPRepresentation;
@end

@interface GrowlTCPPathway : GrowlRemotePathway <GrowlTCPServerDelegate> {
	MD5Authenticator           *authenticator;
	NSNetService               *service;
	NSPort                     *socketPort;
	NSConnection               *remoteDistributedObjectConnection;
	NSConnection               *localDistributedObjectConnection;
	
	GrowlTCPServer				*tcpServer;
	
	GrowlGNTPPacketParser	*networkPacketParser;
}

@end
