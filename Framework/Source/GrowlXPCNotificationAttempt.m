//
//  GrowlXPCNotificationAttempt.m
//  Growl
//
//  Created by Rachel Blackman on 9/2/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlXPCNotificationAttempt.h"

@implementation GrowlXPCNotificationAttempt


+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeNotify;
}

- (void) begin
{
    if (![self establishConnection]) {
        [self failed];
        return;
    }
    
    if (![self sendMessageWithPurpose:@"notification" andReplyHandler:^(xpc_object_t reply) { [self handleReply:reply]; }])
        [self failed];
}

@end
