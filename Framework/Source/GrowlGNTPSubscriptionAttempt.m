//
//  GrowlGNTPSubscriptionAttempt.m
//  Growl
//
//  Created by Daniel Siemer on 7/14/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlGNTPSubscriptionAttempt.h"
#import "GNTPSubscribePacket.h"

@implementation GrowlGNTPSubscriptionAttempt

+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeSubscribe;
}

-(NSData*)outgoingData {
	return [GNTPSubscribePacket gntpDataFromGrowlDictionary:self.dictionary ofType:@"SUBSCRIBE" withKey:self.key];
}

@end
