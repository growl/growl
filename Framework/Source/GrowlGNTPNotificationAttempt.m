//
//  GrowlGNTPNotificationAttempt.m
//  Growl
//
//  Created by Peter Hosey on 2011-07-14.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlGNTPNotificationAttempt.h"

#import "GrowlDefines.h"
#import "GrowlGNTPOutgoingPacket.h"

@implementation GrowlGNTPNotificationAttempt

+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeNotify;
}

- (GrowlGNTPOutgoingPacket *) packet {
	return [GrowlGNTPOutgoingPacket outgoingPacketOfType:GrowlGNTPOutgoingPacket_NotifyType forDict:self.dictionary];
}

- (BOOL) expectsCallback {
	return (_Bool)[self.dictionary objectForKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
}

@end
