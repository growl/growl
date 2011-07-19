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

//Primarily for debugging purposes, though subclasses may put the implementation here and simply implement -GNTPRepresentation to send this string dataUsingEncoding:NSUTF8StringEncoding.
- (NSString *) GNTPRepresentationAsString;
@end

@interface GrowlTCPPathway : GrowlRemotePathway <GrowlTCPServerDelegate, NSNetServiceDelegate> {
	GrowlTCPServer			*tcpServer;
	
	GrowlGNTPPacketParser	*networkPacketParser;
}

@property (nonatomic, retain) GrowlTCPServer *tcpServer;
@property (nonatomic, retain) GrowlGNTPPacketParser	*networkPacketParser;
@end
