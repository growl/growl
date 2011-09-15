//
//  GrowlXPCRegistrationAttempt.m
//  Growl
//
//  Created by Rachel Blackman on 8/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlXPCRegistrationAttempt.h"

@implementation GrowlXPCRegistrationAttempt


+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeRegister;
}

- (void) begin
{
    if (![self establishConnection]) {
        [self failed];
        return;
    }
    
    if (![self sendMessageWithPurpose:@"registration" andReplyHandler:^(xpc_object_t reply) { [self handleReply:reply]; }])
        [self failed];
}

@end
