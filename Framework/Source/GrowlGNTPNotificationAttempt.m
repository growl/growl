//
//  GrowlGNTPNotificationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPNotificationAttempt.h"

#import "GrowlDefines.h"
#import "GNTPNotifyPacket.h"

@implementation GrowlGNTPNotificationAttempt

+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeNotify;
}

-(NSData*)outgoingData {
	return [GNTPNotifyPacket gntpDataFromGrowlDictionary:self.dictionary ofType:@"NOTIFY" withKey:self.key];
}

- (BOOL) expectsCallback {
	return ([self.dictionary objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT] != nil);
}

@end
