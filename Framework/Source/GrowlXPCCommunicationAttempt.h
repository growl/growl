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
			
	NSDictionary *sendingDetails;
	NSDictionary *responseDict;
    
    xpc_connection_t connection;
}

@property (nonatomic, retain) NSDictionary *sendingDetails;
@property (nonatomic, retain) NSDictionary *responseDict;
@property (nonatomic, retain) xpc_connection_t connection NS_AVAILABLE(10_7, 5_0) __attribute__((NSObject));

+ (BOOL)canCreateConnection;
+ (void)shutdownXPC;

- (NSString *)purpose;

// This creates our XPC connection.
- (BOOL) establishConnection;

// Reply handler
- (void) handleReply:(xpc_object_t)reply NS_AVAILABLE(10_7, 5_0);

// This generates an XPC message for the communication dictionary, but
// will never wait for a reply.
- (BOOL) sendMessageWithPurpose:(NSString *)purpose;

@end
