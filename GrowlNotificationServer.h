//
//  GrowlNotificationServer.h
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GrowlNotificationProtocol
- (void)dispatchNotification:(NSDictionary *)notification;
@end

@interface GrowlNotificationServer : NSObject <GrowlNotificationProtocol>
{
}

@end
