//
//  GrowlUDPServer.h
//  Growl
//
//  Created by Ingmar Stein on 18.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GROWL_UDP_PORT 9887

#define GROWL_NN_PRIORITY_LOW			0x0
#define GROWL_NN_PRIORITY_MODERATE		0x1
#define GROWL_NN_PRIORITY_NORMAL		0x2
#define GROWL_NN_PRIORITY_HIGH			0x3
#define GROWL_NN_PRIORITY_EMERGENCY		0x4
#define GROWL_NN_PRIORITY_MASK			0x7
#define GROWL_NN_STICKY					0x8

typedef struct GrowlNetworkNotification_s {
	unsigned int flags;
	unsigned int nameLen;
	unsigned int titleLen;
	unsigned int descriptionLen;
	unsigned int appNameLen;
	unsigned char data[];	/* variable sized */
} GrowlNetworkNotification;

@interface GrowlUDPServer : NSObject
{
	NSSocketPort *sock;
	NSFileHandle *fh;
}
@end
