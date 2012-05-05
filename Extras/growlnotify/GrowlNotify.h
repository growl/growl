//
//  GrowlNotify.h
//  growlnotify
//
//  Created by Daniel Siemer on 9/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlCommunicationAttempt.h"

#define NOTIFICATION_CLICKED 2

@class GrowlGNTPRegistrationAttempt, GrowlGNTPNotificationAttempt;

@interface GrowlNotify : NSObject <GrowlCommunicationAttemptDelegate>{
   GrowlGNTPRegistrationAttempt *registrationAttempt;
   GrowlGNTPNotificationAttempt *notificationAttempt;
   
   BOOL sendingNote;
   BOOL stopLoop;
   BOOL wait;
   
   int returnCode;
}

@property (nonatomic, retain) GrowlGNTPRegistrationAttempt *registrationAttempt;
@property (nonatomic, retain) GrowlGNTPNotificationAttempt *notificationAttempt;

- (id)initWithRegistrationDict:(NSDictionary*)regDict 
              notificationDict:(NSDictionary*)noteDict
                          host:(NSString*)hostName
                      password:(NSString*)pass;

- (int)start:(BOOL)shouldWait;

@end
