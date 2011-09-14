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
    }
    
    return self;
}

-(void)dealloc
{
   [notificationAttempt release];
   [registrationAttempt release];
   [super dealloc];
}

-(void)start
{
   NSRunLoop *runloop = [NSRunLoop mainRunLoop];
   //Setup our runloop here someplace
   NSLog(@"testing");
   [registrationAttempt begin];
   NSLog(@"testing again");
   [runloop run];
}

- (void) attemptDidSucceed:(GrowlCommunicationAttempt *)attempt
{
   //Start notification
   if(attempt == registrationAttempt){
      if(!sendingNote){
         NSLog(@"registration succeeded, sending note");
         [notificationAttempt begin];
         sendingNote = YES;
      }
   }else if(attempt == notificationAttempt)
      NSLog(@"waiting on click feedback");
}
- (void) attemptDidFail:(GrowlCommunicationAttempt *)attempt
{
   //We failed at first step
   if(attempt == registrationAttempt){
      NSLog(@"We failed to register, perhaps Growl 1.3 or higher is not running on the specified host (%@)", [(GrowlGNTPCommunicationAttempt*)attempt host]);
   }else if(attempt == notificationAttempt){
      NSLog(@"We failed to notify");
   }
}
- (void) finishedWithAttempt:(GrowlCommunicationAttempt *)attempt
{
   
}
- (void) queueAndReregister:(GrowlCommunicationAttempt *)attempt
{
   
}

//Sent after success
- (void) notificationClicked:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   NSLog(@"attempt (%@) clicked", attempt);
}

- (void) notificationTimedOut:(GrowlCommunicationAttempt *)attempt context:(id)context
{
   NSLog(@"attempt (%@) timedout", attempt);
}

@end
