//
//  GrowlXPCSubscriptionAttempt.m
//  Growl
//
//  Created by Daniel Siemer on 7/14/12.
//  Copyright (c) 2012 The Growl Project. All rights reserved.
//

#import "GrowlXPCSubscriptionAttempt.h"

@implementation GrowlXPCSubscriptionAttempt

+ (GrowlCommunicationAttemptType) attemptType {
	return GrowlCommunicationAttemptTypeSubscribe;
}

-(NSString*)purpose
{
	return @"subscribe";
}

@end
