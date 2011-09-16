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
#import "GrowlGNTPDefines.h"

#import <xpc/xpc.h>

@implementation GrowlXPCCommunicationAttempt

+ (NSString*)XPCBundleID
{
   return [NSString stringWithFormat:@"%@.GNTPClientService", [[NSBundle mainBundle] bundleIdentifier]];
}

+ (BOOL)canCreateConnection
{   
   static BOOL searched = NO;
   static BOOL found = NO;
   if (xpc_connection_create == NULL)
      return NO;
   
   if(searched) 
      return found;
   
   NSString *appPath = [[NSBundle mainBundle] bundlePath];
   NSString *xpcSubPath = [NSString stringWithFormat:@"Contents/XPCServices/%@", [self XPCBundleID]];
   NSString *xpcPath = [[appPath  stringByAppendingPathComponent:xpcSubPath] stringByAppendingPathExtension:@"xpc"];
   NSLog(@"xpc path: %@", xpcSubPath);
   
   searched = YES;
   //If the file exists, and we can create an XPC, lets use it instead.
   if([[NSFileManager defaultManager] fileExistsAtPath:xpcPath]){
      found = YES;
      return YES;
   }else
      return NO;
}

- (NSString *)purpose
{
   return @"erehwon";
}

- (void)begin
{
   if (![self establishConnection]) {
      [self failed];
      return;
   }
   
   if (![self sendMessageWithPurpose:[self purpose]])
      [self failed];
}

- (void)finished
{
   [super finished];
}

- (BOOL) establishConnection
{
    if (xpc_connection_create == NULL) {
        // We are not on Lion.  We can't do this.
        return NO;
    }
    
   __block GrowlXPCCommunicationAttempt *blockSafe = self;
    //Third party developers will need to make sure to rename the bundle, executable, and info.plist stuff to tld.company.product.GNTPClientService 
   xpcConnection = xpc_connection_create(/*"com.Growl.BeepHammer.GNTPClientService"*/[[GrowlXPCCommunicationAttempt XPCBundleID] UTF8String], dispatch_get_main_queue());
    if (!xpcConnection)
        return NO;
   xpc_connection_set_event_handler(xpcConnection, ^(xpc_object_t object) {
      xpc_type_t type = xpc_get_type(object);
      
      if (type == XPC_TYPE_ERROR) {
         
         if (object == XPC_ERROR_CONNECTION_INTERRUPTED) {
            //NSLog(@"Interrupted connection to XPC service %@", blockSafe);
         } else if (object == XPC_ERROR_CONNECTION_INVALID) {
            NSString *errorDescription = [NSString stringWithUTF8String:xpc_dictionary_get_string(object, XPC_ERROR_KEY_DESCRIPTION)];
            NSLog(@"Connection Invalid error for XPC service (%@)", errorDescription);
            xpc_release(xpcConnection);
            xpcConnection = NULL;
            [blockSafe failed];
         } else {
            NSLog(@"Unexpected error for XPC service");
            [blockSafe failed];
         }
         [blockSafe finished];
      } else {
         [blockSafe handleReply:object];
      }

   });
   xpc_connection_resume(xpcConnection);
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
        [self finished];
        return; 
    }
    
    if (XPC_TYPE_DICTIONARY != type) {
        [self failed];
        [self finished];
        return;
    }
    
   NSDictionary *dict = [NSObject xpcObjectToNSObject:reply];
   NSLog(@"Response dict: %@", dict);
   NSString *responseAction = [dict objectForKey:@"GrowlActionType"];
   BOOL success = [dict objectForKey:@"Success"] != nil ? [[dict objectForKey:@"Success"] boolValue] : NO;
   
   if([responseAction isEqualToString:@"reregister"]){
      [self queueAndReregister];
   }else if([responseAction isEqualToString:@"feedback"]){
      BOOL clicked = [[dict objectForKey:@"Clicked"] boolValue];
      NSString *context = [dict objectForKey:@"Context"];
      if(clicked){
         if(delegate && [delegate respondsToSelector:@selector(notificationClicked:context:)])
            [delegate notificationClicked:self context:context];
      }else{
         if(delegate && [delegate respondsToSelector:@selector(notificationTimedOut:context:)])
            [delegate notificationTimedOut:self context:context];
      }
      [self finished];
   }else{
      if (success){
         [self succeeded];
         if([self attemptType] == GrowlCommunicationAttemptTypeRegister)
            [self finished];
      }else{
         GrowlGNTPErrorCode reason = (GrowlGNTPErrorCode)[[dict objectForKey:@"Error-Code"] integerValue];
         NSString *description = [dict objectForKey:@"Error-Description"];
         NSLog(@"Failed with code %d, \"%@\"", reason, description);
         if([responseAction isEqualToString:@"notification"] && reason == GrowlGNTPUserDisabledErrorCode){
            [self stopAttempts];
         }else{
            [self failed];
            [self finished];
         }
      }
   }
}

- (BOOL) sendMessageWithPurpose:(NSString *)purpose
{
    if (!xpcConnection)
        return NO;
    
    xpc_object_t xpcMessage = xpc_dictionary_create(NULL, NULL, 0);
    
    // Add the known parameters, yay!
    xpc_dictionary_set_string(xpcMessage, "GrowlDictType", [purpose UTF8String]);
    
    xpc_object_t growlDict = [(NSObject*)self.dictionary newXPCObject];
    xpc_dictionary_set_value(xpcMessage, "GrowlDict", growlDict);
    xpc_release(growlDict);
    
    xpc_connection_send_message(xpcConnection, xpcMessage);
    xpc_release(xpcMessage);
    
    return YES;
}

@end
