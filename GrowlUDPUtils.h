//
//  GrowlUDPUtils.h
//  Growl
//
//  Created by Ingmar Stein on 20.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface GrowlUDPUtils : NSObject {
}
+ (char *) registrationToPacket:(NSDictionary *)aNotification packetSize:(unsigned int *)packetSize;
+ (char *) notificationToPacket:(NSDictionary *)aNotification packetSize:(unsigned int *)packetSize;

@end
