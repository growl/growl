//
//  NetworkNotifier.h
//  HardwareGrowler
//
//  Created by Ingmar Stein on 18.02.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SCDynamicStore;

extern NSString *NotifierNetworkLinkUpNotification;
extern NSString *NotifierNetworkLinkDownNotification;
extern NSString *NotifierNetworkIpAcquiredNotification;
extern NSString *NotifierNetworkIpReleasedNotification;
extern NSString *NotifierNetworkAirportConnectNotification;
extern NSString *NotifierNetworkAirportDisconnectNotification;

@interface NetworkNotifier : NSObject {
	SCDynamicStore *scNotificationManager;
	NSMutableDictionary *airportStatus;
}

@end
