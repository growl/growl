//
//  GrowlTCPPathway.h
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"
#import "GrowlGNTPPacketParser.h"

@class MD5Authenticator;

@class GrowlTCPServer;

@interface GrowlTCPPathway : GrowlRemotePathway {
	MD5Authenticator           *authenticator;
	NSNetService               *service;
	NSPort                     *socketPort;
	NSConnection               *remoteDistributedObjectConnection;
	NSConnection               *localDistributedObjectConnection;
	
	GrowlTCPServer				*tcpServer;
	
	GrowlGNTPPacketParser	*networkPacketParser;
}

@end
