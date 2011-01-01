//
//  GrowlTCPPathway.h
//  Growl
//
//  Created by Peter Hosey on 2006-02-13.
//  Copyright 2006 The Growl Project. All rights reserved.
//

#import "GrowlRemotePathway.h"

@class MD5Authenticator;

@interface GrowlTCPPathway : GrowlRemotePathway {
	MD5Authenticator           *authenticator;
	NSNetService               *service;
	NSPort                     *socketPort;
	NSConnection               *serverConnection;
}

@end
