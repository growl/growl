//
//  GrowlApplicationBridgeRegistrationAttempt.h
//  Growl
//
//  Created by Peter Hosey on 2011-07-11.
//  Copyright 2011 The Growl Project. All rights reserved.
//

#import "GrowlCommunicationAttempt.h"

@interface GrowlApplicationBridgeRegistrationAttempt : GrowlCommunicationAttempt
{
	NSString *applicationName;
}

@property(nonatomic, copy) NSString *applicationName;

@end
