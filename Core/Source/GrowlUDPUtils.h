//
//  GrowlUDPUtils.h
//  Growl
//
//  Created by Ingmar Stein on 20.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum GrowlAuthenticationMethod {
	GROWL_AUTH_NONE,
	GROWL_AUTH_MD5,
	GROWL_AUTH_SHA256
};

@interface GrowlUDPUtils : NSObject {
}
+ (unsigned char *) registrationToPacket:(NSDictionary *)aNotification digest:(enum GrowlAuthenticationMethod)authMethod password:(const char *)password packetSize:(unsigned int *)packetSize;
+ (unsigned char *) notificationToPacket:(NSDictionary *)aNotification digest:(enum GrowlAuthenticationMethod)authMethod password:(const char *)password packetSize:(unsigned int *)packetSize;

@end
