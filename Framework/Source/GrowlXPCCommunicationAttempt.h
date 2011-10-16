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
    @private
    
    xpc_connection_t                    xpcConnection;
    
    NSString *                          notificationUuid;
    
}

+ (BOOL)canCreateConnection;
- (NSString *)purpose;

// This creates our XPC connection.
- (BOOL) establishConnection;

// Reply handler
- (void) handleReply:(xpc_object_t)reply NS_AVAILABLE(10_7, 5_0);

// This generates an XPC message for the communication dictionary, but
// will never wait for a reply.
- (BOOL) sendMessageWithPurpose:(NSString *)purpose;

@end
