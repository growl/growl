//
//  GrowlNotificationServer.m
//  Growl
//
//  Created by Ingmar Stein on 15.11.04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "GrowlNotificationServer.h"
#import "GrowlController.h"

@implementation GrowlNotificationServer
- (void)registerApplication:(NSDictionary *)dict
{
	[[GrowlController singleton] _registerApplicationWithDictionary:dict];
}

- (void)postNotification:(NSDictionary *)notification
{
	[[GrowlController singleton] dispatchNotificationWithDictionary:notification];
}
@end
