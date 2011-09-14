//
//  GrowlNotify.m
//  growlnotify
//
//  Created by Daniel Siemer on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GrowlNotify.h"
#import "GrowlCommunicationAttempt.h"
#import "GrowlGNTPCommunicationAttempt.h"
#import "GrowlGNTPRegistrationAttempt.h"
#import "GrowlGNTPNotificationAttempt.h"

@implementation GrowlNotify

@synthesize registrationAttempt;
@synthesize notificationAttempt;

- (id)initWithRegistrationDict:(NSDictionary*)regDict 
              notificationDict:(NSDictionary*)noteDict
                          host:(NSString*)host
                      password:(NSString*)pass
{
    self = [super init];
    if (self) {
       self.registrationAttempt = [[[GrowlGNTPRegistrationAttempt alloc] initWithDictionary:regDict] autorelease];
       self.registrationAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
       self.registrationAttempt.host = host;
       self.registrationAttempt.password = pass;
       
       self.notificationAttempt = [[[GrowlGNTPNotificationAttempt alloc] initWithDictionary:noteDict] autorelease];
       self.notificationAttempt.delegate = (id <GrowlCommunicationAttemptDelegate>)self;
       self.notificationAttempt.host = host;
       self.notificationAttempt.password = pass;
       
       sendingNote = NO;
       stopLoop = NO;
       
       returnCode = EXIT_SUCCESS;
    }
    
    return self;
}

-(void)dealloc
{
   [notificationAttempt release];
   [registrationAttempt release];
   [super dealloc];
}

-(int)start:(BOOL)shouldWait
{
   wait = shouldWait;
   NSRunLoop *runloop = [NSRunLoop currentRunLoop];
   [registrationAttempt begin];
   while(!stopLoop){
      [runloop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
   }
   return returnCode;
}

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt
{
   //Start notification
   if(attempt == registrationAttempt){
      if(!sendingNote){
         [notificationAttempt begin];
         sendingNote = YES;
      }
   }else if(attempt == notificationAttempt && !wait){
      returnCode = EXIT_SUCCESS;
      stopLoop = YES;
   }
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt
{
   //We failed at first step
   if(attempt == registrationAttempt){
      NSLog(@"Failed to register with %@", [(GrowlGNTPCommunicationAttempt*)attempt host]);
   }else if(attempt == notificationAttempt){
      NSLog(@"We failed to notify after succesfully registering");
   }
   returnCode = EXIT_FAILURE;
   stopLoop = YES;
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt
{
   //Other cases should handle this
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt
{
   //We should simply fail here
   returnCode = EXIT_FAILURE  ;
   stopLoop = YES;
}

//Sent after success
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   returnCode = NOTIFICATION_CLICKED;
   stopLoop = YES;
}

- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   returnCode = EXIT_SUCCESS;
   stopLoop = YES;
}

@end
