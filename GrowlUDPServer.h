//
//  GrowlUDPServer.h
//  Growl
//
//  Created by Ingmar Stein on 18.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GROWL_UDP_PORT 9887

struct GrowlNetworkNotification {
	struct {
		unsigned reserved: 28;
		signed   priority: 3;
		unsigned sticky:   1;
	} flags; //size = 32 (28 + 3 + 1)
	unsigned nameLen;
	unsigned titleLen;
	unsigned descriptionLen;
	unsigned appNameLen;
	unsigned char data[];	/* variable sized */
};

@interface GrowlUDPServer : NSObject
{
	NSSocketPort *sock;
	NSFileHandle *fh;
}
@end
