//
//  GrowlUDPServer.h
//  Growl
//
//  Created by Ingmar Stein on 18.11.04.
//  Copyright 2004 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>

#define GROWL_UDP_PORT 9887

#define GROWL_TYPE_REGISTRATION	0
#define GROWL_TYPE_NOTIFICATION	1

/*
 * This struct is common to all incoming network packets and identifies
 * the type of the packet.
 */
struct GrowlNetworkPacket {
	unsigned char type;
};

/*
 * A registration packet.
 */
struct GrowlNetworkRegistration {
	struct GrowlNetworkPacket common;
	struct GrowlNetworkRegistrationFlags {
		unsigned reserved: 31;
		unsigned hasIcon:  1;
	} flags; //size = 32 (31 + 1)
	unsigned int appNameLen;
	unsigned int numAllNotifications;
	unsigned int numDefaultNotifications;
	unsigned int appIconLen;
	/*
	 * Variable sized. Format:
	 * <application name><all notifications><default notifications>[application icon]
	 */
	unsigned char data[];
};

/**
 * A notification packet.
 */
struct GrowlNetworkNotification {
	struct GrowlNetworkPacket common;
	struct GrowlNetworkNotificationFlags {
		unsigned reserved: 25;
		unsigned hasIcon:  1;
		unsigned iconType: 2; // 0 = URL, 1 = icon of application, 2=icon of file, 3=image data
		signed   priority: 3;
		unsigned sticky:   1;
	} flags; //size = 32 (25 + 1 + 2 + 3 + 1)
	unsigned int nameLen;
	unsigned int titleLen;
	unsigned int descriptionLen;
	unsigned int appNameLen;
	unsigned int iconLen;
	/*
	 * Variable sized. Format:
	 * <notification name><title><description><application name>[icon]
	 */
	unsigned char data[];
};

@interface GrowlUDPServer : NSObject {
	NSSocketPort *sock;
	NSFileHandle *fh;
}

@end
