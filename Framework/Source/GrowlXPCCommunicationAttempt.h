//
//  GrowlXPCCommunicationAttempt.h
//  Growl
//
//  Created by Rachel Blackman on 8/22/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlCommunicationAttempt.h"
#import <xpc/xpc.h>

@interface GrowlXPCCommunicationAttempt : GrowlCommunicationAttempt {
    
    xpc_connection_t                    xpcConnection;
    
    NSString *                          notificationUuid;
    
}

// This creates our XPC connection.
- (BOOL) establishConnection;

// Reply handler
- (void) handleReply:(xpc_object_t)reply;

// This generates an XPC message for the communication dictionary, but
// will never wait for a reply.
- (BOOL) sendMessageWithPurpose:(NSString *)purpose;

// This generates an XPC message for the communication dictionary, and
// will wait for a reply.  Upon receiving a reply, the handler block
// will be executed with the reply object as the sole parameter.
- (BOOL) sendMessageWithPurpose:(NSString *)purpose andReplyHandler:(void (^)(xpc_object_t))handler;

@end
