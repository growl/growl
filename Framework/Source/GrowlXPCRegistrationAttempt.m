//
//  GrowlXPCRegistrationAttempt.m
//  Growl
//
//  Created by Rachel Blackman on 8/22/11.
//  Copyright (c) 2011 The Growl Project. All rights reserved.
//

#import "GrowlXPCRegistrationAttempt.h"

@implementation GrowlXPCRegistrationAttempt


+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeRegister;
}

-(NSString*)purpose
{
   return @"registration";
}

@end
