//
//  GrowlNotificationServer.h
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GrowlNotificationProtocol
- (oneway void)registerApplication:(bycopy in NSDictionary *)dict;
- (oneway void)postNotification:(bycopy in NSDictionary *)notification;
@end

@interface GrowlNotificationServer : NSObject <GrowlNotificationProtocol>
{
}

@end
