//
//  GrowlXPCCommunicationAttempt.m
//  Growl
//
//  Created by Rachel Blackman on 8/22/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlXPCCommunicationAttempt.h"
#import "GrowlDefines.h"
#import "NSObject+XPCHelpers.h"

#import <xpc/xpc.h>

@implementation GrowlXPCCommunicationAttempt

+ (NSString*)XPCBundleID
{
   return [NSString stringWithFormat:@"%@.GNTPClientService"];
}

+ (BOOL)canCreateConnection
{
   static xpc_connection_t connect = NULL;
   
   if (xpc_connection_create == NULL)
      return NO;
   
   if(!connect){   
      connect = xpc_connection_create([[GrowlXPCCommunicationAttempt XPCBundleID] UTF8String], dispatch_get_main_queue());
      if(!connect)
         return NO;
   }
   return YES;
}

- (BOOL) establishConnection
{
    if (xpc_connection_create == NULL) {
        // We are not on Lion.  We can't do this.
        return NO;
    }
    
    //Third party developers will need to make sure to rename the bundle, executable, and info.plist stuff to tld.company.product.GNTPClientService    
    xpcConnection = xpc_connection_create([[GrowlXPCCommunicationAttempt XPCBundleID] UTF8String], dispatch_get_main_queue());
    if (!xpcConnection)
        return NO;
    
    return YES;
}

- (void) handleReply:(xpc_object_t)reply
{
    // We received a reply, which will either be a 'success' marker 
    // for registration, or some horrific failure.  "Do or do not,
    // there is no try."
    
    xpc_type_t type = xpc_get_type(reply);
    
    if (XPC_TYPE_ERROR == type) {
        [self failed];
        return; 
    }
    
    if (XPC_TYPE_DICTIONARY != type) {
        [self failed];
        return;
    }
    
    BOOL success = xpc_dictionary_get_bool(reply, "success");
    
    if (success)
        [self succeeded];
    else
        [self failed];
}

- (BOOL) sendMessageWithPurpose:(NSString *)purpose andReplyHandler:(void (^)(xpc_object_t))handler
{
    if (!xpcConnection)
        return NO;
    
    xpc_object_t xpcMessage = xpc_dictionary_create(NULL, NULL, 0);
    
    // Add the known parameters, yay!
    xpc_dictionary_set_string(xpcMessage, "growlMessagePurpose", [purpose UTF8String]);
    
    xpc_object_t growlDict = [self.dictionary newXPCObject];
    xpc_dictionary_set_value(xpcMessage, "GrowlDict", growlDict);
    xpc_release(growlDict);
    
    xpc_connection_send_message_with_reply(xpcConnection, xpcMessage, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT ,0), handler);
    
    xpc_release(xpcMessage);
    
    return YES;
}

- (BOOL) sendMessageWithPurpose:(NSString *)purpose
{
    if (!xpcConnection)
        return NO;
    
    xpc_object_t xpcMessage = xpc_dictionary_create(NULL, NULL, 0);
    
    // Add the known parameters, yay!
    xpc_dictionary_set_string(xpcMessage, "growlMessagePurpose", [purpose UTF8String]);
    
    // And now we start building the message.
    for (NSString *key in [self.dictionary allKeys]) {
        id keyValue = [self.dictionary objectForKey:key];
        
        if ([keyValue isKindOfClass:[NSString class]]) {
            NSString *keyString = (NSString *)keyValue;
            xpc_dictionary_set_string(xpcMessage, [key UTF8String], [keyString UTF8String]);
        }
        else if ([keyValue isKindOfClass:[NSData class]]) {
            NSData *keyData = (NSData *)keyValue;
            xpc_dictionary_set_data(xpcMessage, [key UTF8String], [keyData bytes], [keyData length]);
        }
        else if ([keyValue isKindOfClass:[NSNumber class]]) {
            // Okay, we need to get a little clever here, since I can't tell if this is a bool or no.
            // At least, not without checking what this parameter is.
            
            NSNumber *keyNumber = (NSNumber *)keyValue;
            if ([key isEqualToString:GROWL_NOTIFICATION_STICKY]) {
                xpc_dictionary_set_bool(xpcMessage, [key UTF8String], [keyNumber boolValue]);
            }
            else {
                xpc_dictionary_set_int64(xpcMessage, [key UTF8String], [keyNumber integerValue]);
            }
        }
    }
    
    xpc_connection_send_message(xpcConnection, xpcMessage);
    
    xpc_release(xpcMessage);
    
    return YES;
}

@end
