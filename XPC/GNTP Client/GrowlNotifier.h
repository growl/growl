//
//  GrowlNotifier.h
//  Growl
//
//  Created by Daniel Siemer on 9/15/11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlCommunicationAttempt.h"
#import <xpc/xpc.h>

@interface GrowlNotifier : NSObject <GrowlCommunicationAttemptDelegate>

@property (nonatomic, strong) NSMutableArray *currentAttempts;

- (void) sendCommunicationAttempt:(GrowlCommunicationAttempt *)attempt;

@end
