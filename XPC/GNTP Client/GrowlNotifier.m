//
//  GrowlNotifier.m
//  Growl
//
//  Created by Daniel Siemer on 9/15/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlNotifier.h"
#import "GrowlDefines.h"
#import "GrowlGNTPCommunicationAttempt.h"
#import "GrowlGNTPRegistrationAttempt.h"
#import "GrowlGNTPNotificationAttempt.h"

#import "NSObject+XPCHelpers.h"

@implementation GrowlNotifier

@synthesize currentAttempts;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) sendCommunicationAttempt:(GrowlCommunicationAttempt *)attempt 
{
   [currentAttempts addObject:attempt];
   [attempt begin];
}

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt{
   NSLog(@"Attempt succeeded!");
   if([attempt isKindOfClass:[GrowlGNTPRegistrationAttempt class]]){
      NSMutableDictionary *response = [NSMutableDictionary dictionary];
      [response setValue:[NSNumber numberWithBool:YES] forKey:@"Success"];
      [response setValue:@"Registration" forKey:@"GrowlActionType"];
      xpc_object_t message = [(NSObject*)response newXPCObject];
      xpc_connection_send_message([(GrowlGNTPCommunicationAttempt*)attempt connection], message);
      xpc_release(message);
   }
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt{
   [currentAttempts removeObject:attempt];
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt{
   [currentAttempts removeObject:attempt];
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt{
   //we will have to ask our host app for the reg dict again via XPC
   
}
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context{

}
- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context{
   
}

@end
